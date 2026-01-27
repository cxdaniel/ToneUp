# Generate Evaluate Exams - 生成评测试题接口

## 功能说明

根据指定的能力指标和题目数量，使用 Coze AI 生成评测试题。用于创建能力测评题库。

**核心流程**：
1. 获取指定的能力指标定义
2. 获取可用的活动模板
3. 按权重分配各指标的题目数量
4. 调用 Coze 生成题目内容
5. 保存到评测题库

## 接口信息

**端点**: `POST /generate_evalute_exams`

**请求体**:
```json
{
  "inds": [1, 2, 3, 4, 5],
  "count": 20,
  "acts": null
}
```

**参数说明**:
| 参数 | 类型 | 必填 | 默认值 | 说明 |
|-----|------|-----|--------|------|
| inds | number[] | ✅ | - | 能力指标ID列表 |
| count | number | ❌ | 10 | 总题目数量 |
| acts | number[] | ❌ | null | 指定活动ID列表（null则自动选择） |

## 响应结构

```json
{
  "success": true,
  "savedCount": 18,
  "evaluations": [
    {
      "id": "eval_001",
      "level": 3,
      "indicator_id": 1,
      "activity_id": 10,
      "stem": "我___学习中文。",
      "question": "请选择正确的词语填空",
      "options": ["在", "是", "有", "到"],
      "correct_answer": 0,
      "explain": "表示正在进行的动作用'在'"
    }
  ]
}
```

## 执行流程

### 1. 获取能力指标
```javascript
const indicators = await getIndicators(inds);
```

从 `research_core.indicators` 表查询指标定义，包含：
- indicator（指标名称）
- weight（权重）
- level（级别）
- category（类别）

### 2. 获取活动模板库
```javascript
const activities = await getActivities(acts);
```

从 `research_core.activities` 表查询活动模板，包含：
- material_type（适用材料类型）
- quiz_type（题型）
- quiz_template（题目模板）
- time_cost（耗时）

### 3. 按权重分配题目
```javascript
indicators.forEach(ind => {
  let quantity = Math.round(ind.weight / totalWeight * count);
  while (quantity > 0) {
    const act = getActByIndCategory(ind, activities);
    targets.push({ indicator: ind, activity: act });
    quantity--;
  }
});
```

**示例**：
- 总题数 20，3个指标权重分别为 0.4, 0.3, 0.3
- 分配：8题（0.4×20）, 6题（0.3×20）, 6题（0.3×20）

### 4. 整理 Coze 请求数据
```javascript
const act_data = targets.map((item, index) => ({
  id: index,
  level: item.indicator.level,
  indicator: item.indicator.indicator,
  material_type: item.activity.material_type[0],
  quiz_type: item.activity.quiz_type,
  quiz_template: item.activity.quiz_template,
  activity_title: item.activity.activity_title,
  time_cost: item.activity.time_cost
}));
```

### 5. 调用 Coze 生成题目
```javascript
const quizzes = await callCozeWorkflow({ act_data });
```

Coze 根据活动模板和指标要求生成具体题目内容。

### 6. 保存到评测题库
```javascript
const evaluations = targets.map((item, i) => ({
  level: item.indicator.level,
  indicator_id: item.indicator.id,
  activity_id: item.activity.id,
  stem: quizzes[i].material,
  question: quizzes[i].question,
  options: quizzes[i].options,
  explain: quizzes[i].explain
}));

await saveEvaluationData(evaluations);
```

保存到评测数据表（具体表名需确认）。

## Coze 工作流

### 输入格式
```json
{
  "act_data": [
    {
      "id": 0,
      "level": 3,
      "indicator": "字符识别",
      "material_type": "character",
      "quiz_type": "choice",
      "quiz_template": "看字选拼音",
      "activity_title": "汉字拼音匹配",
      "time_cost": 2
    },
    {
      "id": 1,
      "level": 3,
      "indicator": "词汇识别",
      "material_type": "word",
      "quiz_type": "fill_blank",
      "quiz_template": "看中文填拼音",
      "activity_title": "词汇拼音填空",
      "time_cost": 3
    }
  ]
}
```

### 输出格式
```json
[
  {
    "material": "学",
    "question": "请选择正确的拼音",
    "options": ["xué", "xuě", "xùe", "shué"],
    "correct_answer": 0,
    "explain": "学的拼音是xué，第二声"
  },
  {
    "material": "学___",
    "question": "请填写'学习'的拼音",
    "answer": "xué xí",
    "explain": "学习的拼音是xué xí"
  }
]
```

## 题型说明

### 选择题（choice）
```json
{
  "material": "我___吃饭。",
  "question": "选择正确的词语",
  "options": ["在", "是", "有", "到"],
  "correct_answer": 0,
  "explain": "表示正在进行用'在'"
}
```

### 填空题（fill_blank）
```json
{
  "material": "我___中文。",
  "question": "填写合适的动词",
  "answer": "学习",
  "explain": "学习是最常用的动词"
}
```

### 排序题（sequence）
```json
{
  "material": ["吗", "好", "你", "？"],
  "question": "排列成正确的句子",
  "correct_order": [2, 1, 0, 3],
  "explain": "正确顺序：你好吗？"
}
```

### 匹配题（matching）
```json
{
  "pairs": [
    {"left": "你好", "right": "hello"},
    {"left": "谢谢", "right": "thank you"}
  ],
  "question": "连接对应的翻译"
}
```

## 活动模板示例

### 汉字拼音选择
```json
{
  "id": 10,
  "material_type": ["character"],
  "quiz_type": "choice",
  "quiz_template": "看字选拼音",
  "activity_title": "汉字拼音匹配",
  "time_cost": 2,
  "category": "recognition"
}
```

### 词汇填空
```json
{
  "id": 20,
  "material_type": ["word"],
  "quiz_type": "fill_blank",
  "quiz_template": "看中文填拼音",
  "activity_title": "词汇拼音填空",
  "time_cost": 3,
  "category": "writing"
}
```

## 数据库依赖

### 查询表
- `research_core.indicators` - 能力指标定义
- `research_core.activities` - 活动模板库

### 写入表
- 评测题库表（待确认表名）

## 使用场景

### 1. 生成级别评测题
```dart
final result = await Supabase.instance.client.functions.invoke(
  'generate_evalute_exams',
  body: {
    'inds': [1, 2, 3, 4, 5], // HSK 3级核心指标
    'count': 30,
  },
);
```

### 2. 生成专项练习题
```dart
// 只针对"字符识别"生成练习题
final result = await Supabase.instance.client.functions.invoke(
  'generate_evalute_exams',
  body: {
    'inds': [1], // 只有一个指标
    'count': 50,
  },
);
```

### 3. 使用特定活动模板
```dart
final result = await Supabase.instance.client.functions.invoke(
  'generate_evalute_exams',
  body: {
    'inds': [1, 2, 3],
    'count': 20,
    'acts': [10, 11, 12], // 指定活动ID
  },
);
```

## 性能指标

| 阶段 | 耗时 |
|-----|------|
| 查询指标 | ~0.2s |
| 查询活动 | ~0.2s |
| 题目分配 | ~0.1s |
| **Coze生成** | **~5-10s** |
| 保存数据库 | ~0.5s |
| **总耗时** | **~6-11s** |

## 错误处理

### 参数错误
```json
{
  "error": "缺少参数: inds. 量化指标列表"
}
```

### Coze生成失败
```json
{
  "error": "Coze workflow failed: timeout"
}
```

### 部分保存失败
如果某些题目的 `question` 字段为空，会自动过滤：
```javascript
.filter((quiz) => quiz.question != null)
```

## cURL示例

```bash
curl -X POST \
  'https://xxx.supabase.co/functions/v1/generate_evalute_exams' \
  -H "Authorization: Bearer YOUR_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "inds": [1, 2, 3],
    "count": 20
  }'
```

## 环境变量

```bash
SUPABASE_URL=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx
COZE_API_KEY=xxx
COZE_WORKFLOW_ID_EXAM=xxx
```

## 版本历史

- **v1.0** (2026-01-27): 初始版本

### moke数据
```json
// 生成exam
{"inds":[1,2,4,5,7,9,11,3,16,13,14,6,8,10,15,12], "lang":"ja"}                //level1
{"inds":[17,18,20,21,23,25,27,19,32,29,30,22,24,26,31,28]}       //level2
{"inds":[33,34,36,37,39,41,43,35,48,45,46,38,40,42,47,44]}       //level3
{"inds":[49,50,52,53,55,63,57,59,51,62,61,54,56,58,60]}          //level4
{"inds":[64,65,67,68,73,70,79,72,75,66,78,77,69,71,74,76]}       //level5
{"inds":[80,81,83,84,86,94,88,90,82,93,92,85,87,89,91]}          //level6
{"inds":[95,96,98,99,101,108,103,105,97,107,100,102,104,106]}    //level7
{"inds":[109,110,112,113,115,121,117,111,120,114,116,118,119]}   //level8
{"inds":[122,123,125,126,127,133,129,124,132,128,130,131]}       //level9
```