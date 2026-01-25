# ToneUp 词典系统维护指南

## 📚 架构概览

ToneUp 采用**混合词典架构**，针对不同语言使用最优方案：

```
查询流程：
├─ 英文用户 (70-80%)
│   L1 内存缓存 → L2 SQLite → L3 Supabase (CC-CEDICT 60,000+词)
│   └─ L3.5 本地CC-CEDICT → L4 DeepL API → 拼音降级
│
└─ 其他语言 (ja, ko, es, fr, de等)
    L1 内存缓存 → L2 SQLite → L3 Supabase (API缓存结果)
    └─ L4 DeepL API → L5 MyMemory API → 拼音降级
```

**设计理念**：
- **英文**：使用专业CC-CEDICT词典（免费、高质量、含词性/例句）
- **其他语言**：使用DeepL翻译API（质量最高，500k字符/月免费）
- **逐步积累**：所有API结果缓存到Supabase，形成多语言词库

---

## 🔑 API密钥配置

### 1. DeepL API (推荐)

**获取密钥**：
1. 注册: https://www.deepl.com/pro-api
2. 选择 **DeepL API Free** 计划（500,000字符/月免费）
3. 复制API密钥

**配置位置**：
```dart
// lib/services/dictionary_api_service.dart
static const String _deepLApiKey = 'YOUR_DEEPL_API_KEY'; 
// 替换为: 'your-actual-api-key-f39f59b5-9c0b-4f29-8e3a-4d3b2a1c0e8f:fx'
```

**免费额度**：
- 500,000 字符/月
- 约等于 16,000 次词语查询
- 重置周期：每月1号

**付费升级**（可选）：
- DeepL API Pro: €5.99/月，无限量
- 适用于用户量超过1000+的场景

### 2. MyMemory API (降级备选)

**优点**：
- 完全免费，无需注册
- 14,000 次/天

**缺点**：
- 翻译质量低于DeepL
- 仅作为降级方案

**配置**：无需配置，已内置

---

## 📥 CC-CEDICT 词典导入

### 方式1: 自动脚本导入（推荐）

**前置条件**：
```bash
# 安装 Python 依赖
pip install requests python-dotenv supabase
```

**配置环境变量**：
创建 `.env` 文件（项目根目录）：
```bash
SUPABASE_URL=https://kixonwnuivnjqlraydmz.supabase.co
SUPABASE_SERVICE_KEY=your_service_role_key_here
```

**获取 Service Role Key**：
1. 打开 Supabase 项目: https://supabase.com/dashboard/project/kixonwnuivnjqlraydmz
2. Settings → API → `service_role` key
3. ⚠️ **警告**：此密钥绕过RLS，仅在服务器端使用，不要提交到Git

**运行导入**：
```bash
cd /Users/daniel/WorkSpaces/toneup/toneup_app
python scripts/import_cedict.py
```

**预期结果**：
```
📥 下载 CC-CEDICT 数据...
✅ 下载完成，文件大小: 12345678 字节
🚀 开始导入词条...
✅ 已导入 100 个词条...
✅ 已导入 200 个词条...
...
🎉 导入完成! 共导入 60,000+ 个词条
```

### 方式2: 手动导入（备选）

1. **下载 CC-CEDICT**:
   ```bash
   wget https://www.mdbg.net/chinese/export/cedict/cedict_1_0_ts_utf-8_mdbg.txt.gz
   gunzip cedict_1_0_ts_utf-8_mdbg.txt.gz
   ```

2. **使用在线工具转换**：
   - CSV工具: https://cc-cedict.org/editor/editor.php
   - 导出为CSV格式

3. **导入到Supabase**：
   - Supabase Dashboard → Table Editor → dictionary
   - Import CSV
   - 映射字段: word, pinyin, translations (JSON格式)

---

## 🗄️ 数据库结构说明

### dictionary 表

```sql
CREATE TABLE dictionary (
  id BIGSERIAL PRIMARY KEY,
  word TEXT UNIQUE NOT NULL,        -- 汉字词语（简体）
  pinyin TEXT NOT NULL,              -- 拼音 (e.g. "ni3 hao3")
  hsk_level INTEGER,                 -- HSK等级 (1-6, 可选)
  translations JSONB NOT NULL,       -- 多语言翻译数据
  frequency INTEGER DEFAULT 0,       -- 查询频率（自动更新）
  source TEXT,                       -- 数据来源 (cc-cedict/api/manual)
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### translations JSONB 结构

**标准格式**（CC-CEDICT导入）：
```json
{
  "en": {
    "summary": "hello; hi",
    "entries": [
      {
        "pos": "n./v.",
        "definitions": [
          "hello",
          "hi",
          "how are you?"
        ],
        "examples": []
      }
    ]
  }
}
```

**API缓存格式**（DeepL/MyMemory）：
```json
{
  "ja": {
    "summary": "こんにちは",
    "entries": [
      {
        "pos": "n./v.",
        "definitions": ["こんにちは"],
        "examples": []
      }
    ]
  }
}
```

**混合格式**（支持多语言）：
```json
{
  "en": {
    "summary": "welcome",
    "entries": [...]
  },
  "ja": {
    "summary": "歓迎する",
    "entries": [...]
  },
  "ko": {
    "summary": "환영하다",
    "entries": [...]
  }
}
```

---

## 🔄 日常维护任务

### 1. 监控API使用量

**DeepL配额查询**：
```bash
curl -X GET "https://api-free.deepl.com/v2/usage" \
  -H "Authorization: DeepL-Auth-Key YOUR_API_KEY"
```

**返回示例**：
```json
{
  "character_count": 180000,
  "character_limit": 500000
}
```

**在App中查看**：
```dart
// 调用 DictionaryApiService.checkApiAvailability()
// 查看日志输出: "✅ DeepL可用: 180000 / 500000 字符已使用"
```

### 2. 手动添加高质量词条

**场景**：用户反馈某个词翻译质量差

**步骤**：
1. 打开 Supabase Dashboard → Table Editor → dictionary
2. 点击 Insert Row
3. 填写字段：
   ```json
   word: "飞角"
   pinyin: "fei1 jiao3"
   hsk_level: null
   source: "manual"
   translations: {
     "en": {
       "summary": "flying eave (architectural term)",
       "entries": [{
         "pos": "n.",
         "definitions": [
           "upturned eave (traditional Chinese architecture)",
           "corner of a roof that curves upward"
         ],
         "examples": [
           "故宫的飞角非常有特色 The flying eaves of the Forbidden City are very distinctive"
         ]
       }]
     }
   }
   ```
4. Save

**批量编辑**：
使用Supabase SQL Editor执行UPDATE语句：
```sql
UPDATE dictionary
SET translations = jsonb_set(
  translations,
  '{en,entries,0,examples}',
  '["Example sentence here"]'::jsonb
)
WHERE word = '欢迎';
```

### 3. 清理低质量API缓存

**查询低频词条**（访问次数<2的API缓存）：
```sql
SELECT word, frequency, source, created_at
FROM dictionary
WHERE source = 'api' AND frequency < 2
ORDER BY created_at DESC
LIMIT 100;
```

**删除（可选）**：
```sql
DELETE FROM dictionary
WHERE source = 'api' 
  AND frequency < 2 
  AND created_at < NOW() - INTERVAL '30 days';
```

### 4. 更新CC-CEDICT词库

CC-CEDICT会定期更新，建议每季度同步一次：

```bash
# 1. 重新下载最新数据
python scripts/import_cedict.py

# 2. 脚本会自动upsert（已存在的词条会更新）
```

**增量更新**（仅更新新词）：
修改脚本 `import_cedict.py`，将 `upsert` 改为 `insert`（跳过已存在词条）。

---

## 📊 性能优化建议

### 1. 数据库索引优化

确保以下索引已创建（见migration文件）：
```sql
-- 词语查询索引
CREATE INDEX idx_dict_word ON dictionary(word);

-- HSK等级筛选
CREATE INDEX idx_dict_hsk ON dictionary(hsk_level);

-- 频率排序
CREATE INDEX idx_dict_freq ON dictionary(frequency DESC);

-- JSONB全文搜索（可选）
CREATE INDEX idx_dict_translations ON dictionary USING GIN(translations);
```

### 2. 缓存清理策略

**SQLite缓存**（自动LRU）：
- 保留最常访问的500个词
- 定期运行: `DictionaryCacheService.cleanOldCache()`

**Supabase定期清理低频API缓存**：
```sql
-- 每月清理一次30天内访问少于2次的API缓存
DELETE FROM dictionary
WHERE source = 'api' 
  AND frequency < 2 
  AND created_at < NOW() - INTERVAL '30 days';
```

### 3. 批量预加载高频词

**识别高频词**：
```sql
SELECT word, frequency, translations->'en'->>'summary' as english
FROM dictionary
WHERE frequency > 10
ORDER BY frequency DESC
LIMIT 100;
```

**优化策略**：
- 将高频词的其他语言翻译预先生成（调用DeepL API批量翻译）
- 存储到Supabase，减少实时API调用

---

## 🐛 故障排查

### 问题1: DeepL API返回403
**原因**: API密钥无效或过期

**解决**:
1. 检查密钥是否正确复制（包含`:fx`后缀）
2. 验证账户状态: https://www.deepl.com/account/usage
3. 确认使用了Free API端点（`api-free.deepl.com`而非`api.deepl.com`）

### 问题2: DeepL配额用尽(456错误)
**临时方案**: 自动降级到MyMemory API（已内置）

**长期方案**:
- 升级到DeepL Pro（€5.99/月无限量）
- 或减少API调用（更多依赖缓存）

### 问题3: 英文词条显示空白
**原因**: CC-CEDICT未导入或导入失败

**排查**:
```sql
SELECT COUNT(*) FROM dictionary WHERE source = 'cc-cedict';
-- 应该返回 60,000+ 行
```

**修复**: 重新运行导入脚本

### 问题4: 某些词总是返回拼音
**原因**: 所有查询级别都未命中

**排查步骤**:
1. 查看日志: `flutter logs | grep 词语`
2. 检查Supabase是否有该词: `SELECT * FROM dictionary WHERE word = '词语'`
3. 手动触发API查询（删除缓存）
4. 如果API也失败，考虑手动添加词条

---

## 🚀 未来扩展

### 1. 添加更多语言词典

**日语**: JMdict (https://www.edrdg.org/jmdict/j_jmdict.html)
- 170,000+ 中日词条
- 包含假名、汉字、例句

**德语**: HanDeDict (https://handedict.zydeo.net/)
- 30,000+ 中德词条

**导入方式**: 修改 `import_cedict.py`，支持不同数据格式

### 2. AI增强释义

使用GPT-4批量生成高质量例句：
```python
# 伪代码
for word in high_frequency_words:
    examples = openai.chat.completions.create(
        model="gpt-4",
        messages=[{
            "role": "user",
            "content": f"为中文词语'{word}'生成3个地道的英文例句"
        }]
    )
    update_dictionary(word, examples)
```

### 3. 用户贡献词条

允许用户提交更好的翻译：
- 添加 `user_contributions` 表
- 审核机制
- 自动合并到主词库

---

## 📞 技术支持

**CC-CEDICT相关**:
- 官网: https://cc-cedict.org
- GitHub: https://github.com/skishore/makemeahanzi
- 许可证: CC BY-SA 4.0

**DeepL API**:
- 文档: https://www.deepl.com/docs-api
- 支持: support@deepl.com

**项目维护者**: 
- 查看词典代码: `lib/services/simple_dictionary_service.dart`
- API服务: `lib/services/dictionary_api_service.dart`
- 数据库Schema: `supabase/migrations/20260118_dictionary_and_profile.sql`
