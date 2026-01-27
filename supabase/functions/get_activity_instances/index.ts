// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
console.info('get_activity_instances started');
const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 部署接口 */ //
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
  try {
    const { ids } = await req.json();
    if (!ids) {
      throw new Error("缺少参数：检查参数 ids");
    }
    // 创建可写流用于持续发送数据
    const { readable, writable } = new TransformStream({
      transform (chunk, controller) {
        controller.enqueue(`data: ${JSON.stringify(chunk)}\n\n`);
      }
    });
    // 1. 获取活动实例数据
    const quizData = await getQuizesData(JSON.parse(ids));
    if (!quizData || quizData.length === 0) {
      return new Response(JSON.stringify({
        error: '未找到对应的 user_activity_data 记录'
      }), {
        status: 404,
        headers: {
          'Content-Type': 'application/json'
        }
      });
    }
    console.log(`quizData:${JSON.stringify(quizData)}`);
    const quizExist = quizData.reduce((a, b)=>a && b.question != null, true);
    if (quizExist) {
      return new Response(JSON.stringify(quizData), {
        headers: {
          'Content-Type': 'application/json',
          "Access-Control-Allow-Origin": "*"
        },
        status: 200
      });
    }
    const withoutQuiz = quizData.filter((quiz)=>quiz.question == null);
    const withQuiz = quizData.filter((quiz)=>quiz.question != null);
    console.log(`需要生成的题目${withoutQuiz.length}个: ${JSON.stringify(withoutQuiz)}`);
    // 2. 查询关联活动库模板
    const actMap = await getActivityData(withoutQuiz);
    // 3. 查询关联能力指标
    const indMap = await getIndicatorData(withoutQuiz);
    // 4. 准备请求数据并生成题目
    const mergeData = withoutQuiz.map((quiz)=>({
        ...quiz,
        activity: actMap.get(quiz.activity_id) || null,
        indicator: indMap.get(quiz.indicator_id) || null
      }));
    const quiz_data = mergeData.map((quiz)=>{
      return {
        id: quiz.id,
        quiz_template: quiz.activity.quiz_template,
        material: quiz.material,
        material_type: quiz.material_type,
        activity_title: quiz.activity.activity_title,
        indicator: quiz.indicator.indicator,
        topic_tag: quiz.topic_tag,
        culture_tag: quiz.culture_tag,
        time_cost: quiz.activity.time_cost,
        level: quiz.level,
        lang: quiz.lang
      };
    });
    const quizes = await callCozeWorkflow({
      quiz_data
    });
    // 5. 更新生成好题目的quiz数据
    const actUpdateIds = withoutQuiz.map((e)=>e.id);
    const updated = await updateQuizzesSimple(quizes, withoutQuiz);
    const res = [
      ...withQuiz,
      ...updated
    ];
    //
    return new Response(JSON.stringify(res), {
      headers: {
        'Content-Type': 'application/json',
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
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 获取活动库实例数据 */ //
async function getQuizesData(quizIds) {
  console.log(`获取活动库实例数据getQuizesData:::start:::${quizIds},length:${quizIds.length}`);
  // 确保所有ID都是数字
  const validIds = quizIds.filter((id)=>!isNaN(Number(id))).map(Number);
  if (validIds.length === 0) {
    return new Response(JSON.stringify({
      error: 'instanceIds 中没有有效的数字ID'
    }), {
      status: 400,
      headers: {
        'Content-Type': 'application/json'
      }
    });
  }
  // 批量查询 user_activity_instances 表（public schema）
  const { data, error } = await supabase.from('quizes').select().in('id', validIds); // 匹配ID列表
  if (error) throw error;
  return data;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 查询实例对应的活动库模板数据 */ //
async function getActivityData(quizes) {
  // 1. 提取所有关联的 activity_id（去重）
  const activityIds = [
    ...new Set(quizes.map((quiz)=>quiz.activity_id))
  ];
  // 2. 批量查询关联的 activities 表（research_core schema）
  console.log(`批量查询关联的 activities 表::::start`);
  const { data: activities, error: activityError } = await supabase.schema('research_core').from('activities').select().in('id', activityIds); // 匹配activity_id列表
  if (activityError) throw activityError;
  // 3. 将activities转换为Map（key: activity_id, value: activity数据），方便匹配
  const activityMap = new Map();
  activities.forEach((act)=>{
    activityMap.set(act.id, act);
  });
  console.log(`批量查询关联的 activities 表::::result:::${JSON.stringify(activities)}`);
  return activityMap;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 查询实例对应的能力指标数据 */ //
async function getIndicatorData(quizes) {
  const indicatorIds = [
    ...new Set(quizes.map((quiz)=>quiz.indicator_id))
  ];
  // 5. 批量查询关联的 indicators 表（research_core schema）
  console.log(`批量查询关联的 indicators 表::::start`);
  const { data: indicators, error: indicatorError } = await supabase.schema('research_core') // 指定非public schema
  .from('indicators').select().in('id', indicatorIds); // 匹配indicator_id列表
  if (indicatorError) throw indicatorError;
  // 6. 将indicators转换为Map（key: indicator_id, value: activity数据），方便匹配
  const indicatorMap = new Map();
  indicators.forEach((ind)=>{
    indicatorMap.set(ind.id, ind);
  });
  console.log(`批量查询关联的 indicators 表::::result:::${JSON.stringify(indicators)}`);
  // 7. 合并数据：为每个instance添加对应的activity
  console.log(`合并数据：为每个instance添加对应的activity::::start`);
  return indicatorMap;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 保存Quiz数据 简单可靠的循环更新（无事务，适合中小数据量） */ //
//TODO更新逻辑可以再简单点
const updateQuizzesSimple = async (genData, quizes)=>{
  // 构建批量更新 payload
  const errors = [];
  const updates = quizes.map((quiz, i)=>{
    const update = genData[i];
    if (!update || !update.question) {
      errors.push(quiz);
      return null;
    }
    return {
      id: quiz.id,
      stem: update.material,
      question: update.question,
      options: update.options,
      explain: update.explain
    };
  }).filter(Boolean);
  if (updates.length === 0) throw new Error('没有可更新的数据');
  const { data, error } = await supabase.from('quizes').upsert(updates, {
    onConflict: 'id'
  }) // 指定主键列
  .select();
  if (error) throw error;
  if (updates.length < quizes.length) throw new Error(`部分更新失败，共${errors.length}项: ${errors.map((e)=>e.id)}`);
  return data;
// const results = [];
// const errors = [];
// for(let i = 0; i < quizes.length; i++){
//   const update = genData[i];
//   const quiz = quizes[i];
//   if (update && update.question != '') {
//     try {
//       const { data, error } = await supabase.from('quizes').update({
//         stem: update.material,
//         question: update.question,
//         options: update.ontions,
//         explain: update.explain
//       }).eq('id', quiz.id).select().maybeSingle(); //limit(1).maybeSingle();
//       if (error) throw error;
//       results.push(data);
//     } catch (error) {
//       console.error(`更新ID ${quiz.id} 失败: `, error);
//     }
//   } else {
//     errors.push(quiz);
//   }
// }
// if (results.length < quizes.length) throw new Error(`部分更新失败，共${errors.length}项: ${errors.map((e)=>e.id)}`);
// return results;
};
const COZE_TOKEN = Deno.env.get("COZE_TOKEN_RUN"); //COZE_TOKEN_RUN
const COZE_WORKFLOW_ID = Deno.env.get("COZE_WORKFLOW_GETQUIZ");
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/** 封装Coze API调用（单独函数，便于维护） */ //
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
    const result = JSON.parse(responseJson.data).output;
    if (!result) {
      throw new Error(`Coze API返回数据解析output错误, 原数据：${responseJson.data}} `);
    }
    return result;
  } catch (fetchError) {
    throw new Error(`Coze API请求失败：${fetchError.message} `);
  }
}
