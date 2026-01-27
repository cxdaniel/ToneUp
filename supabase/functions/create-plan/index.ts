import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
// 初始化Supabase客户端
const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
// 计划练习数量（每周天数）
let TotalDaysforPlan = 6;
function setTotalDaysbyLevel(level) {
  TotalDaysforPlan = level <= 3 ? 6 : level <= 6 ? 9 : 12;
}
// 材料类型标准时长配置（分钟）
const STANDARD_DURATIONS = {
  character: 2,
  word: 3,
  syllable: 5,
  grammar: 10,
  sentence: 4,
  dialog: 8,
  paragraph: 12,
  chars_review: 1,
  words_review: 1.5
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
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 部署函数 */ //
Deno.serve(async (req) => {
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
  const { user_id, inds, dur = 60, acts = null, native_language = 'en' } = await req.json();
  const lang = native_language; // 统一使用 lang 变量名
  if (!inds || !inds) {
    throw new Error("缺少参数: user_id, inds");
  }
  debug(`API request::${JSON.stringify({
    user_id,
    inds,
    dur
  })}`);
  // 创建 ReadableStream 用于流式传输
  const stream = new ReadableStream({
    async start(controller) {
      // 辅助函数：发送进度消息
      const sendProgress = (step, message, data = null) => {
        const progressData = {
          type: 'progress',
          step,
          message,
          data,
          timestamp: new Date().toISOString()
        };
        controller.enqueue(new TextEncoder().encode(JSON.stringify(progressData) + '\n'));
      };
      // 辅助函数：发送错误消息
      const sendError = (error) => {
        const errorData = {
          type: 'error',
          error,
          timestamp: new Date().toISOString()
        };
        controller.enqueue(new TextEncoder().encode(JSON.stringify(errorData) + '\n'));
      };
      // 辅助函数：发送完成消息
      const sendComplete = (result) => {
        const completeData = {
          type: 'complete',
          result,
          timestamp: new Date().toISOString()
        };
        controller.enqueue(new TextEncoder().encode(JSON.stringify(completeData) + '\n'));
      };
      try {
        // 1. 获取用户能力短板指标和当前级别
        sendProgress(1, 'Analyzing user ability data...');
        const { focusIndicators, currentLevel } = await _getFocusIndicators(inds);
        debug(`1. 获取用户能力短板指标和当前级别:${JSON.stringify({
          focusIndicators,
          currentLevel
        })}`, 3);
        sendProgress(1, 'Ability analysis complete.', {
          currentLevel,
          indicatorCount: focusIndicators.length
        });
        // 2. 设置计划参数
        const totalDuration = dur;
        setTotalDaysbyLevel(currentLevel);
        debug(`2. 用户计划时长:${totalDuration}, 计划练习量:${JSON.stringify(TotalDaysforPlan)}`, 3);
        sendProgress(2, 'Time allocation complete.', {
          totalDuration
        });
        // 3. 获取各材料按时间分配的数量
        sendProgress(3, 'Planning learning materials...');
        const materialQuantities = _getMaterialQuantities(focusIndicators, totalDuration);
        debug(`3. 获取各材料按时间分配的数量:${JSON.stringify(materialQuantities)}`, 3);
        sendProgress(3, 'Material planning complete.', {
          materialQuantities
        });
        // 4. 获取复习内容
        sendProgress(4, 'Querying review content...');
        const needReviews = await _getUserScoreRecord(user_id, materialQuantities, currentLevel);
        debug(`4. 获取复习内容:${JSON.stringify(needReviews)}`, 3);
        sendProgress(4, 'Review content loaded.', {
          reviewCount: Object.keys(needReviews).length
        });
        // 5. 查找已学过的材料
        sendProgress(5, 'Checking learning history...');
        const exists = await _getExists(user_id, currentLevel);
        debug(`5. 查找已学过的材料:${JSON.stringify(exists)}`, 3);
        sendProgress(5, 'Learning history loaded.', {
          existingCount: Object.keys(exists).length
        });
        // 6. 整合要生成材料的数据
        const materialNeeds = {
          level: currentLevel,
          focusIndicators: focusIndicators.map((ind) => ind.indicator),
          materialQuantities,
          needReviews,
          exists
        };
        debug(`6. 生成请求数据:${JSON.stringify({
          materialNeeds
        })}`, 2);
        // 7. 生成材料（这一步通常最耗时）
        sendProgress(6, 'Generating learning materials (this may take a moment)...');
        const cozeOutput = await _callCozeWorkflow(materialNeeds);
        debug(`7. 生成材料:${JSON.stringify(cozeOutput)}`, 3);
        sendProgress(6, 'Materials generation complete.', cozeOutput['topic_title']);
        // 8. 获取可分配的活动库
        sendProgress(7, 'Allocating learning activities...');
        const { allocationMap, tidyMeterials, totalStudyTime } = await _get_allocate_activities({
          level: currentLevel,
          material: cozeOutput,
          indicators: focusIndicators,
          activityIds: acts,
          totalDuration: totalDuration
        });
        debug(`8. 获取可分配的活动库:${JSON.stringify({
          allocationMap,
          tidyMeterials,
          totalStudyTime
        })}`, 3);
        sendProgress(7, 'Activity allocation complete.', totalStudyTime);
        // 9. 生成计划
        sendProgress(8, 'Generating study plan...');
        const planData = await _create_weekly_plan({
          allocationMap,
          tidyMeterials,
          totalStudyTime
        });
        debug(`9. 生成计划:${JSON.stringify(planData)}`, 3);
        sendProgress(8, 'Study plan generated.', planData.length);
        // 10. 保存数据
        sendProgress(9, 'Saving material data...');
        const saved_material = await _saveMaterialData({
          user_id,
          currentLevel,
          cozeOutput
        });
        sendProgress(9, 'Saving quiz data...');
        const saved_quizes = await _saveQuizesData({
          planData,
          cozeOutput,
          lang: lang
        });
        sendProgress(9, 'Saving practice data...');
        const saved_practices = await _savePracticesData({
          planData,
          saved_quizes,
          lang: lang
        });
        sendProgress(9, 'Saving goal data...');
        const saved_plan = await _savePlanData({
          user_id,
          saved_practices,
          saved_material,
          cozeOutput,
          focusIndicators
        });
        sendProgress(9, 'All data saved successfully. Goal created!', saved_plan);
        // 发送最终结果
        sendComplete(saved_plan);
        // 关闭流
        controller.close();
      } catch (error) {
        sendError(error.message);
        controller.close();
      }
    }
  });
  // 返回流式响应
  return new Response(stream, {
    headers: {
      "Content-Type": "application/x-ndjson",
      "Access-Control-Allow-Origin": "*",
      "Cache-Control": "no-cache",
      "Connection": "keep-alive"
    },
    status: 200
  });
});
async function runSaveTransactionJS({ user_id, currentLevel, cozeOutput, planData, focusIndicators }) {
  try {
    // 步骤 1：保存材料库（_saveMaterialData 改造为事务内执行）
    const saved_material = await _saveMaterialData({
      user_id,
      currentLevel,
      cozeOutput
    });
    if (!saved_material) throw new Error('材料库保存失败');
    // 步骤 2：保存 quizes（拍平数据）
    const saved_quizes = await _saveQuizesData({
      planData,
      cozeOutput
    });
    if (!saved_quizes.length) throw new Error('quizes 保存失败');
    // 步骤 3：保存 practices 和 plan（还原嵌套结构）
    const saved_practices = await _savePracticesData({
      planData,
      saved_quizes
    });
    if (!saved_practices.length) throw new Error('practices 保存失败');
    const saved_plan = await _savePlanData({
      user_id,
      saved_practices,
      saved_material,
      cozeOutput,
      focusIndicators
    });
    return saved_plan;
  } catch (error) {
    throw error;
  }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 保存学习材料数据 */ //
async function _saveMaterialData({ user_id, currentLevel, cozeOutput }) {
  const saved_data = {
    user_id: user_id,
    level: currentLevel,
    chars: cozeOutput.chars_new,
    chars_review: cozeOutput.chars_review,
    words: cozeOutput.words_new,
    words_review: cozeOutput.words_review,
    syllables: cozeOutput.syllables,
    grammars: cozeOutput.grammars,
    sentences: cozeOutput.sentences,
    dialogs: cozeOutput.dialogs,
    paragraphs: cozeOutput.paragraphs,
    topic_tag: cozeOutput.topic_tag,
    culture_tag: cozeOutput.culture_tag,
    topic_title: cozeOutput.topic_title
  };
  const { data, error } = await supabase.from('user_materials').insert(saved_data).select('id').single();
  if (error) {
    console.error('材料库保存失败：', error);
  } else {
    debug(`材料库保存成功：>>>> ${JSON.stringify(data)}`);
  }
  return data;
}
/** 创建并保存quizes */ //
async function _saveQuizesData({ planData, cozeOutput, lang = 'en' }) {
  //活动库数据: 把planData中嵌套的activity拍平成一个数组进行quizes存储
  const save_quiz_data = planData.flatMap((day) => day.map((act) => ({
    indicator_id: act.indicator_id,
    activity_id: act.activity_id,
    level: act.level,
    material: act.materials.content,
    material_type: act.materials.type,
    topic_tag: cozeOutput.topic_tag,
    culture_tag: cozeOutput.culture_tag,
    lang: lang
  })));
  // 批量插入活动实例数据
  debug(`要保存到quizes 的数据：${JSON.stringify(save_quiz_data)}`, 2);
  const { data, error } = await supabase.from('quizes').insert(save_quiz_data).select('id');
  if (error) {
    console.error('创建并保存quizes-失败：', error);
  } else {
    debug(`创建并保存quizes-成功：<<<< ${JSON.stringify(data)}`);
  }
  return data;
}
/** 保存活动实例到数据库的函数 */ //
async function _savePracticesData({ planData, saved_quizes, lang = 'en' }) {
  let index = 0;
  const dailyQuizes = planData.map((daily) => daily.map((a) => saved_quizes[index++].id));
  //批量插入practice数据
  const saved_prct_data = dailyQuizes.map((quizId) => ({
    quizes: quizId,
    score: 0,
    count: 0,
    lang: lang
  }));
  debug(`要保存到practice的数据：${JSON.stringify(saved_prct_data)}`, 2);
  const { data, error } = await supabase.from('user_practices').insert(saved_prct_data).select('id');
  if (error) {
    console.error('practice保存失败：', error);
  } else {
    debug(`practice保存成功：<<< ${JSON.stringify(data)}`);
  }
  return data;
}
/** 保存活动实例到数据库的函数 */ //
async function _savePlanData({ user_id, saved_practices, saved_material, cozeOutput, focusIndicators }) {
  const saved_plan_data = {
    user_id: user_id,
    start_date: new Date(),
    end_date: new Date(Date.now() + TotalDaysforPlan * 86400000),
    target_indicators: focusIndicators.map((ind) => ind.id),
    practices: saved_practices.map((p) => p.id),
    target_material: saved_material.id,
    material_snapshot: cozeOutput,
    topic_title: cozeOutput.topic_title,
    level: cozeOutput.level
  };
  debug(`要保存到计划的数据：${JSON.stringify(saved_plan_data)}`, 2);
  const { data, error } = await supabase.from('user_weekly_plans').insert(saved_plan_data).select().single();
  if (error) {
    console.error('学习计划保存失败：', JSON.stringify(error));
  } else {
    debug(`学习计划保存成功<<< ${JSON.stringify(data)}`);
  }
  return data;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 获取用户能力短板指标 */ //
async function _getFocusIndicators(inds) {
  const { data, error: indicatorsError } = await supabase.schema('research_core').from("indicators").select().in('id', inds).order("level");
  if (!data || data.length === 0) throw new Error("指标库为空");
  const totalLevel = data.reduce((sum, ind) => sum + ind.level, 0);
  return {
    focusIndicators: data.map((ind) => ({
      ...ind,
      current_score: 0
    })),
    currentLevel: Math.round(totalLevel / data.length) //通过平均算出所在级别
  };
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 获取各材料数量 */ ///
function _getMaterialQuantities(focusIndicators, totalDuration) {
  //计算材料占比
  const materialTypeWeights = new Map();
  focusIndicators.forEach((indicator) => {
    // 遍历指标适用的材料类型
    indicator.material_types.forEach((type) => {
      if (!materialTypeWeights.has(type)) materialTypeWeights.set(type, 0);
      materialTypeWeights.set(type, materialTypeWeights.get(type) + indicator.weight);
    });
  });
  // 计算总权重并归一化得到占比
  const totalWeight = [
    ...materialTypeWeights.values()
  ].reduce((sum, w) => sum + w, 0);
  const materialTypeRatios = new Map();
  [
    ...materialTypeWeights.entries()
  ].forEach(([type, weight]) => {
    materialTypeRatios.set(type, weight / totalWeight);
  });
  debug(`_getMaterialQuantities>>materialTypeRatios:${totalWeight},${JSON.stringify([
    ...materialTypeRatios
  ])}`, 3);
  // 计算材料时长
  const materialDurations = new Map();
  [
    ...materialTypeRatios.entries()
  ].forEach(([type, ratio]) => {
    if (STANDARD_DURATIONS[type]) {
      materialDurations.set(type, Math.round(totalDuration * ratio));
      debug(`STANDARD_DURATIONS[type]:${type}-${materialDurations.get(type)}`);
    }
  });
  debug(`_getMaterialQuantities>>>材料类型时长：${JSON.stringify([
    ...materialDurations.entries()
  ])}`, 3);
  // 5. 根据标准时长计算每种材料的数量
  const materialQuantities = {
    character: 0,
    word: 0,
    syllable: 0,
    grammar: 0,
    sentence: 0,
    dialog: 0,
    paragraph: 0
  };
  [
    ...materialDurations.entries()
  ].forEach(([type, duration]) => {
    const standard = STANDARD_DURATIONS[type];
    // 分配时长除以标准时长，取上限避免0
    materialQuantities[type] = Math.max(1, Math.ceil(duration / standard));
  });
  return materialQuantities;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 获取用户最近的学习材料记录（用于复习内容和标签）*/ //
async function _getUserScoreRecord(userId, quantity, level) {
  const count = {
    character: Math.round(quantity['character'] * (level * .4 / 9 + 0.3)),
    word: Math.round(quantity['word'] * (level * .4 / 9 + 0.3))
  };
  const { data, error } = await supabase.from("user_score_records").select("category,item,score,count,update_at").eq("user_id", userId).in('category', [
    'character',
    'word'
  ]).order("update_at");
  if (error || !data) {
    // 如果没有历史记录，返回默认空值
    return {
      chars: [],
      words: []
    };
  }
  const record = {
    chars: data.filter((item) => item.category == 'character').filter((item) => item.score < 0.6).sort((a, b) => b.score - a.score).slice(0, count.character).map((item) => item.item),
    words: data.filter((item) => item.category == 'word').filter((item) => item.score < 0.6).sort((a, b) => b.score - a.score).slice(0, count.word).map((item) => item.item)
  };
  //TODO: 先返回历史分数最低字词，未来按遗忘策略更新算法
  // 正确率因素：总分/练习总次数；
  // 时间因素：Math.pow(TIME_DECAY_RATE, (Date.now() - data.lastDate.getTime()) / 86400000);
  // 练习次数因素：总次数/最小次数 Math.min(1, data.totalPractice / MIN_PRACTICE)
  // (正确率因素 * 60%) + (时间因素 * 30%) + (练习次数因素 * 10%)
  ///materialQuantities[type]
  return record;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 查找已学的材料 chars,words,topic_tag,culture_tag*/ //
async function _getExists(userId, level) {
  //查找已学的
  const { data, error } = await supabase.from('user_materials').select('chars,words,topic_tag,culture_tag').eq('user_id', userId).eq('level', level);
  const exist = {
    chars: {},
    words: {},
    topic_tags: {},
    culture_tags: {}
  };
  if (error || !data) {
    return exist;
  }
  if (data && data.length > 0) {
    data.forEach((item) => {
      // 处理字符
      item.chars.forEach((char) => {
        if (char) {
          exist.chars[char] = (exist.chars[char] || 0) + 1;
        }
      });
      // 处理词语
      item.words.forEach((word) => {
        if (word) {
          exist.words[word] = (exist.words[word] || 0) + 1;
        }
      });
      // 处理主题标签
      if (item.topic_tag) {
        exist.topic_tags[item.topic_tag] = (exist.topic_tags[item.topic_tag] || 0) + 1;
      }
      // 处理文化标签
      if (item.culture_tag) {
        exist.culture_tags[item.culture_tag] = (exist.culture_tags[item.culture_tag] || 0) + 1;
      }
    });
  }
  return exist;
}
const COZE_TOKEN = Deno.env.get("COZE_TOKEN_RUN"); //COZE_TOKEN_RUN
const COZE_WORKFLOW_ID = Deno.env.get("COZE_WORKFLOW_ID");
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 生成材料 */ //
async function _callCozeWorkflow(input) {
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
    debug(`Coze API 响应状态码:>>> ${response.status}`);
    if (!response.ok) {
      throw new Error(`Coze API调用失败（状态码：${response.status}）${response.statusText}`);
    }
    const responseJson = await response.json();
    debug(`Coze API 响应内容response:<<< ${responseJson.data}`);
    const output = JSON.parse(responseJson.data).output;
    if (!output) {
      throw new Error(`Coze API返回数据解析output错误, 原数据：${responseJson.data}}`);
    }
    return output;
  } catch (fetchError) {
    throw new Error(`Coze API请求失败：${fetchError.message}`);
  }
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 获取可分配的活动库 */ //
async function _get_allocate_activities({ level, material, indicators, totalDuration, activityIds }) {
  //查询所有活动库
  const { data, error } = activityIds ? await supabase.schema('research_core').from("activities").select().in('id', activityIds) : await supabase.schema('research_core').from("activities").select().eq("available", 1);
  if (error) throw new Error(`活动库查询失败：${data.message}`);
  //初始化前置数据
  const inputActivities = data.map((act) => ({
    ...act,
    indicator_id: Number.NaN,
    level: Number.NaN
  }));
  const totalStudyTime = getTotalTimeByLevel(level, totalDuration); // 分钟/周
  // 按类别分类的学习材料
  const tidyMeterials = [
    {
      type: 'character',
      data: material.chars_new.concat(material.chars_review),
      timePerUnit: 2
    },
    {
      type: 'word',
      data: material.words_new.concat(material.words_review),
      timePerUnit: 3
    },
    {
      type: 'sentence',
      data: material.sentences,
      timePerUnit: 4
    },
    {
      type: 'dialog',
      data: material.dialogs,
      // data: material.dialogs.map((dialog)=>JSON.stringify(dialog.chat)),
      timePerUnit: 8
    },
    {
      type: 'paragraph',
      data: material.paragraphs,
      timePerUnit: 12
    },
    {
      type: 'syllable',
      data: material.syllables,
      timePerUnit: 5
    },
    {
      type: 'grammar',
      data: material.grammars,
      timePerUnit: 10
    }
  ];
  // 最终要使用的活动库权重分配MAP
  const allocationMap = [];
  // 步骤1：筛选符合条件的活动
  const candidateActivities = inputActivities.filter((act) => indicators.some((ind) => {
    act.indicator_id = ind.id;
    act.level = ind.level;
    return act.indicator_cats.includes(ind.category); // && act.quiz_type == '选择题';
  }));
  debug(`candidateActivities::${JSON.stringify(candidateActivities)}`, 2);
  // 步骤2：按能权重分配时间给活动库
  // 按能力指标分配总时间
  const abilityWeights = new Map();
  // 设置能力权重
  indicators.forEach((ind) => {
    abilityWeights.set(ind.category, Math.round(ind.weight / (ind.current_score + 1) * 100)); //避免0分，乘100陬整避免浮点太多
  });
  // 每个能力指标的时间池,按能力指标权重分配时间
  const abilityTimePool = new Map();
  const totalWeight = Array.from(abilityWeights.values()).reduce((a, b) => a + b, 0);
  abilityWeights.forEach((weight, category) => {
    abilityTimePool.set(category, weight / totalWeight * totalStudyTime);
  });
  // 步骤3：计算时间分配的权重
  candidateActivities.forEach((activity) => {
    const supportedAbilities = activity.indicator_cats;
    // 同一活动符合多指标时，在能力指标内部分配时间给活动，一个活动内多项指标权重时间取均值为该活动时长
    const sharedTime = supportedAbilities.map((cat) => abilityTimePool.get(cat) || 0).reduce((a, b) => a + b, 0) / supportedAbilities.length;
    // 按材料计算活动权重
    const weight = calculateActivityWeightByMaterials(activity);
    // 精确到3位浮点
    // allocation.set(activity, Math.round(sharedTime * weight * 1000) / 1000);
    allocationMap.push({
      activity,
      weight: Math.round(sharedTime * weight * 1000) / 1000
    });
  });
  // 多重权重计算
  function calculateActivityWeightByMaterials(activity) {
    const materials = activity.material_type.reduce((arr, type) => {
      const m = tidyMeterials.find((i) => i.type === type);
      return m ? [
        ...arr,
        ...m.data
      ] : arr;
    }, []);
    // 多样性因子（避免选择题类型活动过多）
    const diversityFactor = 1; //1 / (activity.quiz_type === '选择题' ? 1.5 : 1);
    // 材料充足度因子
    const materialFactor = Math.min(1, materials.length / 5);
    // 时间效率因子
    const timeFactor = 1 / Math.sqrt(activity.time_cost);
    return diversityFactor * materialFactor * timeFactor;
  }
  return {
    allocationMap,
    tidyMeterials,
    totalStudyTime
  };
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 创建计划 */ //
async function _create_weekly_plan({ allocationMap, tidyMeterials, totalStudyTime }) {
  // -------------------- 生成每日计划 --------------------
  const days = [];
  //活动库的时长单位是秒，周总时长totalStudyTime的单位是分钟
  const dailyMaxTime = totalStudyTime / TotalDaysforPlan * 60;
  // 按活动库权重和活动库单位耗时，生成本周活动库列表
  const totalActWeight = allocationMap.reduce((sum, a) => sum + a.weight, 0);
  const allocationActivities = allocationMap.flatMap((d) => {
    // 计算活动库各组长度
    const group_count = Math.ceil(totalStudyTime * d.weight / totalActWeight / d.activity.time_cost * 60);
    return Array.from({
      length: group_count
    }, () => d.activity);
  });
  //生成拍平后的材料计数map
  const scheduledMaterialsMap = new Map();
  tidyMeterials.forEach((m) => {
    if (m.data) m.data.forEach((d) => {
      scheduledMaterialsMap.set(d, 0);
    });
  });
  // 随机化活动顺序, todo: 后续可以按权重
  const shuffledActivities = allocationActivities.sort(() => Math.random() - 0.5);
  shuffledActivities.forEach((activity) => {
    let targetDay;
    // 获取当前所有天数中已用时间最少的那天 
    const candidateDays = days.filter((day) => day.reduce((sum, a) => sum + a.time_cost, 0) < dailyMaxTime);
    // 累计空闲时长
    const totalEmpty = dailyMaxTime * days.length - days.reduce((sum, day) => sum + day.reduce((sum, a) => sum + a.time_cost, 0), 0);
    if (totalEmpty < activity.time_cost && days.length < TotalDaysforPlan) {
      targetDay = [];
      days.push(targetDay);
      addActivityToDay(activity, targetDay);
    } else {
      targetDay = days[days.length - 1];
      addActivityToDay(activity, targetDay);
    }
    function addActivityToDay(act, day) {
      day.push({
        level: act.level,
        activity_id: act.id,
        act_title: act.activity_title,
        act_category: act.quiz_type,
        indicator_id: act.indicator_id,
        materials: smartFindMaterial(act),
        time_cost: act.time_cost
      });
    }
    // 增强的材料匹配逻辑
    function smartFindMaterial(activity) {
      // 过滤匹配的
      const candidates = tidyMeterials.filter((m) => activity.material_type.includes(m.type));
      //所有用过的材料平铺并记录
      let flatMaterials = candidates.flatMap((m) => m.data.map((d) => {
        return {
          type: m.type,
          content: d
        };
      }));
      const data = flatMaterials.sort((a, b) => (scheduledMaterialsMap.get(a.content) || 0) - (scheduledMaterialsMap.get(b.content) || 0)).map((d) => {
        return d;
      })[0];
      scheduledMaterialsMap.set(data.content, (scheduledMaterialsMap.get(data.content) || 0) + 1);
      return data;
    }
  });
  return days;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 获取本周总学习时长，分钟 */ //
function getTotalTimeByLevel(level, total) {
  const a = [
    total * 1,
    total * 1.2,
    total * 1.3,
    total * 1.4,
    total * 1.5,
    total * 1.6,
    total * 1.7,
    total * 1.8,
    total * 2
  ];
  return total;
  return a[Math.min(Math.max(0, level - 1), a.length - 1)] / 2;
}
