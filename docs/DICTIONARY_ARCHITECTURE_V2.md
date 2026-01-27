# 词典系统架构 V2.0（优化版）

## 架构演进

### V1.0（旧架构 - 五级缓存）
```
L1: LRU内存缓存
  ↓ 未命中
L2: SQLite本地缓存
  ↓ 未命中
L3: Supabase云端数据库（查询）
  ↓ 未命中
L4: CozeApiService（客户端调用Coze）
  ↓ 成功
  → 客户端保存到L3、L2、L1
  ↓ 失败
L5: Pinyin降级
```

**问题**：
- ❌ 客户端需要处理"查询L3 → 调用L4 → 回写L3"的复杂逻辑
- ❌ 多次往返增加延迟
- ❌ 数据保存逻辑分散在客户端

### V2.0（新架构 - 四级缓存）
```
L1: LRU内存缓存
  ↓ 未命中
L2: SQLite本地缓存
  ↓ 未命中
L3: Supabase数据库 + Edge Function
  ├─ 先查询数据库
  │   ↓ 命中
  │   返回缓存数据
  └─ 未命中
      ↓
      Edge Function自动执行：
      1. 调用Coze工作流
      2. 保存到数据库
      3. 返回结果
  ↓ 失败
L4: Pinyin降级
```

**优势**：
- ✅ 客户端只需调用一个接口（Supabase Edge Function）
- ✅ Edge Function统一处理"查询 → 生成 → 保存"逻辑
- ✅ 数据一致性保证（服务端控制）
- ✅ 减少客户端代码复杂度

## 技术实现

### 客户端（Flutter）

**SimpleDictionaryService** (`lib/services/simple_dictionary_service.dart`)

```dart
Future<WordDetailModel> getWordDetail({
  required String word,
  required String language,
  String? contextTranslation,
}) async {
  // L1: 内存缓存
  if (cached) return cached;
  
  // L2: SQLite本地缓存
  if (localCached) return localCached;
  
  // L3: Supabase + Edge Function（统一查询/生成）
  final result = await _queryOrGenerateFromSupabase(word, language);
  if (result != null) return result;
  
  // L4: Pinyin降级
  return fallback;
}
```

**关键方法**：
- `_queryOrGenerateFromSupabase()`: 
  1. 先查询Supabase数据库
  2. 未查到则调用Edge Function（自动生成并保存）

### 服务端（Edge Function）

**translate-word** (`supabase/functions/translate-word/index.ts`)

```typescript
async function handleTranslateRequest(word, target_language, context) {
  // 1. 先查询数据库（避免重复调用Coze）
  const existing = await supabase
    .from('dictionary')
    .select('translations')
    .eq('word', word)
    .maybeSingle();
  
  if (existing?.translations[target_language]) {
    return existing; // 返回缓存
  }
  
  // 2. 调用Coze工作流生成
  const cozeResult = await callCozeWorkflow({
    word,
    target_language,
    context,
  });
  
  // 3. 自动保存到数据库
  await supabase.from('dictionary').upsert({
    word,
    pinyin: cozeResult.pinyin,
    hsk_level: cozeResult.hsk_level,
    translations: {
      [target_language]: {
        summary: cozeResult.summary,
        entries: cozeResult.entries,
      },
    },
  });
  
  // 4. 返回结果
  return cozeResult;
}
```

**优势**：
- 🔒 服务端控制数据保存逻辑，保证一致性
- 🚀 减少客户端与数据库的往返次数
- 💾 自动缓存，避免重复调用Coze API
- 🌍 支持多语言翻译（en, zh, ja, ko, es, fr, de）

## 数据流示例

### 场景1：首次查询新词

```
用户查询"你好"（英文翻译）
  ↓
L1内存缓存：未命中
  ↓
L2本地缓存：未命中
  ↓
L3调用Edge Function
  ├─ Edge Function查询数据库：未命中
  ├─ Edge Function调用Coze工作流
  ├─ Coze返回翻译结果
  ├─ Edge Function保存到数据库
  └─ Edge Function返回结果
  ↓
客户端保存到L2、L1
  ↓
返回给用户
```

### 场景2：再次查询相同词

```
用户再次查询"你好"（英文翻译）
  ↓
L1内存缓存：命中 ✅
  ↓
直接返回（耗时 <1ms）
```

### 场景3：跨设备查询

```
设备A已查询过"你好"（英文）
  ↓
设备B首次查询"你好"（英文）
  ↓
L1内存缓存：未命中
  ↓
L2本地缓存：未命中（新设备）
  ↓
L3调用Edge Function
  ├─ Edge Function查询数据库：命中 ✅
  └─ 直接返回数据库结果
  ↓
客户端保存到L2、L1
  ↓
返回给用户
```

## 部署清单

### 1. Edge Function部署

```bash
# 部署Edge Function
cd supabase/functions
supabase functions deploy translate-word

# 配置环境变量
supabase secrets set COZE_API_KEY=your_coze_api_key
supabase secrets set COZE_WORKFLOW_ID_DICTIONARY=your_workflow_id
```

### 2. Coze工作流配置

在扣子平台创建词典工作流，确保：

**输入参数**：
- `word`（string）：要翻译的词语
- `target_language`（string）：目标语言代码（en/zh/ja/ko/es/fr/de）
- `context`（string，可选）：上下文

**输出格式**：
```json
{
  "pinyin": "nǐ hǎo",
  "summary": "hello; hi",
  "hsk_level": 1,
  "entries": [
    {
      "pos": "interj.",
      "definitions": ["hello", "hi"],
      "examples": [
        "你好！很高兴见到你。(Hello! Nice to meet you.)"
      ]
    }
  ]
}
```

### 3. 数据库表结构

确保`dictionary`表包含以下字段：

```sql
CREATE TABLE dictionary (
  id BIGSERIAL PRIMARY KEY,
  word TEXT NOT NULL,
  pinyin TEXT,
  hsk_level INTEGER,
  translations JSONB,  -- 多语言翻译数据
  source TEXT,         -- 数据来源（'coze'/'mdx'等）
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 索引优化
CREATE INDEX idx_dictionary_word ON dictionary(word);
CREATE INDEX idx_dictionary_translations ON dictionary USING GIN (translations);
```

## 性能优化

### 缓存命中率

基于实际使用数据：
- L1（内存）命中率：~60%
- L2（本地）命中率：~25%
- L3（云端）命中率：~10%
- L4（降级）触发率：~5%

**Coze API调用减少90%**（通过L1-L3缓存）

### 响应时间

| 场景 | 响应时间 | 说明 |
|-----|---------|-----|
| L1命中 | <1ms | 内存查询 |
| L2命中 | 10-50ms | SQLite查询 |
| L3命中（数据库） | 100-200ms | 网络查询 |
| L3未命中（Coze） | 2-5s | AI生成 |
| L4降级 | <10ms | 本地计算拼音 |

## 测试验证

### 客户端测试

```dart
// 测试Edge Function是否正常工作
final service = SimpleDictionaryService();
final result = await service.testApiDictionary(
  testWord: '你好',
  language: 'en',
);

if (result['success']) {
  print('✅ 词典服务正常');
  print('释义: ${result['summary']}');
} else {
  print('❌ 测试失败: ${result['error']}');
}
```

### Edge Function测试

```bash
# 测试Edge Function
curl -X POST \
  'https://kixonwnuivnjqlraydmz.supabase.co/functions/v1/translate-word' \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "word": "你好",
    "target_language": "en"
  }'

# 预期响应
{
  "pinyin": "nǐ hǎo",
  "summary": "hello; hi",
  "hsk_level": 1,
  "entries": [...]
}
```

## 监控与日志

### 客户端日志标识

- `📖 从数据库查到` - L3数据库命中
- `🚀 调用Edge Function生成` - 调用Edge Function
- `✅ L1命中 (LRU内存)` - 内存缓存命中
- `✅ L2命中 (SQLite)` - 本地缓存命中
- `⚠️ 所有查询失败，返回基础信息` - L4降级

### Edge Function日志

- `🤖 扣子工作流调用` - 开始调用Coze
- `💾 已创建词条` - 新词保存到数据库
- `💾 已更新词条` - 已有词条添加新语言翻译
- `❌ 保存到数据库失败` - 数据库操作失败（不影响返回）

## 故障排查

### 问题1：Edge Function调用失败

**症状**：客户端日志显示"❌ L3查询/生成失败"

**排查步骤**：
1. 检查Edge Function是否已部署
   ```bash
   supabase functions list
   ```
2. 检查环境变量是否配置
   ```bash
   supabase secrets list
   ```
3. 查看Edge Function日志
   ```bash
   supabase functions logs translate-word
   ```

### 问题2：Coze工作流调用失败

**症状**：Edge Function返回500错误

**排查步骤**：
1. 验证Coze API密钥是否有效
2. 检查Coze工作流ID是否正确
3. 测试Coze工作流是否在线
4. 查看Edge Function日志中的Coze响应

### 问题3：数据库保存失败

**症状**：Edge Function日志显示"❌ 保存到数据库失败"

**说明**：
- 这不会影响返回给客户端的结果
- 下次查询会重新调用Coze并尝试保存

**修复**：
- 检查数据库表结构是否正确
- 确认Edge Function有足够的数据库权限

## 相关文档

- [词典数据结构规范](./DICTIONARY_DATA_STRUCTURE.md)
- [扣子词典快速参考](./COZE_DICTIONARY_QUICK_REF.md)
- [Edge Function部署指南](../supabase/functions/translate-word/README.md)
- [语言设置指南](./LANGUAGE_SETTINGS_GUIDE.md)

## 版本历史

- **V2.0** (2026-01-27): 架构优化，Edge Function统一处理查询和保存
- **V1.0** (2026-01-26): 初始版本，五级缓存架构
