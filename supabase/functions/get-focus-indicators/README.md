# Get Focus Indicators - 获取用户能力短板接口

## 功能说明

分析用户的能力历史数据，找出最需要提升的核心指标（能力短板）。用于智能推荐学习重点。

**核心算法**：
1. 调用 `check_for_upgrade` 获取用户所有核心指标的达成情况
2. 计算每个指标的优先级得分
3. 返回优先级最高的 N 个指标

## 接口信息

**端点**: `POST /get-focus-indicators`

**请求体**:
```json
{
  "user_id": "uuid",
  "level": 3
}
```

**参数说明**:
| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| user_id | string | ✅ | 用户ID |
| level | number | ✅ | 当前级别（1-9） |

## 响应结构

```json
[
  {
    "indicatorId": 2,
    "indicatorName": "词汇识别",
    "indicatorWeight": 0.35,
    "minimum": 20,
    "practiceCount": 8,
    "practiceGap": 12,
    "avgScore": 0.65,
    "isQualified": false,
    "priorityScore": 0.92,
    "importanceScore": 0.35,
    "gapRatio": 0.60,
    "insufficientScore": 0.60
  },
  {
    "indicatorId": 1,
    "indicatorName": "字符识别",
    "indicatorWeight": 0.40,
    "minimum": 15,
    "practiceCount": 10,
    "practiceGap": 5,
    "avgScore": 0.70,
    "isQualified": false,
    "priorityScore": 0.85,
    "importanceScore": 0.40,
    "gapRatio": 0.33,
    "insufficientScore": 0.33
  },
  {
    "indicatorId": 5,
    "indicatorName": "听力理解",
    "indicatorWeight": 0.25,
    "minimum": 10,
    "practiceCount": 4,
    "practiceGap": 6,
    "avgScore": 0.60,
    "isQualified": false,
    "priorityScore": 0.78,
    "importanceScore": 0.25,
    "gapRatio": 0.60,
    "insufficientScore": 0.40
  }
]
```

## 优先级计算算法

### 公式
```typescript
priorityScore = 
  (importanceScore × 0.4) +     // 业务权重占比40%
  (gapRatio × 0.3) +            // 达标差距占比30%
  (insufficientScore × 0.3);    // 完成度不足占比30%
```

### 各维度说明

#### 1. importanceScore（业务重要性）
```typescript
importanceScore = indicatorWeight;
```
- 直接使用指标的业务权重（0-1）
- 权重越大，说明该指标越重要

#### 2. gapRatio（达标差距比例）
```typescript
gapRatio = practiceGap / (minimum + practiceGap);
```
- 表示离达标要求还有多远
- 值越大，说明差距越大，越需要优先练习

**示例**：
- minimum = 20，practiceCount = 8
- practiceGap = 12
- gapRatio = 12 / (20 + 12) = 0.375

#### 3. insufficientScore（完成度不足）
```typescript
completionRate = practiceCount / minimum;
insufficientScore = 1 - completionRate;
```
- 表示当前完成度相对要求的不足程度
- 值越大，说明完成度越低

**示例**：
- minimum = 20，practiceCount = 8
- completionRate = 8 / 20 = 0.4
- insufficientScore = 1 - 0.4 = 0.6

### 权重配置
```typescript
const weights = {
  importance: 0.4,    // 业务权重占比40%
  gap: 0.3,          // 差距占比30%
  insufficient: 0.3   // 不足占比30%
};
```

可以根据实际需求调整权重配置。

## 目标指标数量（按级别）

```typescript
const levelTargetMap = {
  1: 3,  // HSK 1级：返回3个短板
  2: 3,
  3: 3,
  4: 4,  // HSK 4级：返回4个短板
  5: 4,
  6: 4,
  7: 4,
  8: 4,
  9: 4
};
```

## 执行流程

### 1. 调用升级检查接口
```javascript
const { data } = await supabase.functions.invoke(
  'check_for_upgrade',
  {
    body: {
      user_id: user_id,
      level: level,
      validDays: 100
    }
  }
);
```

获取用户所有核心指标的详细数据：
- practiceCount（练习次数）
- avgScore（平均得分）
- minimum（要求次数）
- isQualified（是否达标）

### 2. 计算优先级得分
```javascript
const indicatorsWithScore = indicators.map(indicator => {
  const importanceScore = indicator.indicatorWeight;
  const gapRatio = indicator.practiceGap / 
    (indicator.minimum + indicator.practiceGap);
  const completionRate = indicator.practiceCount / 
    indicator.minimum;
  const insufficientScore = 1 - completionRate;
  
  const priorityScore = 
    (importanceScore × 0.4) +
    (gapRatio × 0.3) +
    (insufficientScore × 0.3);
  
  return { ...indicator, priorityScore };
});
```

### 3. 排序并返回Top N
```javascript
const focusIndicators = indicatorsWithScore
  .sort((a, b) => b.priorityScore - a.priorityScore)
  .slice(0, levelTargetMap[level]);
```

## 使用场景

### 1. 生成学习计划前
```dart
final focusIndicators = await Supabase.instance.client.functions.invoke(
  'get-focus-indicators',
  body: {
    'user_id': userId,
    'level': currentLevel,
  },
);

// 基于短板指标生成针对性计划
final indicatorIds = focusIndicators.data
  .map((ind) => ind['indicatorId'])
  .toList();

await generatePlan(userId, indicatorIds);
```

### 2. 学习进度分析
```dart
final shortcomings = await getFocusIndicators(userId, level);

// 显示用户的能力短板
shortcomings.forEach((ind) {
  print('${ind['indicatorName']}: 优先级 ${ind['priorityScore']}');
  print('  还需练习 ${ind['practiceGap']} 次');
  print('  当前得分 ${ind['avgScore']}');
});
```

### 3. 智能推荐练习
```dart
final topIndicators = await getFocusIndicators(userId, level);

// 推荐练习材料
final materials = await getMaterialsByIndicators(
  topIndicators.map((ind) => ind['indicatorId'])
);

showRecommendedPractice(materials);
```

## 优先级得分解读

| 得分范围 | 优先级 | 说明 |
|---------|-------|------|
| 0.9-1.0 | 极高 | 严重短板，急需提升 |
| 0.7-0.9 | 高 | 明显不足，优先练习 |
| 0.5-0.7 | 中 | 有待提升 |
| 0.3-0.5 | 低 | 基本达标，可适当练习 |
| 0.0-0.3 | 极低 | 已达标，无需重点关注 |

## 示例分析

### 用户A（HSK 3级）
```json
// 原始数据
{
  "词汇识别": {
    "weight": 0.35,
    "minimum": 20,
    "practiceCount": 8,
    "avgScore": 0.65
  }
}

// 计算过程
importanceScore = 0.35
gapRatio = 12 / 32 = 0.375
insufficientScore = 1 - (8/20) = 0.6

priorityScore = 
  0.35 × 0.4 + 
  0.375 × 0.3 + 
  0.6 × 0.3 
  = 0.14 + 0.1125 + 0.18 
  = 0.4325
```

### 用户B（HSK 3级）
```json
// 原始数据
{
  "字符识别": {
    "weight": 0.40,
    "minimum": 15,
    "practiceCount": 14,
    "avgScore": 0.78
  }
}

// 计算过程
importanceScore = 0.40
gapRatio = 1 / 16 = 0.0625
insufficientScore = 1 - (14/15) = 0.067

priorityScore = 
  0.40 × 0.4 + 
  0.0625 × 0.3 + 
  0.067 × 0.3 
  = 0.16 + 0.01875 + 0.02 
  = 0.199
```

用户A的"词汇识别"优先级（0.43）> 用户B的"字符识别"优先级（0.20），说明用户A更需要优先练习词汇。

## 数据库依赖

### 间接依赖（通过 check_for_upgrade）
- `research_core.indicators`
- `user_ability_history`

### 无写入操作

## 性能指标

| 阶段 | 耗时 |
|-----|------|
| 调用 check_for_upgrade | ~1-2s |
| 计算优先级得分 | ~0.01s |
| 排序和筛选 | ~0.01s |
| **总耗时** | **~1-2s** |

## 错误处理

```json
{
  "error": "缺少参数：user_id"
}
```

```json
{
  "error": "check_for_upgrade error: user not found"
}
```

## cURL 示例

```bash
curl -X POST \
  'https://xxx.supabase.co/functions/v1/get-focus-indicators' \
  -H "Authorization: Bearer YOUR_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "123e4567-e89b-12d3-a456-426614174000",
    "level": 3
  }'
```

## 环境变量

```bash
SUPABASE_URL=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx
```

## 与其他接口的配合

```
check_for_upgrade → get-focus-indicators → create-plan
      ↓                     ↓                    ↓
  获取所有指标         计算优先级           生成针对性计划
```

## 版本历史

- **v1.0** (2026-01-27): 初始版本，基于加权优先级算法
