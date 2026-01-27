# Get Activity Instances - 获取活动实例接口

## 功能说明

根据活动实例ID列表，获取完整的练习题目数据。如果题目未生成，会调用 Coze AI 自动生成题目内容。

**核心特性**：
- ✅ 智能检测题目是否已生成
- ✅ 自动调用 Coze 补全缺失的题目
- ✅ 返回完整的可执行练习数据

## 接口信息

**端点**: `POST /get_activity_instances`

**请求体**:
```json
{
  "ids": "[123, 124, 125]"
}
```

**参数说明**:
| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| ids | string | ✅ | 活动实例ID数组（JSON字符串格式） |

## 响应结构

```json
[
  {
    "id": 123,
    "level": 3,
    "indicator_id": 1,
    "activity_id": 10,
    "material": "学",
    "material_type": "character",
    "topic_tag": "education",
    "culture_tag": null,
    "question": "请选择正确的拼音",
    "options": ["xué", "xuě", "xùe", "shué"],
    "correct_answer": 0,
    "explain": "学的拼音是xué，第二声"
  },
  {
    "id": 124,
    "level": 3,
    "indicator_id": 2,
    "activity_id": 20,
    "material": "学习",
    "material_type": "word",
    "topic_tag": "education",
    "culture_tag": null,
    "question": "选择正确的意思",
    "options": ["to study", "to teach", "to work", "to play"],
    "correct_answer": 0,
    "explain": "学习means to study or to learn"
  }
]
```

## 执行流程

### 1. 查询活动实例数据
```javascript
const quizData = await getQuizesData(JSON.parse(ids));
```

从 `activity_instances` 表查询所有实例的基础数据。

### 2. 检查题目完整性
```javascript
const quizExist = quizData.reduce(
  (a, b) => a && b.question != null, 
  true
);
```

**判断逻辑**：
- ✅ 如果所有实例都有 `question` 字段 → 直接返回
- ❌ 如果有实例缺少题目 → 继续生成流程

### 3. 分类处理
```javascript
const withoutQuiz = quizData.filter(
  quiz => quiz.question == null
);
const withQuiz = quizData.filter(
  quiz => quiz.question != null
);
```

将有题目和无题目的实例分开处理。

### 4. 查询关联的活动模板
```javascript
const actMap = await getActivityData(withoutQuiz);
```

从 `research_core.activities` 表查询活动模板信息：
- quiz_template（题目模板）
- quiz_type（题型）
- activity_title（活动标题）

### 5. 查询关联的能力指标
```javascript
const indMap = await getIndicatorData(withoutQuiz);
```

从 `research_core.indicators` 表查询指标信息：
- indicator（指标名称）
- level（级别）

### 6. 合并数据准备生成
```javascript
const quiz_data = withoutQuiz.map(quiz => ({
  id: quiz.id,
  quiz_template: activity.quiz_template,
  material: quiz.material,
  material_type: quiz.material_type,
  activity_title: activity.activity_title,
  indicator: indicator.indicator,
  topic_tag: quiz.topic_tag,
  culture_tag: quiz.culture_tag,
  time_cost: activity.time_cost,
  level: quiz.level
}));
```

### 7. 调用 Coze 生成题目
```javascript
const quizzes = await callCozeWorkflow({ quiz_data });
```

Coze 根据材料内容和活动模板生成具体题目。

### 8. 更新数据库
```javascript
await updateQuizzesSimple(quizzes, withoutQuiz);
```

将生成的题目更新到 `activity_instances` 表。

### 9. 返回完整数据
```javascript
return [...withQuiz, ...updated];
```

合并已有题目和新生成的题目。

## Coze 工作流

### 输入格式
```json
{
  "quiz_data": [
    {
      "id": 123,
      "quiz_template": "看字选拼音",
      "material": "学",
      "material_type": "character",
      "activity_title": "汉字拼音匹配",
      "indicator": "字符识别",
      "topic_tag": "education",
      "culture_tag": null,
      "time_cost": 2,
      "level": 3
    }
  ]
}
```

### 输出格式
```json
[
  {
    "question": "请选择正确的拼音",
    "options": ["xué", "xuě", "xùe", "shué"],
    "correct_answer": 0,
    "explain": "学的拼音是xué，第二声"
  }
]
```

## 活动实例数据结构

### 基础字段（来自 activity_instances 表）
```typescript
{
  id: number,              // 实例ID
  level: number,           // 级别
  indicator_id: number,    // 能力指标ID
  activity_id: number,     // 活动模板ID
  material: string,        // 材料内容（如"学"、"学习"）
  material_type: string,   // 材料类型（character/word/sentence）
  topic_tag: string,       // 主题标签（education/food/travel）
  culture_tag: string      // 文化标签
}
```

### 题目字段（由 Coze 生成）
```typescript
{
  question: string,        // 题目问题
  options: string[],       // 选项（选择题）
  correct_answer: number,  // 正确答案索引
  answer: string,          // 答案文本（填空题）
  explain: string          // 解析说明
}
```

## 使用场景

### 1. 获取练习题目
```dart
final result = await Supabase.instance.client.functions.invoke(
  'get_activity_instances',
  body: {
    'ids': jsonEncode([123, 124, 125]),
  },
);

final quizzes = result.data as List;
// 开始练习
quizzes.forEach((quiz) {
  showQuiz(quiz);
});
```

### 2. 批量预加载题目
```dart
// 用户创建计划后，预加载所有练习题目
final planPractices = await getPlanPractices(planId);
final instanceIds = planPractices.map((p) => p.activityInstanceId);

await Supabase.instance.client.functions.invoke(
  'get_activity_instances',
  body: {'ids': jsonEncode(instanceIds)},
);
// 所有题目已生成并缓存，后续练习无需等待
```

### 3. 懒加载（按需生成）
```dart
// 用户点击开始练习时才生成题目
void startPractice(int instanceId) async {
  showLoading();
  
  final result = await Supabase.instance.client.functions.invoke(
    'get_activity_instances',
    body: {'ids': jsonEncode([instanceId])},
  );
  
  hideLoading();
  showQuiz(result.data[0]);
}
```

## 性能优化

### 快速路径（所有题目已生成）
```javascript
if (quizExist) {
  return quizData; // 直接返回，耗时 ~0.2s
}
```

### 生成路径（部分题目缺失）
| 阶段 | 耗时 |
|-----|------|
| 查询实例 | ~0.2s |
| 查询活动模板 | ~0.2s |
| 查询能力指标 | ~0.2s |
| **Coze 生成** | **~5-10s** |
| 更新数据库 | ~0.5s |
| **总耗时** | **~6-11s** |

### 批量优化建议
```dart
// ❌ 不推荐：逐个查询
for (final id in instanceIds) {
  await getActivityInstance(id); // N次网络请求
}

// ✅ 推荐：批量查询
await getActivityInstances(instanceIds); // 1次网络请求
```

## 数据库依赖

### 查询表
- `activity_instances` - 活动实例表（主表）
- `research_core.activities` - 活动模板库
- `research_core.indicators` - 能力指标定义

### 更新表
- `activity_instances` - 更新 question, options, explain 等字段

## 错误处理

### 参数错误
```json
{
  "error": "缺少参数：检查参数 ids"
}
```

### Coze 生成失败
如果 Coze 返回的某个题目缺少 `question`，会自动过滤：
```javascript
.filter((quiz) => quiz.question != null)
```

### 部分成功
即使部分题目生成失败，也会返回成功生成的部分：
```json
[
  { "id": 123, "question": "...", ... },  // 成功
  { "id": 124, "question": null, ... }    // 失败，但仍返回基础数据
]
```

## cURL 示例

```bash
curl -X POST \
  'https://xxx.supabase.co/functions/v1/get_activity_instances' \
  -H "Authorization: Bearer YOUR_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "ids": "[123, 124, 125]"
  }'
```

## 环境变量

```bash
SUPABASE_URL=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx
COZE_API_KEY=xxx
COZE_WORKFLOW_ID_QUIZ=xxx
```

## 与其他接口的配合

### 完整流程
```
1. create-plan 
   → 创建计划，生成 activity_instances（题目为空）

2. get_activity_instances 
   → 获取实例时自动生成题目内容

3. 用户练习
   → 提交答案，记录得分

4. 更新 user_ability_history
   → 保存练习结果
```

## 版本历史

- **v1.0** (2026-01-27): 初始版本，支持自动生成缺失题目

### moke数据
```json
{"ids":"[133,134,135]"}
```