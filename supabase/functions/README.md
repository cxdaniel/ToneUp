# ToneUp 后端 API 总览

## 架构概述

ToneUp 使用 **Supabase Edge Functions** 作为 Serverless 后端，所有 API 均部署为独立的 Edge Function，提供高性能、低延迟的服务。

**技术栈**：
- **运行时**: Deno（TypeScript/JavaScript）
- **数据库**: PostgreSQL (Supabase)
- **存储**: Supabase Storage
- **AI集成**: 扣子(Coze) AI workflows
- **订阅**: RevenueCat webhooks
- **TTS**: 火山引擎 VolcTTS

## API 列表

| 接口名 | 功能 | 响应时间 | AI集成 |
|--------|------|---------|--------|
| [check_for_upgrade](#1-check_for_upgrade) | 升级建议检查 | ~1s | ❌ |
| [create-plan](#2-create-plan) | 学习计划生成（流式） | ~25-50s | ✅ Coze |
| [gen-target-material](#3-gen-target-material) | 轻量材料生成 | ~7-13s | ✅ Coze |
| [generate_evalute_exams](#4-generate_evalute_exams) | 测验题生成 | ~6-11s | ✅ Coze |
| [get_activity_instances](#5-get_activity_instances) | 活动实例获取 | ~0.2s / ~8s | ✅ Coze |
| [get-focus-indicators](#6-get-focus-indicators) | 能力短板分析 | ~1-2s | ❌ |
| [revenue-cat-webhook](#7-revenue-cat-webhook) | 订阅事件处理 | ~0.2s | ❌ |
| [translate-word](#8-translate-word) | 词典翻译 | ~0.1s / ~5-10s | ✅ Coze |
| [tts_proxy](#9-tts_proxy) | 语音合成代理 | ~0.1s / ~1-3s | ❌ |

## 接口详细说明

### 1. check_for_upgrade
**功能**：分析用户学习数据，判断是否建议升级到下一HSK级别  
**端点**：`POST /check_for_upgrade`  
**参数**：
```json
{
  "userId": "user_123",
  "currentLevel": 1
}
```
**响应**：
```json
{
  "canUpgrade": true,
  "reason": "你在 HSK1 级别的各项能力均达到升级标准...",
  "currentScore": 85
}
```
**文档**: [check_for_upgrade/README.md](check_for_upgrade/README.md)

---

### 2. create-plan
**功能**：基于用户能力分析生成个性化周学习计划（流式响应）  
**端点**：`POST /create-plan`  
**参数**：
```json
{
  "userId": "user_123",
  "hskLevel": 1,
  "targetLanguage": "en"
}
```
**响应**：Server-Sent Events (SSE) 流式数据
```
data: {"step":1,"message":"正在分析你的学习能力..."}
...
data: {"step":8,"content":{...完整计划数据...}}
```
**文档**: [create-plan/README.md](create-plan/README.md)

---

### 3. gen-target-material
**功能**：快速生成指定能力指标的测试材料  
**端点**：`POST /gen-target-material`  
**参数**：
```json
{
  "indicators": {"listening": 8, "speaking": 5},
  "materialType": "sentence",
  "hskLevel": 2,
  "targetLanguage": "en",
  "quantity": 5
}
```
**响应**：
```json
{
  "materials": [
    {
      "chinese_content": "...",
      "translation": "...",
      "pinyin": "...",
      "indicators": {...}
    }
  ]
}
```
**文档**: [gen-target-material/README.md](gen-target-material/README.md)

---

### 4. generate_evalute_exams
**功能**：为指定活动模板生成练习题  
**端点**：`POST /generate_evalute_exams`  
**参数**：
```json
{
  "activity_id": "act_123",
  "user_id": "user_123",
  "user_weekly_plan_id": "plan_456",
  "target_language": "en"
}
```
**响应**：
```json
{
  "quizzes": [
    {
      "quiz_type": "choice",
      "question": "...",
      "options": [...],
      "answer": "..."
    }
  ],
  "total_count": 4
}
```
**文档**: [generate_evalute_exams/README.md](generate_evalute_exams/README.md)

---

### 5. get_activity_instances
**功能**：获取活动实例的练习题，智能检测并自动生成  
**端点**：`POST /get_activity_instances`  
**参数**：
```json
{
  "activity_id": "act_123",
  "user_id": "user_123",
  "user_weekly_plan_id": "plan_456",
  "target_language": "en"
}
```
**响应**：
```json
{
  "quizzes": [...],
  "total_count": 4,
  "source": "database" // 或 "generated"
}
```
**文档**: [get_activity_instances/README.md](get_activity_instances/README.md)

---

### 6. get-focus-indicators
**功能**：分析用户15维能力指标，返回优先级排序的短板列表  
**端点**：`POST /get-focus-indicators`  
**参数**：
```json
{
  "userId": "user_123",
  "hskLevel": 2
}
```
**响应**：
```json
{
  "focusIndicators": [
    {
      "indicator": "listening",
      "currentScore": 45,
      "targetScore": 70,
      "priority": 95
    }
  ]
}
```
**文档**: [get-focus-indicators/README.md](get-focus-indicators/README.md)

---

### 7. revenue-cat-webhook
**功能**：接收 RevenueCat 订阅事件，同步到 Supabase 数据库  
**端点**：`POST /revenue-cat-webhook`  
**参数**：由 RevenueCat 自动发送
```json
{
  "type": "INITIAL_PURCHASE",
  "app_user_id": "user_123",
  "product_id": "toneup_monthly_sub",
  "expiration_at_ms": 1738022400000
}
```
**响应**：
```json
{
  "received": true
}
```
**文档**: [revenue-cat-webhook/README.md](revenue-cat-webhook/README.md)

---

### 8. translate-word
**功能**：多级缓存的词典翻译服务（L3缓存层）  
**端点**：`POST /translate-word`  
**参数**：
```json
{
  "word": "你好",
  "lang": "en"
}
```
**响应**：
```json
{
  "word": "你好",
  "translation": "Hello",
  "definition": "...",
  "examples": [...],
  "lang": "en"
}
```
**文档**: 参见 `docs/DICTIONARY_ARCHITECTURE_V2.md`

---

### 9. tts_proxy
**功能**：代理火山引擎TTS服务，提供智能音频缓存  
**端点**：`POST /tts_proxy`  
**参数**：
```json
{
  "request": {"text": "你好，欢迎学习中文！"},
  "audio": {"voice_type": "zh_female_qingxin"}
}
```
**响应**：`audio/mpeg` 二进制数据  
**文档**: [tts_proxy/README.md](tts_proxy/README.md)

---

## 数据流图

### 学习计划生成流程
```
客户端
  ↓
create-plan (Edge Function)
  ↓
get-focus-indicators (内部调用)
  ↓ 分析用户短板
Coze AI Workflow
  ↓ 生成个性化计划
Supabase 数据库
  ↓ 保存计划
客户端（流式接收进度）
```

### 练习题获取流程
```
客户端
  ↓
get_activity_instances
  ↓
查询数据库 (user_practice)
  ├─ 有数据 → 直接返回 (~0.2s)
  └─ 无数据 → generate_evalute_exams
                ↓
             Coze AI 生成题目 (~8s)
                ↓
             保存到数据库
                ↓
             返回给客户端
```

### 词典翻译流程（4级缓存）
```
SimpleDictionaryService (客户端)
  ↓
L1: LRU 内存缓存 (~1ms)
  ↓ miss
L2: SQLite 本地缓存 (~10-50ms)
  ↓ miss
L3: translate-word (Edge Function)
  ↓
  查询 Supabase 数据库 (~100ms)
    ↓ miss
  Coze AI 生成翻译 (~5-10s)
    ↓
  自动保存到数据库
    ↓
  返回给客户端
  ↓
L4: 拼音降级方案 (<10ms)
```

### 订阅同步流程
```
用户在 App 内购买
  ↓
RevenueCat SDK
  ↓
App Store / Google Play
  ↓
RevenueCat 后台
  ↓
revenue-cat-webhook (Edge Function)
  ↓
Supabase subscriptions 表
  ↓
客户端轮询/实时监听
  ↓
UI 更新为 Pro 状态
```

## Coze AI 集成

### 使用 Coze 的接口
| 接口 | Workflow 用途 |
|-----|---------------|
| create-plan | 生成个性化学习计划 |
| gen-target-material | 生成指定能力的学习材料 |
| generate_evalute_exams | 生成练习题 |
| translate-word | 词典翻译（替代百度API） |

### Coze API 调用模式
```typescript
const response = await fetch('https://api.coze.cn/v1/workflow/run', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${COZE_API_KEY}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    workflow_id: WORKFLOW_ID,
    parameters: { /* 根据不同workflow传参 */ }
  })
});
```

**优势**：
- ✅ 个性化内容生成
- ✅ 基于用户能力的智能推荐
- ✅ 降低人工内容制作成本

## 性能对比

| 场景 | 不使用缓存 | 使用缓存 | 提升 |
|-----|-----------|---------|------|
| 词典查询 | ~8s | ~100ms | **80x** |
| TTS 合成 | ~2s | ~100ms | **20x** |
| 练习题获取 | ~8s | ~0.2s | **40x** |

## 数据库依赖

| 接口 | 读取表 | 写入表 |
|-----|--------|--------|
| check_for_upgrade | user_practice, user_materials | - |
| create-plan | user_practice | user_weekly_plan, user_materials |
| generate_evalute_exams | activity_templates, user_materials | user_practice |
| get_activity_instances | user_practice, activity_templates | user_practice |
| get-focus-indicators | user_practice, user_materials | - |
| revenue-cat-webhook | - | subscriptions |
| translate-word | word_translations | word_translations |
| tts_proxy | - | storage.objects (tts_cache) |

## 环境变量

所有 Edge Functions 共享的环境变量：

```bash
# Supabase
SUPABASE_URL=https://kixonwnuivnjqlraydmz.supabase.co
SUPABASE_ANON_KEY=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx

# Coze AI
COZE_API_KEY=xxx
COZE_WORKFLOW_PLAN=xxx         # create-plan 使用
COZE_WORKFLOW_MATERIAL=xxx     # gen-target-material 使用
COZE_WORKFLOW_QUIZ=xxx         # generate_evalute_exams 使用
COZE_WORKFLOW_DICT=xxx         # translate-word 使用

# 火山引擎 TTS
VOLC_TOKEN=xxx
VOLC_APPID=xxx

# RevenueCat (可选，用于 webhook 验证)
REVENUECAT_WEBHOOK_SECRET=xxx
```

## 部署

### 本地测试
```bash
# 启动 Supabase 本地环境
supabase start

# 部署所有函数到本地
supabase functions serve

# 测试单个函数
curl -X POST \
  'http://localhost:54321/functions/v1/translate-word' \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -d '{"word":"你好","lang":"en"}'
```

### 生产部署
```bash
# 部署所有函数到生产环境
supabase functions deploy --project-ref kixonwnuivnjqlraydmz

# 部署单个函数
supabase functions deploy translate-word --project-ref kixonwnuivnjqlraydmz

# 查看日志
supabase functions logs translate-word --project-ref kixonwnuivnjqlraydmz
```

## 错误处理

所有接口遵循统一的错误响应格式：

```json
{
  "error": "Error message",
  "details": "Optional detailed error info"
}
```

**HTTP 状态码**：
- `200` - 成功
- `400` - 客户端请求错误（参数缺失/格式错误）
- `401` - 未授权（缺少 Authorization header）
- `404` - 资源不存在
- `500` - 服务器内部错误

## 客户端集成

### Dart/Flutter 调用示例

```dart
// 1. 词典翻译
final response = await Supabase.instance.client.functions.invoke(
  'translate-word',
  body: {'word': '你好', 'lang': 'en'},
);
final translation = response.data;

// 2. 生成学习计划（流式）
final stream = Supabase.instance.client.functions.invokeStream(
  'create-plan',
  body: {
    'userId': user.id,
    'hskLevel': 2,
    'targetLanguage': 'en',
  },
);

stream.listen((chunk) {
  final data = jsonDecode(chunk);
  print('进度: ${data['step']}/8');
});

// 3. 获取练习题
final response = await Supabase.instance.client.functions.invoke(
  'get_activity_instances',
  body: {
    'activity_id': activityId,
    'user_id': userId,
    'user_weekly_plan_id': planId,
    'target_language': 'en',
  },
);
final quizzes = response.data['quizzes'];

// 4. TTS 语音合成
final response = await Supabase.instance.client.functions.invoke(
  'tts_proxy',
  body: {
    'request': {'text': '你好世界'},
    'audio': {'voice_type': 'zh_female_qingxin'},
  },
);
final audioBytes = response.data as Uint8List;
await audioPlayer.playBytes(audioBytes);
```

## 监控与调试

### 查看实时日志
```bash
# 所有函数
supabase functions logs --tail

# 单个函数
supabase functions logs translate-word --tail

# 过滤错误
supabase functions logs | grep ERROR
```

### 性能监控
在 Supabase Dashboard 中查看：
- **Invocations**: 调用次数
- **Errors**: 错误率
- **Duration**: 平均响应时间
- **Bandwidth**: 带宽使用

### 成本优化建议
1. **启用缓存**：translate-word 和 tts_proxy 已实现，建议其他高频接口也实现
2. **批量操作**：避免在循环中逐个调用 Edge Function
3. **预加载**：提前生成常用内容（如每日计划的音频）
4. **定期清理**：删除过期的 TTS 缓存文件

## 相关文档

- [项目总览](../../docs/PROJECT_OVERVIEW.md)
- [词典架构 V2](../../docs/DICTIONARY_ARCHITECTURE_V2.md)
- [数据模型](../../docs/DATA_MODELS.md)
- [第三方认证](../../docs/THIRD_PARTY_AUTH.md)

## 版本历史

- **v1.0** (2026-01-27): 初始版本，包含9个 Edge Functions
  - 新增 Coze AI 集成（4个工作流）
  - 新增词典4级缓存架构
  - 新增 RevenueCat webhook 集成
  - 新增 TTS 智能缓存

---

**维护者**: ToneUp Team  
**最后更新**: 2026-01-27
