// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};
// 从环境变量获取扣子配置
const SUPABASE = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
const COZE_TOKEN = Deno.env.get('COZE_TOKEN_RUN');
const COZE_WORKFLOW_ID = Deno.env.get('COZE_WORKFLOW_DICT');

interface TranslateRequest {
  word: string;
  lang: string; // 对应 ProfileModel.nativeLanguage (en, zh, ja, ko, es, fr, de)
}

interface WordEntry {
  pinyin: string;
  pos: string; // 词性 (n., v., adj.等)
  definitions: string[];
  examples: string[];
}

interface CozeWorkflowResponse {
  summary: string;
  hsk_level?: number;
  entries: WordEntry[];
}

Deno.serve(async (req) => {
  // 处理CORS预检请求
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 解析请求体
    const { word, lang } = await req.json() as TranslateRequest;

    // 验证必需参数
    if (!word || !lang) {
      throw new Error('Missing required parameters: word, lang');
    }

    console.log(`🤖 收到词典请求: ${word} → ${lang}`);

    // 1. 先查询数据库（客户端通常已查过，这里是双重保险）
    const { data: existingWord } = await SUPABASE
      .from('dictionary')
      .select('word, hsk_level, translations')
      .eq('word', word)
      .maybeSingle();

    if (existingWord && existingWord.translations?.[lang]) {
      console.log(`📖 数据库已有缓存: ${word} (${lang})`);
      return new Response(JSON.stringify({
        summary: existingWord.translations[lang].summary,
        hsk_level: existingWord.hsk_level,
        entries: existingWord.translations[lang].entries || [],
      }), {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200,
      });
    }

    // 2. 数据库没有，调用Coze工作流生成
    console.log(`🚀 调用扣子工作流生成: ${word} → ${lang}`);

    if (!COZE_TOKEN || !COZE_WORKFLOW_ID) {
      throw new Error('Missing Coze configuration. Please set COZE_TOKEN_RUN and COZE_WORKFLOW_DICT');
    }

    // 调用扣子工作流API
    const cozeResponse = await fetch('https://api.coze.cn/v1/workflow/run', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${COZE_TOKEN}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        workflow_id: COZE_WORKFLOW_ID,
        parameters: {
          word: word,
          lang: lang,
        },
      }),
    });

    if (!cozeResponse.ok) {
      const errorText = await cozeResponse.text();
      console.error(`❌ 扣子API错误: ${cozeResponse.status} - ${errorText}`);
      throw new Error(`Coze API error: ${cozeResponse.status}`);
    }

    const cozeData = await cozeResponse.json();
    console.log('✅ 扣子工作流响应成功');

    // 解析扣子工作流返回的数据
    const workflowOutput = JSON.parse(cozeData.data).output;

    const result: CozeWorkflowResponse = {
      summary: workflowOutput.summary || '',
      hsk_level: workflowOutput.hsk_level,
      entries: workflowOutput.entries || [],
    };

    // 验证必需字段
    if (!result.summary) {
      console.warn('⚠️ 扣子工作流返回的summary为空');
    }

    // 3. 保存到Supabase数据库
    try {
      let translationsData: Record<string, any> = {};
      
      if (existingWord) {
        // 已有词条（但没有当前语言），合并翻译
        translationsData = existingWord.translations || {};
        translationsData[lang] = {
          summary: result.summary,
          entries: result.entries,
        };

        await SUPABASE
          .from('dictionary')
          .update({
            translations: translationsData,
            updated_at: new Date().toISOString(),
          })
          .eq('word', word);

        console.log(`💾 已更新词条: ${word} (添加${lang}翻译)`);
      } else {
        // 新词条，创建
        translationsData[lang] = {
          summary: result.summary,
          entries: result.entries,
        };

        await SUPABASE
          .from('dictionary')
          .insert({
            word: word,
            hsk_level: result.hsk_level,
            translations: translationsData,
            source: 'coze',
          });

        console.log(`💾 已创建新词条: ${word} (${lang})`);
      }
    } catch (dbError) {
      // 数据库保存失败不影响返回结果
      console.error('❌ 保存到数据库失败:', dbError);
    }

    return new Response(JSON.stringify(result), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      status: 200,
    });

  } catch (error) {
    console.error('❌ Edge Function错误:', error);
    
    return new Response(
      JSON.stringify({ 
        error: error.message,
        timestamp: new Date().toISOString(),
      }), 
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    );
  }
});
