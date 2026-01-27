import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
// 初始化Supabase客户端
const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
// 计划练习数量（每周天数）
let TotalDaysforPlan = 6;
function setTotalDaysbyLevel(level) {
  TotalDaysforPlan = level <= 3 ? 6 : level <= 6 ? 9 : 12;
}
const levelTargetMap = {
  1: 3,
  2: 3,
  3: 3,
  4: 4,
  5: 4,
  6: 4,
  7: 4,
  8: 4,
  9: 4
};
function debug(params, priority = 1) {
  if (priority == 1) {
    console.log(params);
  } else if (priority == 2) {
    console.log(params);
  } else {
  // console.log(params);
  }
}
/** 部署函数 */ //
Deno.serve(async (req)=>{
  // ✅ 处理预检请求（浏览器自动发出的 OPTIONS 请求）
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
      }
    });
  }
  const { user_id, level } = await req.json();
  if (!user_id) {
    throw new Error("缺少参数：user_id");
  }
  debug(`API request::${JSON.stringify({
    user_id,
    level
  })}`);
  try {
    // 获取用户能力指标状态
    const { data, error } = await supabase.functions.invoke('check_for_upgrade', {
      body: {
        user_id: user_id,
        level: level,
        validDays: 100
      }
    });
    if (error) throw new Error(`check_for_upgrade error:${error}`);
    const focusIndicators = getFocusIndicators(data.coreIndicatorDetails, levelTargetMap[level]);
    // 完成请求
    return new Response(JSON.stringify(focusIndicators), {
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
/**
 * 获取最需要提升的核心指标
 * @param {Array} indicators - 指标达成情况数组（结构如题目所示）
 * @param {number} n - 需要返回的核心指标数量（n≥1）
 * @returns {Array} 按优先级排序的前n个核心指标（保留原始数据+优先级得分）
 */ function getFocusIndicators(indicators, n) {
  // 边界处理：参数校验
  if (!Array.isArray(indicators) || indicators.length === 0) {
    console.warn("指标数据为空");
    return [];
  }
  const targetN = Math.min(n, indicators.length); // 避免n超过指标总数
  // 1. 为每个指标计算优先级得分
  const indicatorsWithScore = indicators.map((indicator)=>{
    const { indicatorWeight, minimum, practiceCount, practiceGap } = indicator;
    // 计算各维度得分（归一化到0~1）
    const importanceScore = indicatorWeight; // 业务权重本身已量化，直接使用
    const gapRatio = minimum + practiceGap === 0 ? 0 : practiceGap / (minimum + practiceGap); // 达标差距占比
    const completionRate = minimum === 0 ? 0 : practiceCount / minimum; // 完成度
    const insufficientScore = 1 - completionRate; // 完成度不足得分
    // 2. 计算总优先级得分（权重可按需调整）
    const priorityScore = importanceScore * 0.4 + gapRatio * 0.35 + insufficientScore * 0.25;
    return {
      ...indicator,
      priorityScore: Number(priorityScore.toFixed(4)) // 保留4位小数，便于查看
    };
  });
  // 3. 按优先级得分降序排序（得分越高，越需要优先提升）
  const sortedIndicators = indicatorsWithScore.sort((a, b)=>{
    return b.priorityScore - a.priorityScore;
  });
  // 4. 返回前n个核心指标（可按需剔除priorityScore字段）
  return sortedIndicators.slice(0, targetN);
}
