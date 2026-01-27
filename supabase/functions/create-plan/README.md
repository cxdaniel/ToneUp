# Create Plan - 学习计划生成接口

## 功能说明

根据用户能力短板和学习时长，生成个性化的学习计划。使用 Coze AI 工作流生成学习材料，并自动分配到合适的学习活动中。

**核心流程**：
1. 分析用户能力短板（调用 `get-focus-indicators`）
2. 根据时长分配材料数量
3. 查询用户已学材料和需复习内容
4. 调用 Coze AI 生成新材料
5. 分配活动实例并保存计划

## 接口信息

**端点**: `POST /create-plan`

**请求体**:
```json
{
  "user_id": "uuid",
  "inds": [1, 2, 3],
  "dur": 60,
  "acts": [10, 20, 30]
}
```

**参数说明**:
| 参数 | 类型 | 必填 | 默认值 | 说明 |
|-----|------|-----|--------|------|
| user_id | string | ✅ | - | 用户ID |
| inds | number[] | ✅ | - | 关注的能力指标ID列表 |
| dur | number | ❌ | 60 | 学习时长（分钟） |
| acts | number[] | ❌ | null | 指定活动ID列表（null表示自动分配） |

## 响应格式

### 流式响应（Server-Sent Events）

接口返回流式数据，实时推送进度和结果：

```json
// 进度消息
{
  "type": "progress",
  "step": 1,
  "message": "Analyzing user ability data...",
  "data": {
    "currentLevel": 3,
    "indicatorCount": 5
  },
  "timestamp": "2026-01-27T10:00:00.000Z"
}

// 完成消息
{
  "type": "complete",
  "result": {
    "planId": "plan_123",
    "totalPractices": 12,
    "estimatedDuration": 60
  },
  "timestamp": "2026-01-27T10:01:30.000Z"
}

// 错误消息
{
  "type": "error",
  "error": "Failed to generate materials",
  "timestamp": "2026-01-27T10:01:00.000Z"
}
```

## 执行步骤

### 步骤1: 分析用户能力（~1s）
```json
{
  "step": 1,
  "message": "Analyzing user ability data...",
  "data": {
    "currentLevel": 3,
    "indicatorCount": 5
  }
}
```

调用 `get-focus-indicators` 获取用户当前级别和需要重点提升的能力指标。

### 步骤2: 计算材料分配（~0.1s）
```json
{
  "step": 2,
  "message": "Calculating material distribution...",
  "data": {
    "character": 5,
    "word": 8,
    "sentence": 3
  }
}
```

根据总时长和材料标准时长计算各类型材料数量：
```typescript
const STANDARD_DURATIONS = {
  character: 2,    // 单字 2分钟
  word: 3,         // 词汇 3分钟
  sentence: 4,     // 句子 4分钟
  dialog: 8,       // 对话 8分钟
  paragraph: 12    // 段落 12分钟
};
```

### 步骤3: 查询已学材料（~0.5s）
```json
{
  "step": 3,
  "message": "Fetching learned materials...",
  "data": {
    "learnedCount": 150
  }
}
```

查询用户在当前级别已学过的材料，避免重复生成。

### 步骤4: 查询复习材料（~0.5s）
```json
{
  "step": 4,
  "message": "Fetching review materials...",
  "data": {
    "reviewCount": 20
  }
}
```

根据学习记录查询需要复习的材料（chars_review, words_review）。

### 步骤5: 生成学习材料（~5-10s）
```json
{
  "step": 5,
  "message": "Generating learning materials with AI...",
  "data": {
    "status": "calling_coze_workflow"
  }
}
```

调用 Coze AI 工作流生成新材料，包含：
- 汉字、词汇、句子、对话、段落
- HSK级别标注
- 主题和文化标签
- 15维能力指标关联

### 步骤6: 分配学习活动（~1s）
```json
{
  "step": 6,
  "message": "Allocating activities...",
  "data": {
    "totalActivities": 24
  }
}
```

为每个材料分配合适的学习活动模板。

### 步骤7: 生成练习实例（~2s）
```json
{
  "step": 7,
  "message": "Generating practice instances...",
  "data": {
    "practiceCount": 24
  }
}
```

创建具体的练习实例（activity_instances），但此时题目内容为空。

### 步骤8: 保存学习计划（~0.5s）
```json
{
  "step": 8,
  "message": "Saving plan to database...",
  "data": {
    "planId": "plan_123"
  }
}
```

保存到 `user_weekly_plan` 和 `user_practice` 表。

### 完成响应
```json
{
  "type": "complete",
  "result": {
    "planId": "plan_abc123",
    "userId": "user_xyz",
    "level": 3,
    "totalDuration": 60,
    "practiceCount": 12,
    "createdAt": "2026-01-27T10:01:30.000Z"
  },
  "timestamp": "2026-01-27T10:01:30.000Z"
}
```

## 计划参数配置

### 每周练习量（按级别）
```typescript
const TotalDaysforPlan = {
  1-3: 6天,   // 初级
  4-6: 9天,   // 中级
  7-9: 12天   // 高级
};
```

### 材料标准时长
| 材料类型 | 时长（分钟） | 说明 |
|---------|------------|------|
| character | 2 | 单字学习 |
| word | 3 | 词汇学习 |
| syllable | 5 | 音节练习 |
| grammar | 10 | 语法讲解 |
| sentence | 4 | 句子理解 |
| dialog | 8 | 对话练习 |
| paragraph | 12 | 段落阅读 |
| chars_review | 1 | 汉字复习 |
| words_review | 1.5 | 词汇复习 |

## Coze AI 工作流输入

```json
{
  "level": 3,
  "focusIndicators": [
    "字符识别",
    "词汇识别",
    "句子理解"
  ],
  "materialQuantities": {
    "character": 5,
    "word": 8,
    "sentence": 3
  },
  "needReviews": {
    "chars_review": ["你", "好", "吗"],
    "words_review": ["你好", "谢谢"]
  },
  "exists": ["材料ID1", "材料ID2"]
}
```

## 客户端调用示例

### Dart/Flutter（流式接收）
```dart
await for (final progress in DataService().generatePlanWithProgress(
  userId: userId,
  inds: [1, 2, 3],
  dur: 60,
)) {
  final type = progress['type'];
  
  if (type == 'progress') {
    final step = progress['step'];
    final message = progress['message'];
    updateProgressUI(step, message);
  } else if (type == 'complete') {
    final planId = progress['result']['planId'];
    navigateToPlan(planId);
  } else if (type == 'error') {
    showError(progress['error']);
  }
}
```

### cURL（查看原始流）
```bash
curl -X POST \
  'https://kixonwnuivnjqlraydmz.supabase.co/functions/v1/create-plan' \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "123e4567-e89b-12d3-a456-426614174000",
    "inds": [1, 2, 3],
    "dur": 60
  }' \
  --no-buffer
```

## 数据库依赖

### 查询表
- `research_core.indicators` - 能力指标定义
- `user_ability_history` - 用户能力历史
- `user_score_records` - 学习记录（用于查找复习材料）
- `learning_materials` - 材料库（查找已存在材料）
- `research_core.activities` - 活动模板库

### 写入表
- `user_weekly_plan` - 学习计划主表
- `user_practice` - 练习列表
- `activity_instances` - 活动实例（题目占位）

## 性能指标

| 阶段 | 耗时 | 说明 |
|-----|------|------|
| 能力分析 | ~1s | 调用 check_for_upgrade |
| 材料计算 | ~0.1s | 本地计算 |
| 查询已学 | ~0.5s | 数据库查询 |
| 查询复习 | ~0.5s | 数据库查询 |
| **AI生成** | **~5-10s** | **Coze工作流（最耗时）** |
| 活动分配 | ~1s | 本地匹配算法 |
| 生成实例 | ~2s | 批量插入 |
| 保存计划 | ~0.5s | 数据库写入 |
| **总耗时** | **~10-15s** | - |

## 错误处理

### 参数错误（400）
```json
{
  "type": "error",
  "error": "缺少参数: user_id, inds",
  "timestamp": "2026-01-27T10:00:00.000Z"
}
```

### Coze调用失败
```json
{
  "type": "error",
  "error": "Failed to call Coze workflow: timeout",
  "timestamp": "2026-01-27T10:00:30.000Z"
}
```

## 依赖的Edge Functions

- `get-focus-indicators` - 获取用户能力短板

## 环境变量

```bash
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=xxx
COZE_API_KEY=xxx           # Coze API密钥
COZE_WORKFLOW_ID_PLAN=xxx  # 计划生成工作流ID
```

## 版本历史

- **v2.0** (2026-01-27): 增加流式响应，实时推送进度
- **v1.5** (2026-01-25): 集成 Coze AI 工作流
- **v1.0** (2026-01-20): 初始版本
