// supabase/functions/tts_proxy/index.ts
// 可以定期运行 Edge Function 清理旧缓存，例如：
// sql: delete from storage.objects where bucket_id = 'tts_cache' and created_at < now() - interval '30 days';
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
const SUPABASE_URL = Deno.env.get("SUPABASE_URL");
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
const VOLC_TOKEN = Deno.env.get("VOLC_TOKEN");
const VOLC_APPID = Deno.env.get("VOLC_APPID");
// 初始化 Supabase 客户端
const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);
// 计算缓存文件名（用哈希保证唯一性）
function hashKey(text, voiceType) {
  const encoder = new TextEncoder();
  const data = encoder.encode(`${voiceType}|${text}`);
  return crypto.subtle.digest("SHA-1", data).then((buf)=>Array.from(new Uint8Array(buf)).map((b)=>b.toString(16).padStart(2, "0")).join(""));
}
Deno.serve(async (req)=>{
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
      }
    });
  }
  try {
    const reqData = await req.json();
    const { text } = reqData.request;
    const voiceType = reqData.audio.voice_type || "default";
    // ✅ 计算缓存 key
    const key = await hashKey(text, voiceType);
    const filePath = `${voiceType}/${key}.mp3`;
    // ✅ 尝试从 Supabase Storage 读取缓存
    const { data: fileData } = await supabase.storage.from("tts_cache").download(filePath);
    if (fileData) {
      console.log(`🎯 从 Supabase 缓存读取: ${filePath}`);
      return new Response(fileData, {
        headers: {
          "Content-Type": "audio/mpeg",
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
        }
      });
    }
    // ✅ 未命中缓存 → 调用火山接口生成音频
    reqData.app = {
      appid: VOLC_APPID,
      token: VOLC_TOKEN,
      cluster: "volcano_tts"
    };
    console.log(`🌐 请求火山 TTS: ${text}`);
    const volcRes = await fetch("https://openspeech.bytedance.com/api/v1/tts", {
      method: "POST",
      headers: {
        Authorization: `Bearer;${VOLC_TOKEN}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify(reqData)
    });
    const audioData = await volcRes.arrayBuffer();
    // ✅ 缓存音频到 Supabase Storage
    await supabase.storage.from("tts_cache").upload(filePath, audioData, {
      contentType: "audio/mpeg",
      upsert: true
    });
    console.log(`✅ 新缓存音频: ${filePath}`);
    return new Response(audioData, {
      headers: {
        "Content-Type": "audio/mpeg",
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
      }
    });
  } catch (err) {
    console.error("❌ TTS Proxy Error:", err);
    return new Response(JSON.stringify({
      error: err.message
    }), {
      status: 500,
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
      }
    });
  }
});
