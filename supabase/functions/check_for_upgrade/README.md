# Check for Upgrade - 升级资格检查接口

## 功能说明

检查用户是否达到升级到下一级别的资格。通过分析用户在当前级别的核心能力指标练习情况，判断是否满足升级条件。

**核心逻辑**：
1. 查询当前级别的核心能力指标（weight ≥ 0.3）
2. 分析用户在有效期内（默认30天）的练习历史
3. 计算每个指标的平均得分和练习次数
4. 综合评估是否达到升级标准

## 接口信息

**端点**: `POST /check_for_upgrade`

**请求体**:
```json
{
  "user_id": "uuid",
  "level": 1,
  "validDays": 60
}
```

**参数说明**:
| 参数 | 类型 | 必填 | 默认值 | 说明 |
|-----|------|-----|--------|------|
| user_id | string | ✅ | - | 用户ID |
| level | number | ✅ | - | 当前级别（1-9） |
| validDays | number | ❌ | 60 | 有效练习天数 |

## 配置参数

```typescript
CONFIG = {
  validDays: 30,                     // 有效练习天数（可由请求覆盖）
  coreWeightThreshold: 0.3,          // 核心指标权重阈值
  indicatorQualifiedThreshold: 0.75, // 单指标合格阈值（75分）
  upgradeQualifiedThreshold: 0.75    // 升级合格阈值（75分）
}
```

## 升级判定逻辑

### 1. 核心指标筛选
- 查询当前级别所有 `weight >= 0.3` 的指标
- 这些指标代表该级别最重要的能力维度

### 2. 单指标达标条件
指标需**同时满足**两个条件才算达标：
- ✅ **平均得分 ≥ 0.75**（75分）
- ✅ **练习次数 ≥ minimum**（指标要求的最小练习次数）

```typescript
const isQualified = 
  avgScore >= 0.75 && 
  practiceCount >= indicator.minimum;
```

### 3. 加权总得分计算
- 只计入**已达标指标**的得分
- 未达标指标按 0 分计算

```typescript
weightedTotalScore = 
  Σ(达标指标得分 × 权重) / Σ(所有指标权重)
```

### 4. 升级资格判定
用户满足升级条件需达到：
- 🎯 **加权总得分 ≥ 0.75**

## 响应结构

```json
{
  "userId": "uuid",
  "currentLevel": 1,
  "canUpgrade": true,
  "weightedTotalScore": 0.82,
  "coreIndicatorCoverage": 85,
  "qualifiedIndicatorsCount": 7,
  "totalCoreIndicators": 8,
  "coreIndicatorDetails": [
    {
      "indicatorId": 123,
      "indicatorName": "字符识别",
      "indicatorWeight": 0.4,
      "minimum": 10,
      "practiceCount": 15,
      "avgScore": 0.85,
      "isQualified": true,
      "practiceGap": 0
    },
    {
      "indicatorId": 124,
      "indicatorName": "词汇识别",
      "indicatorWeight": 0.3,
      "minimum": 20,
      "practiceCount": 12,
      "avgScore": 0.90,
      "isQualified": false,
      "practiceGap": 8
    }
  ],
  "validDays": 60,
  "config": {
    "validDays": 60,
    "coreWeightThreshold": 0.3,
    "indicatorQualifiedThreshold": 0.75,
    "upgradeQualifiedThreshold": 0.75
  }
}
```

## 响应字段说明

### 顶层字段
| 字段 | 类型 | 说明 |
|-----|------|------|
| userId | string | 用户ID |
| currentLevel | number | 当前级别 |
| canUpgrade | boolean | **是否可升级**（关键字段） |
| weightedTotalScore | number | 加权总得分（0-1） |
| coreIndicatorCoverage | number | 核心指标覆盖率（%） |
| qualifiedIndicatorsCount | number | 达标指标数量 |
| totalCoreIndicators | number | 核心指标总数 |
| validDays | number | 有效天数 |

### 指标详情（coreIndicatorDetails）
| 字段 | 类型 | 说明 |
|-----|------|------|
| indicatorId | number | 指标ID |
| indicatorName | string | 指标名称 |
| indicatorWeight | number | 指标权重 |
| minimum | number | 要求的最小练习次数 |
| practiceCount | number | 实际练习次数 |
| avgScore | number | 平均得分（0-1） |
| isQualified | boolean | **是否达标** |
| practiceGap | number | 练习次数差距 |

## 使用场景

### 1. 升级提示
```dart
final result = await Supabase.instance.client.functions.invoke(
  'check_for_upgrade',
  body: {
    'user_id': userId,
    'level': currentLevel,
    'validDays': 30,
  },
);

if (result.data['canUpgrade']) {
  showUpgradeDialog(); // 提示用户可升级
}
```

### 2. 学习进度分析
```dart
final details = result.data['coreIndicatorDetails'];
final notQualified = details
  .where((ind) => !ind['isQualified'])
  .toList();

// 显示未达标指标和差距
notQualified.forEach((ind) {
  print('${ind['indicatorName']}: 还需练习 ${ind['practiceGap']} 次');
});
```

### 3. 进度条展示
```dart
final progress = result.data['weightedTotalScore'];
final coverage = result.data['coreIndicatorCoverage'];

// 显示升级进度
LinearProgressIndicator(value: progress); // 82%
```

## 数据库依赖

### 表
- `research_core.indicators` - 能力指标定义
- `user_ability_history` - 用户能力历史记录

### 关键字段
- `indicators.minimum` - 指标要求的最小练习次数（新增）
- `indicators.weight` - 指标权重
- `user_ability_history.score` - 练习得分

## 错误处理

### 参数错误（400）
```json
{
  "error": "无效参数：user_id 为必填项，level 需为 1-9"
}
```

### 数据不存在（404）
```json
{
  "error": "未找到级别 1 的核心指标"
}
```

## 性能优化建议

1. **缓存策略**: 结果可缓存1小时，避免频繁查询
2. **批量查询**: 一次性获取所有指标数据，减少数据库往返
3. **索引优化**: 
   - `user_ability_history(user_id, indicator_id, created_at)`
   - `indicators(level, weight)`

## 调用示例

### cURL
```bash
curl -X POST \
  'https://kixonwnuivnjqlraydmz.supabase.co/functions/v1/check_for_upgrade' \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "user_id": "123e4567-e89b-12d3-a456-426614174000",
    "level": 3,
    "validDays": 30
  }'
```

### Dart/Flutter
```dart
final response = await Supabase.instance.client.functions.invoke(
  'check_for_upgrade',
  body: {
    'user_id': userId,
    'level': 3,
    'validDays': 30,
  },
);

final canUpgrade = response.data['canUpgrade'];
final score = response.data['weightedTotalScore'];
```

## 版本历史

- **v2.0** (2026-01-27): 增加 minimum 字段，优化达标判定逻辑
- **v1.0** (2026-01-20): 初始版本，基础升级检查
