// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
console.info('server started');
const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
// 配置参数（可直接在代码中修改，调试更方便）
let CONFIG = {
  validDays: 30,
  coreWeightThreshold: 0.3, //核心权重阈值，只计算大于此的指标
  indicatorQualifiedThreshold: 0.75, //指标合格阈值，大于此算作合格
  upgradeQualifiedThreshold: 0.75 //升级合格阈值，大于此可升级
};
Deno.serve(async (req) => {
  // 处理跨域 OPTIONS 请求
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
      }
    });
  }
  try {
    const { user_id, level, validDays = 60 } = await req.json();
    // 1. 解析并验证输入参数
    CONFIG.validDays = validDays;
    if (!user_id || !level || level < 1 || level > 9) {
      return new Response(JSON.stringify({
        error: "无效参数：user_id 为必填项，level 需为 1-9"
      }), {
        status: 400,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        }
      });
    }
    console.log(`request: user_id:${user_id},level:${level},config:${JSON.stringify(CONFIG)}`);
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // 步骤1：查询当前级别的核心指标（含 minimum 字段）
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    const { data: coreIndicators, error: indicatorsError } = await supabase.schema('research_core').from('indicators').select('id, indicator, weight, category, skill_group, minimum') // 新增 minimum 字段
      .eq('level', level).gte('weight', CONFIG.coreWeightThreshold).order('weight', {
        ascending: false
      });
    if (indicatorsError) throw indicatorsError;
    if (!coreIndicators || coreIndicators.length === 0) {
      return new Response(JSON.stringify({
        error: `未找到级别 ${level} 的核心指标`
      }), {
        status: 404,
        headers: {
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*"
        }
      });
    }
    const coreIndicatorIds = coreIndicators.map((ind) => ind.id);
    const totalCoreIndicators = coreIndicatorIds.length;
    const now = new Date();
    const validStartTime = new Date(now.setDate(now.getDate() - CONFIG.validDays)).toISOString();
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // 步骤2：计算每个核心指标的「平均得分+练习次数」，判断是否达标（需同时满足得分和次数条件）
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    const indicatorScores = [];
    for (const indicator of coreIndicators) {
      const { data: historyData, error: historyError } = await supabase.from('user_ability_history').select('score, created_at').eq('user_id', user_id).eq('indicator_id', indicator.id).gte('created_at', validStartTime).order('created_at', {
        ascending: false
      });
      if (historyError) throw historyError;
      // 计算该指标的核心数据
      const practiceCount = historyData.length; // 该指标的练习次数（最近30天）
      const avgScore = practiceCount > 0 ? historyData.reduce((sum, item) => sum + Number(item.score), 0) / practiceCount : 0;
      const indicatorMinimum = Number(indicator.minimum) || 0; // 指标基础练习次数（兼容 null 情况）
      // 单指标达标条件：平均得分≥阈值 AND 练习次数≥minimum
      const isQualified = avgScore >= CONFIG.indicatorQualifiedThreshold && practiceCount >= indicatorMinimum;
      indicatorScores.push({
        indicatorId: indicator.id,
        indicatorName: indicator.indicator,
        indicatorWeight: Number(indicator.weight),
        minimum: indicatorMinimum,
        practiceCount: practiceCount,
        avgScore: Number(avgScore.toFixed(2)),
        isQualified: isQualified,
        // 新增：次数差距提示（前端可展示“已练X次/需X次”）
        practiceGap: Math.max(0, indicatorMinimum - practiceCount)
      });
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // 步骤3：计算核心指标覆盖率（有练习数据的核心指标数/总核心指标数）
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    const coveredIndicatorsCount = indicatorScores.filter((ind) => ind.practiceCount > 0).length;
    const coreIndicatorCoverage = Math.round(coveredIndicatorsCount / totalCoreIndicators * 100);
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // 步骤4：计算加权总得分（仅计入达标的指标得分，未达标指标按 0 计算）
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    const totalWeight = indicatorScores.reduce((sum, ind) => sum + ind.indicatorWeight, 0);
    // 未达标指标不计入得分（避免“次数不够但分数高”拉高新总分）
    const weightedTotalScore = totalWeight > 0 ? indicatorScores.reduce((sum, ind) => sum + (ind.isQualified ? ind.avgScore * ind.indicatorWeight : 0), 0) / totalWeight : 0;
    const finalScore = Number(weightedTotalScore.toFixed(2));
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // 步骤5：计算连续达标次数（最近30天内，按时间倒序的连续「单条练习得分≥阈值」的记录数）
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    const { data: allHistoryData, error: allHistoryError } = await supabase.from('user_ability_history').select('score, created_at').eq('user_id', user_id).in('indicator_id', coreIndicatorIds).gte('created_at', validStartTime).order('created_at', {
      ascending: false
    });
    if (allHistoryError) throw allHistoryError;
    let consecutiveQualifiedCount = 0;
    for (const item of allHistoryData) {
      if (Number(item.score) >= CONFIG.indicatorQualifiedThreshold) {
        consecutiveQualifiedCount++;
      } else {
        break; // 中断连续计数
      }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // 步骤6：统计最近练习情况（7天/30天练习次数、最近练习时间）
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    const sevenDaysAgo = new Date(now.setDate(now.getDate() - 7)).toISOString();
    const { data: practice30dData } = await supabase.from('user_ability_history').select('id, created_at').eq('user_id', user_id).in('indicator_id', coreIndicatorIds).gte('created_at', validStartTime);
    const { data: practice7dData } = await supabase.from('user_ability_history').select('id').eq('user_id', user_id).in('indicator_id', coreIndicatorIds).gte('created_at', sevenDaysAgo);
    const recentPractice = {
      practiceCount7d: practice7dData?.length || 0,
      practiceCount30d: practice30dData?.length || 0,
      lastPracticeTime: practice30dData?.length ? new Date(practice30dData.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime())[0].created_at).toISOString() : null
    };
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // 步骤7：计算升级差距（未达标时，需要提升的分数）
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    const upgradeGap = Math.max(0, Number((CONFIG.upgradeQualifiedThreshold - finalScore).toFixed(2)));
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // 步骤8：判断是否有升级测试资格（总分≥阈值 + 核心指标覆盖率≥80%）
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    const isEligibleForUpgrade = finalScore >= CONFIG.upgradeQualifiedThreshold && coreIndicatorCoverage >= 80;
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // 步骤9：生成更精准的提示信息
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    let message = "";
    if (isEligibleForUpgrade) {
      message = "你已满足升级测试条件！点击参与测试，解锁更高级别～";
    } else {
      const unmetIndicators = indicatorScores.filter((ind) => !ind.isQualified);
      if (unmetIndicators.length > 0) {
        // 提示未达标的核心原因（次数不够/分数不够）
        const countGapIndicators = unmetIndicators.filter((ind) => ind.practiceGap > 0).length;
        const scoreGapIndicators = unmetIndicators.filter((ind) => ind.practiceGap === 0 && ind.avgScore < CONFIG.indicatorQualifiedThreshold).length;
        let message_list = [];
        if (countGapIndicators > 0) message_list.push(`有 ${countGapIndicators} 个指标练习次数不足（需累计 ${unmetIndicators[0].minimum} 次）`);
        if (scoreGapIndicators > 0) message_list.push(`有 ${scoreGapIndicators} 个指标平均得分未达标（需≥${CONFIG.indicatorQualifiedThreshold}）`);
        message_list.push(`还需提升 ${upgradeGap} 分才能参与升级测试`);
        message = message_list.join("，");
      } else {
        message = `核心指标覆盖率不足（当前 ${coreIndicatorCoverage}%，需≥80%），继续练习解锁更多指标～`;
      }
    }
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    // 组装最终返回结果
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    const result = {
      score: finalScore,
      isEligibleForUpgrade: isEligibleForUpgrade,
      coreIndicatorCoverage: coreIndicatorCoverage,
      coreIndicatorDetails: indicatorScores,
      consecutiveQualifiedCount: consecutiveQualifiedCount,
      recentPractice: recentPractice,
      upgradeGap: upgradeGap,
      message: message // 精准提示信息
    };
    return new Response(JSON.stringify(result), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 200
    });
  } catch (error) {
    console.error("接口错误：", error);
    return new Response(JSON.stringify({
      error: "获取升级资格失败",
      details: error instanceof Error ? error.message : String(error)
    }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 500
    });
  }
});
