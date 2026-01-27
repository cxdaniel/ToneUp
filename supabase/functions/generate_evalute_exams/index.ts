// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
console.info('server started');
const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
///
///
Deno.serve(async (req)=>{
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
      }
    });
  }
  const { inds, count = 10, acts = null, lang = 'en'} = await req.json();
  if (!inds) {
    throw new Error('缺少参数: inds. 量化指标列表');
  }
  try {
    console.log(`开始执行:${inds}`);
    // 1. 获取能力指标
    const indicators = await getIndicators(inds);
    console.log(`获取能力指标:${indicators}`);
    // 2. 获取活动库
    const activities = await getActivities(acts);
    console.log(`获取活动库:${activities}`);
    // 3. 按权重安排indicator
    const targets = [];
    const totalWeight = indicators.reduce((sum, ind)=>sum + ind.weight, 0);
    indicators.forEach((ind)=>{
      let quantity = Math.round(ind.weight / totalWeight * count);
      while(quantity > 0){
        const acts = getActByIndCategory(ind, activities);
        const act = acts[Math.floor(Math.random() * acts.length)];
        if (act) targets.push({
          indicator: ind,
          activity: act
        });
        quantity--;
      }
    });
    console.log(`按权重安排indicator:${targets}`);
    // 4. 整理quiz数据
    const act_data = targets.map((item, index)=>({
        id: index,
        lang: lang,
        level: item.indicator.level,
        indicator: item.indicator.indicator,
        material_type: item.activity.material_type[Math.floor(Math.random() * item.activity.material_type.length)],
        quiz_type: item.activity.quiz_type,
        quiz_template: item.activity.quiz_template,
        activity_title: item.activity.activity_title,
        time_cost: item.activity.time_cost
      }));
    console.log(`整理quiz数据:${act_data}`);
    // 5. 生成quiz
    const quizess = await callCozeWorkflow({
      act_data
    });
    // 5. 保存数据
    const evaluations = targets.map((item, i)=>{
      const update = quizess[i];
      if (!update || !update.question) {
        return null;
      }
      return {
        level: item.indicator.level,
        indicator_id: item.indicator.id,
        activity_id: item.activity.id,
        stem: quizess[i].material,
        question: quizess[i].question,
        options: quizess[i].options,
        explain: quizess[i].explain,
        lang,
      };
    }).filter(Boolean);
    const res = await saveEvaluationData(evaluations);
    console.log(`保存数据:${res}`);
    // 6. 返回接口
    return new Response(JSON.stringify(res), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 200
    });
  } catch (error) {
    return new Response(JSON.stringify({
      error: error.message
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 400
    });
  }
});
///
/** 获取指定指标项 */ ///
async function getIndicators(inds) {
  const { data, error } = await supabase.schema('research_core').from("indicators").select().in('id', inds).order("level");
  if (error) throw new Error(`能力指标查询失败：${data.message}`);
  if (!data || data.length === 0) throw new Error("指标库为空");
  return data;
}
///
/** 获取指定活动库 */ ///
async function getActivities(acts) {
  const { data, error } = acts ? await supabase.schema('research_core').from("activities").select().in('id', acts) : await supabase.schema('research_core').from("activities").select().eq("available", 1);
  if (error) throw new Error(`活动库查询失败：${data.message}`);
  if (!data || data.length === 0) throw new Error("活动库为空");
  return data;
}
///
/** 找到可用活动库 */ ///
function getActByIndCategory(ind, acts) {
  const candidateActivities = acts.filter((act)=>{
    return act.indicator_cats.includes(ind.category);
  });
  return candidateActivities;
}
///
/** 保存测评数据 */ ///
async function saveEvaluationData(save_data) {
  const { data, error } = await supabase.schema('research_core').from('evaluation').insert(save_data).select('id');
  if (error) throw new Error(`保存测评数据-失败：${data.message}`);
  return data;
}
////////////////////////////////////////////////////////
////////////////////////////////////////////////////////
const COZE_TOKEN = Deno.env.get("COZE_TOKEN_RUN");
const COZE_WORKFLOW_ID = Deno.env.get("COZE_WORKFLOW_GENEXAM");
///
/** 调用COZE */ ///
async function callCozeWorkflow(input) {
  console.log('请求COZE...', input);
  if (!COZE_TOKEN || !COZE_WORKFLOW_ID) {
    throw new Error("Coze环境变量未配置");
  }
  try {
    const response = await fetch("https://api.coze.cn/v1/workflow/run", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${COZE_TOKEN}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        workflow_id: COZE_WORKFLOW_ID,
        parameters: input
      })
    });
    console.log("Coze API 响应状态码:", response.status);
    if (!response.ok) {
      throw new Error(`Coze API调用失败（状态码：${response.status}）${response.statusText}`);
    }
    const responseJson = await response.json();
    console.log("Coze API 响应内容response:", responseJson.data);
    const output = JSON.parse(responseJson.data).output;
    if (!output) {
      throw new Error(`Coze API返回数据解析output错误, 原数据：${responseJson.data}} `);
    }
    return output;
  } catch (fetchError) {
    throw new Error(`Coze API请求失败：${fetchError.message} `);
  }
}
