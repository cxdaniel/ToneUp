# Gen Target Material - 生成目标学习材料接口

## 功能说明

**轻量级计划生成接口**。与 `create-plan` 的区别是：
- ❌ 不创建完整计划（不写入 `user_weekly_plan`）
- ❌ 不生成活动实例
- ✅ 只返回 Coze AI 生成的原始学习材料数据

**适用场景**：
- 快速预览材料生成结果
- 测试 Coze 工作流输出
- 需要自定义后续处理的场景

## 接口信息

**端点**: `POST /gen-target-material`

**请求体**:
```json
{
  "user_id": "uuid",
  "inds": [1, 2, 3],
  "dur": 60,
  "acts": null
}
```

**参数说明**:
| 参数 | 类型 | 必填 | 默认值 | 说明 |
|-----|------|-----|--------|------|
| user_id | string | ✅ | - | 用户ID |
| inds | number[] | ✅ | - | 能力指标ID列表 |
| dur | number | ❌ | 60 | 目标学习时长（分钟） |
| acts | number[] | ❌ | null | 活动ID列表（仅用于活动分配测试） |

## 响应结构

```json
{
  "level": 3,
  "focusIndicators": [
    {
      "id": 1,
      "indicator": "字符识别",
      "weight": 0.4
    }
  ],
  "materialQuantities": {
    "character": 5,
    "word": 8,
    "sentence": 3,
    "chars_review": 10,
    "words_review": 5
  },
  "needReviews": {
    "chars_review": [
      {
        "item": "你",
        "item_type": "character",
        "score": 0.65
      }
    ],
    "words_review": [
      {
        "item": "你好",
        "item_type": "word",
        "score": 0.70
      }
    ]
  },
  "exists": ["mat_001", "mat_002"],
  "cozeOutput": {
    "character": [
      {
        "char": "学",
        "pinyin": "xué",
        "meaning": "to study; to learn",
        "hsk_level": 2,
        "topic_tag": "education",
        "culture_tag": null,
        "indicators": {
          "charsRecognition": 1.0,
          "pinyinRecognition": 0.8,
          "toneRecognition": 0.7,
          ...
        }
      }
    ],
    "word": [
      {
        "word": "学习",
        "pinyin": "xué xí",
        "meaning": "to study; to learn",
        "hsk_level": 2,
        "topic_tag": "education",
        "culture_tag": null,
        "indicators": {
          "wordRecognition": 1.0,
          "pinyinRecognition": 0.8,
          ...
        }
      }
    ],
    "sentence": [...],
    "dialog": [...],
    "paragraph": [...]
  },
  "allocationMap": {
    "character": [10, 11, 12],
    "word": [20, 21, 22],
    ...
  },
  "tidyMaterials": {
    "character": [...],
    "word": [...]
  },
  "totalStudyTime": 60
}
```

## 执行流程

### 1. 分析用户能力短板
```javascript
const { focusIndicators, currentLevel } = 
  await _getFocusIndicators(inds);
```

调用内部逻辑获取用户当前级别和需要重点提升的能力指标。

### 2. 计算材料数量分配
```javascript
const materialQuantities = _getMaterialQuantities(
  focusIndicators, 
  totalDuration
);
```

根据总时长和材料标准时长，计算各类型材料数量。

### 3. 查询需复习的材料
```javascript
const needReviews = await _getUserScoreRecord(
  user_id, 
  materialQuantities, 
  currentLevel
);
```

从 `user_score_records` 表查询得分 < 0.75 的材料作为复习内容。

### 4. 查询已学材料
```javascript
const exists = await _getExists(user_id, currentLevel);
```

避免 Coze 生成重复材料。

### 5. 调用 Coze 生成材料
```javascript
const cozeOutput = await _callCozeWorkflow({
  level: currentLevel,
  focusIndicators,
  materialQuantities,
  needReviews,
  exists
});
```

Coze 工作流返回完整的学习材料数据。

### 6. 分配活动模板（可选）
```javascript
const { allocationMap, tidyMaterials, totalStudyTime } = 
  await _get_allocate_activities({
    level,
    material: cozeOutput,
    indicators: focusIndicators,
    activityIds: acts,
    totalDuration
  });
```

如果提供了 `acts` 参数，会测试活动分配逻辑。

## Coze 工作流输入

```json
{
  "level": 3,
  "focusIndicators": ["字符识别", "词汇识别"],
  "materialQuantities": {
    "character": 5,
    "word": 8,
    "sentence": 3
  },
  "needReviews": {
    "chars_review": [{item: "你", score: 0.65}],
    "words_review": [{item: "你好", score: 0.70}]
  },
  "exists": ["已学材料ID1", "已学材料ID2"]
}
```

## Coze 工作流输出（期望格式）

### 汉字材料
```json
{
  "char": "学",
  "pinyin": "xué",
  "meaning": "to study; to learn",
  "hsk_level": 2,
  "topic_tag": "education",
  "culture_tag": null,
  "indicators": {
    "charsRecognition": 1.0,
    "charsWriting": 0.8,
    "pinyinRecognition": 0.8,
    "toneRecognition": 0.7,
    "tonePronunciation": 0.6,
    ...
  }
}
```

### 词汇材料
```json
{
  "word": "学习",
  "pinyin": "xué xí",
  "meaning": "to study; to learn",
  "hsk_level": 2,
  "topic_tag": "education",
  "culture_tag": null,
  "indicators": {
    "wordRecognition": 1.0,
    "wordWriting": 0.8,
    "pinyinRecognition": 0.8,
    ...
  }
}
```

### 句子材料
```json
{
  "sentence": "我在学习中文。",
  "pinyin": "wǒ zài xué xí zhōng wén。",
  "meaning": "I am studying Chinese.",
  "hsk_level": 3,
  "topic_tag": "education",
  "culture_tag": null,
  "indicators": {
    "sentenceRecognition": 1.0,
    "sentencePronunciation": 0.8,
    "grammarRecognition": 0.7,
    ...
  }
}
```

## 材料类型

| 类型 | 字段名 | 说明 |
|-----|--------|------|
| 汉字 | character | 单个汉字 + 拼音 + 释义 |
| 词汇 | word | 词语 + 拼音 + 释义 |
| 句子 | sentence | 完整句子 + 拼音 + 翻译 |
| 对话 | dialog | 多轮对话 |
| 段落 | paragraph | 文章段落 |
| 汉字复习 | chars_review | 需复习的汉字列表 |
| 词汇复习 | words_review | 需复习的词汇列表 |

## 15维能力指标

每个材料都包含 15 个能力指标的关联度（0-1）：

```typescript
indicators: {
  charsRecognition: 1.0,      // 字符识别
  charsWriting: 0.8,          // 字符书写
  wordRecognition: 0.9,       // 词汇识别
  wordWriting: 0.7,           // 词汇书写
  pinyinRecognition: 0.8,     // 拼音识别
  toneRecognition: 0.7,       // 声调识别
  tonePronunciation: 0.6,     // 声调发音
  sentenceRecognition: 0.5,   // 句子识别
  sentencePronunciation: 0.4, // 句子发音
  grammarRecognition: 0.3,    // 语法识别
  grammarApplication: 0.2,    // 语法应用
  listening: 0.6,             // 听力理解
  speaking: 0.5,              // 口语表达
  reading: 0.7,               // 阅读理解
  writing: 0.4                // 写作能力
}
```

## 与 create-plan 的区别

| 特性 | gen-target-material | create-plan |
|-----|---------------------|-------------|
| 生成材料 | ✅ | ✅ |
| 创建计划 | ❌ | ✅ |
| 生成活动实例 | ❌ | ✅ |
| 保存到数据库 | ❌ | ✅ |
| 流式响应 | ❌ | ✅ |
| 响应速度 | 快（5-10s） | 慢（10-15s） |
| 用途 | 测试/预览 | 正式创建计划 |

## 使用场景

### 1. 测试 Coze 工作流
```bash
curl -X POST \
  'https://xxx.supabase.co/functions/v1/gen-target-material' \
  -H "Authorization: Bearer YOUR_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "test_user",
    "inds": [1, 2, 3],
    "dur": 30
  }'
```

### 2. 预览材料生成结果
```dart
final result = await Supabase.instance.client.functions.invoke(
  'gen-target-material',
  body: {'user_id': userId, 'inds': [1, 2], 'dur': 30},
);

final materials = result.data['cozeOutput'];
// 展示给用户预览，用户确认后再调用 create-plan
```

### 3. 自定义后续处理
```dart
final materials = await getTargetMaterials(userId, inds, dur);

// 自己决定如何保存和分配活动
await customSaveMaterials(materials);
await customAllocateActivities(materials);
```

## 数据库依赖

### 只读表
- `research_core.indicators`
- `user_ability_history`
- `user_score_records`
- `learning_materials`
- `research_core.activities`（如果测试活动分配）

### 不写入任何表

## 性能指标

| 阶段 | 耗时 |
|-----|------|
| 能力分析 | ~1s |
| 查询复习材料 | ~0.5s |
| 查询已学材料 | ~0.5s |
| **Coze 生成** | **~5-10s** |
| 活动分配测试 | ~1s（可选） |
| **总耗时** | **~7-13s** |

## 错误处理

```json
{
  "error": "缺少参数: user_id, inds"
}
```

```json
{
  "error": "Coze workflow failed: timeout"
}
```

## 环境变量

```bash
SUPABASE_URL=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx
COZE_API_KEY=xxx
COZE_WORKFLOW_ID_MATERIAL=xxx
```

## 版本历史

- **v1.0** (2026-01-27): 从 create-plan 拆分出轻量级版本
