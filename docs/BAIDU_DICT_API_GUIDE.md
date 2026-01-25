# 百度词典版API集成指南

## 📋 概述

ToneUp App 现使用**百度翻译词典版API**作为L4词典数据源,提供丰富的词典数据(例句/近义词/音标/词性等)。

### 为什么选择百度词典版?

| 对比项 | 百度词典版 | 有道词典API | 优势 |
|--------|-----------|------------|------|
| **注册方式** | 自助开通 | 需商务洽谈 | ✅ 无需商务对接 |
| **中英词典** | ✅ 完整支持 | ✅ 完整支持 | 同等功能 |
| **日韩词典** | ❌ 不支持 | ✅ 支持 | 有道优势 |
| **其他语种** | ✅ 200+翻译 | ❌ 不支持 | ✅ 百度优势 |
| **定价** | 49元/百万字符 | TBD商务报价 | ✅ 透明定价 |
| **免费额度** | 1000万字符/月 | TBD | ✅ 适合初期 |
| **认证方式** | Access Token | SHA256签名 | 简化实现 |

### 核心特性

- **丰富词典数据**(仅中英互查):
  - 中文→英文: 拼音、词性、中文释义、英文释义、近义词
  - 英文→中文: 音标(美式/英式)、词性、英文释义、中文释义、例句、核心词汇标签(高考/CET4/考研)
- **TTS语音合成**: 返回`src_tts`/`dst_tts` MP3 URL
- **200+语种支持**: 非中英语种返回基础翻译(无词典数据)
- **自助开通**: 无需商务对接,注册即用

### 关键限制

⚠️ **词典数据仅支持**: `from=zh` ↔ `from=en` (中英互查)
⚠️ **其他语种**: 仅返回基础翻译,无词典字段
⚠️ **查询限制**: 仅支持单词/短语,不支持句子
⚠️ **TTS限制**: 最长200字符,仅单句

---

## 🚀 快速开始

### Step 1: 获取API密钥

1. **注册百度智能云账号**: https://login.bce.baidu.com/new-reg
2. **进入百度AI开放平台**: https://ai.baidu.com/
3. **创建应用**:
   - 访问控制台: https://console.bce.baidu.com/ai/#/ai/machinetranslation/overview/index
   - 点击"创建应用"
   - 填写应用名称: `ToneUp词典服务`
   - 接口选择: 勾选"机器翻译" → "文本翻译(含词典版)"
4. **获取密钥**:
   - 创建成功后在"应用列表"中查看
   - 复制 **API Key** 和 **Secret Key**

### Step 2: 配置密钥

编辑 `lib/services/baidu_dict_service.dart`:

```dart
class BaiduDictService {
  // API配置
  static const String _apiKey = 'YOUR_BAIDU_API_KEY';      // 替换为实际API Key
  static const String _secretKey = 'YOUR_BAIDU_SECRET_KEY'; // 替换为实际Secret Key
  // ...
}
```

### Step 3: 测试API

1. **运行调试页面**:
   ```bash
   flutter run -d "iPhone 15 Pro"
   ```

2. **进入调试页面**:
   - 导航栏: 个人资料 → API词典调试(开发环境可见)
   - 或直接访问路由: `/dictionary-debug`

3. **检查配置**:
   - L4显示: `✅ 百度词典版API: API已配置(仅支持中英互查)`
   - 如显示`⚠️ API未配置`,检查密钥是否正确替换

4. **执行测试**:
   - 默认测试词: "你好"
   - 点击"清空缓存后测试"按钮
   - 预期结果:
     ```
     ✅ API词典工作正常
     - 查询词语: 你好
     - 拼音: nǐ hǎo
     - 释义: hello
     - 词条数: ≥1
     - 查询耗时: ~1000-2000ms
     - API配置: ✅
     ```

---

## 📖 API详细说明

### 认证流程

百度词典版使用**Access Token认证**,有效期30天:

```
1. 请求Token: GET https://aip.baidubce.com/oauth/2.0/token
   参数: grant_type=client_credentials&client_id={API_KEY}&client_secret={SECRET_KEY}
   
2. 返回Token: {"access_token": "xxx", "expires_in": 2592000}

3. 调用API: POST https://aip.baidubce.com/rpc/2.0/mt/texttrans-with-dict/v1?access_token={TOKEN}
```

**Token缓存策略**:
- `BaiduDictService`自动缓存Token
- 有效期检查: 提前1小时刷新(避免过期)
- 清除缓存: `BaiduDictService().clearTokenCache()`

### 请求格式

**Endpoint**: `POST https://aip.baidubce.com/rpc/2.0/mt/texttrans-with-dict/v1`

**Headers**:
```
Content-Type: application/json;charset=utf-8
```

**Body** (JSON):
```json
{
  "from": "zh",      // 源语言: zh(中文) | en(英文)
  "to": "en",        // 目标语言: zh | en
  "q": "你好"        // 查询词语(单词/短语,非句子)
}
```

### 响应格式

#### 成功响应 (中英互查,含词典数据)

```json
{
  "result": {
    "from": "zh",
    "to": "en",
    "trans_result": [
      {
        "src": "你好",
        "dst": "hello",
        "dict": "{\"zdict\":{\"item\":[{\"pinyin\":\"nǐ hǎo\",\"tr_group\":[{\"tr\":[\"hello\"],\"example\":[\"你好，世界 hello world\"]}]}]},\"edict\":{\"item\":[{\"pos\":\"interjection\",\"tr_group\":[{\"tr\":[\"你好\"],\"example\":[\"Hello, how are you?\"]}]}]},\"simple_means\":{\"word_means\":[\"你好\",\"问好\"],\"symbols\":[{\"ph_am\":\"həˈloʊ\",\"ph_en\":\"həˈləʊ\"}]}}",
        "src_tts": "https://fanyi.baidu.com/gettts?lan=zh&text=你好&...",
        "dst_tts": "https://fanyi.baidu.com/gettts?lan=en&text=hello&..."
      }
    ]
  }
}
```

**dict字段结构** (二次JSON解析):

```json
{
  "zdict": {           // 中文词典 (from=zh时有效)
    "item": [{
      "pinyin": "nǐ hǎo",
      "tr_group": [{
        "tr": ["hello"],                        // 英文释义
        "example": ["你好，世界 hello world"]    // 例句
      }]
    }]
  },
  "edict": {           // 英文词典 (from=en时有效)
    "item": [{
      "pos": "interjection",                    // 词性
      "tr_group": [{
        "tr": ["你好"],                         // 中文释义
        "example": ["Hello, how are you?"],    // 例句
        "similar_word": ["hi", "hey"]          // 近义词
      }]
    }]
  },
  "simple_means": {    // 简明释义 (通用)
    "word_means": ["你好", "问好"],             // 基础释义
    "symbols": [{                              // 音标信息
      "ph_am": "həˈloʊ",                       // 美式音标
      "ph_en": "həˈləʊ"                        // 英式音标
    }],
    "tags": {
      "core": ["高考", "CET4", "考研"]         // 核心词汇标签
    },
    "exchange": {
      "word_pl": ["hellos"]                    // 词形变化
    }
  }
}
```

#### 失败响应

```json
{
  "error_code": 52003,
  "error_msg": "UNAUTHORIZED USER"
}
```

**常见错误码**:

| 错误码 | 说明 | 解决方案 |
|--------|------|---------|
| 52001 | 请求超时 | 重试 |
| 52002 | 系统错误 | 重试 |
| 52003 | 未授权用户 | 检查API Key/Secret Key |
| 54000 | 必填参数为空 | 检查from/to/q参数 |
| 54001 | 签名错误 | 检查Secret Key |
| 58000 | 客户端IP非法 | 检查IP白名单 |
| 90107 | 认证未通过 | 检查Access Token |

---

## 🏗️ 代码架构

### 文件结构

```
lib/services/
├── baidu_dict_service.dart          # 百度词典版API服务 (新建)
├── simple_dictionary_service.dart   # 五级词典查询 (已更新)
└── youdao_api_service.dart          # 有道API服务 (已废弃)

lib/pages/
└── dictionary_debug_page.dart       # API调试页面 (已更新)
```

### BaiduDictService API

```dart
class BaiduDictService {
  // 单例模式
  static final BaiduDictService _instance = BaiduDictService._internal();
  factory BaiduDictService() => _instance;
  
  // 主要方法
  Future<WordDetailModel?> translate({
    required String word,
    String from = 'zh',  // zh | en
    String to = 'en',    // zh | en
  });
  
  Future<Map<String, WordDetailModel?>> translateBatch(
    List<String> words, {
    String from = 'zh',
    String to = 'en',
  });
  
  // 工具方法
  bool get isConfigured;               // 检查API是否配置
  void clearTokenCache();              // 清除Token缓存
  Map<String, dynamic> getUsageStats(); // 获取使用统计
}
```

### 五级查询流程 (SimpleDictionaryService)

```
┌─────────────────────────────────────┐
│ getWordDetail(word: "你好", lang: "en") │
└────────────┬────────────────────────┘
             │
    ┌────────▼────────┐
    │ L1: LRU缓存检查  │ ─── 命中 ──→ 返回结果 (< 1ms)
    └────────┬────────┘
             │ 未命中
    ┌────────▼────────┐
    │ L2: SQLite检查  │ ─── 命中 ──→ 缓存到L1 → 返回 (~ 5ms)
    └────────┬────────┘
             │ 未命中
    ┌────────▼────────┐
    │ L3: Supabase检查│ ─── 命中 ──→ 缓存到L2+L1 → 返回 (~ 100ms)
    └────────┬────────┘
             │ 未命中
    ┌────────▼─────────┐
    │ L4: 百度词典版API │ ── 仅中英 ──→ 获取词典数据
    │  - zh↔en: 词典   │              缓存到L3+L2+L1 → 返回 (~ 1-2s)
    │  - 其他: 跳过    │
    └────────┬─────────┘
             │ 未命中或不支持
    ┌────────▼────────┐
    │ L5: 拼音兜底     │ ──→ 缓存到L1 → 返回 "(暂无释义)" (< 1ms)
    └─────────────────┘
```

**关键逻辑**:

```dart
// SimpleDictionaryService.getWordDetail()
if (_baiduDict.isConfigured && _isSupportedByBaiduDict(language)) {
  final apiWord = await _baiduDict.translate(
    word: word,
    from: 'zh',
    to: language,
  );
  // 补充拼音(如API未返回)
  // 保存到L3+L2+L1缓存
}

bool _isSupportedByBaiduDict(String language) {
  return language == 'en' || language == 'zh';  // 仅中英
}
```

---

## 🧪 测试指南

### 单元测试场景

```dart
// 测试1: 中文→英文 (完整词典数据)
final result = await BaiduDictService().translate(
  word: '你好',
  from: 'zh',
  to: 'en',
);
expect(result?.pinyin, 'nǐ hǎo');
expect(result?.summary, 'hello');
expect(result?.entries.isNotEmpty, true);

// 测试2: 英文→中文 (含音标/例句)
final result = await BaiduDictService().translate(
  word: 'hello',
  from: 'en',
  to: 'zh',
);
expect(result?.pinyin, contains('həˈloʊ')); // 音标
expect(result?.entries.any((e) => e.examples.isNotEmpty), true);

// 测试3: 非中英语种 (应返回null)
final result = await BaiduDictService().translate(
  word: 'こんにちは',
  from: 'ja',
  to: 'zh',
);
expect(result, null);  // 不支持,返回null

// 测试4: Token自动刷新
BaiduDictService().clearTokenCache();
final result1 = await BaiduDictService().translate(word: '学习', from: 'zh', to: 'en');
final result2 = await BaiduDictService().translate(word: '中国', from: 'zh', to: 'en');
// 第二次调用应使用缓存的Token (检查日志无二次Token请求)
```

### 集成测试 (调试页面)

1. **测试中英互查**:
   - 输入: "学习" → 预期: pinyin, 英文释义, 词条 > 0
   - 输入: "study" → 预期: 音标, 中文释义, 例句

2. **测试缓存效果**:
   - 首次查询 "你好" → 耗时 ~ 1500ms (L4 API)
   - 再次查询 "你好" → 耗时 < 10ms (L1缓存命中)
   - 清空缓存后查询 → 耗时恢复 ~ 1500ms

3. **测试语种限制**:
   - 中文→日语: 预期跳过L4,进入L5拼音兜底
   - 日志: `⚠️ 百度词典版仅支持中英互查,语种 ja 不支持,跳过L4`

---

## 💰 成本管理

### 定价模式

- **免费额度**: 1000万字符/月 (QPS=10)
- **付费**: 49元/百万字符
- **字符计算**: 按源语言文本字符数(包括标点/空格)

### 成本估算

**场景1: 1000 DAU,每用户查询10词/天**:
```
日查询量: 1000 × 10 = 10,000次
平均词长: 3字符
日消耗: 10,000 × 3 = 30,000字符 = 0.03M字符
月消耗: 0.03M × 30 = 0.9M字符
月成本: 免费额度内 (< 10M)
```

**场景2: 5000 DAU,每用户查询20词/天**:
```
月消耗: 5000 × 20 × 3 × 30 = 9M字符
月成本: 免费额度内
```

**场景3: 1万DAU,每用户查询30词/天**:
```
月消耗: 10,000 × 30 × 3 × 30 = 27M字符
月成本: (27 - 10) × 49 = 833元
```

### 优化策略

1. **三级缓存命中率优化**:
   - 目标: L1+L2+L3命中率 > 85%
   - 策略: 预热高频词(HSK1-4核心词汇)
   - 效果: API调用减少85%,成本降至原15%

2. **批量查询优化**:
   - 当前: 串行调用,100ms延迟限流
   - 优化: 合并短时间内多词查询 (暂未实现)
   - 效果: 减少API调用次数30%

3. **Supabase预填充**:
   - 策略: 离线爬取HSK1-6核心词汇 (9000词)
   - 工具: 使用百度API批量翻译 → 导入Supabase
   - 效果: 新用户L3命中率从0%提升至60%

---

## 🔄 与有道API对比

### 迁移检查清单

- [x] ~~`lib/services/youdao_api_service.dart`~~ → `baidu_dict_service.dart`
- [x] ~~`YoudaoApiService()`~~ → `BaiduDictService()`
- [x] ~~`_convertToYoudaoLang()`~~ → `_isSupportedByBaiduDict()`
- [x] ~~`from: 'zh-CHS'`~~ → `from: 'zh'`
- [x] ~~`to: _convertToYoudaoLang(language)`~~ → `to: language`
- [x] 调试页面显示文本更新
- [x] 文档更新 (`docs/BAIDU_DICT_API_GUIDE.md`)

### API差异

| 特性 | 有道文本翻译API | 百度词典版API |
|------|---------------|--------------|
| **认证** | SHA256签名(每次请求) | Access Token(30天缓存) |
| **请求** | POST `application/x-www-form-urlencoded` | POST `application/json` |
| **中英词典** | ❌ 2024.04.22下线 | ✅ 完整支持 |
| **日韩词典** | ❌ 需商务版 | ❌ 不支持 |
| **200+语种** | ✅ 基础翻译 | ✅ 基础翻译 |
| **词典数据** | 需单独API | 内置在响应中 |
| **音标** | ❌ | ✅ 美式/英式 |
| **例句** | ❌ | ✅ |
| **近义词** | ❌ | ✅ |
| **TTS** | ❌ | ✅ MP3 URL |

### 何时考虑有道商务版?

**选择有道** (需商务谈判):
- ✅ 需要日语/韩语词典数据
- ✅ 预算充足,追求最全语种覆盖
- ✅ 需要商务级SLA保障

**选择百度** (当前方案):
- ✅ 主要用户群为英语母语者学中文
- ✅ 其他语种仅需基础翻译
- ✅ 需要自助快速上线
- ✅ 成本敏感型项目

---

## 📚 参考资料

### 官方文档
- 百度翻译API总览: https://ai.baidu.com/tech/mt/text_trans
- 词典版技术文档: https://ai.baidu.com/ai-doc/MT/nkqrzmbpc
- 通用翻译技术文档: https://ai.baidu.com/ai-doc/MT/4kqryjku9
- 控制台: https://console.bce.baidu.com/ai/#/ai/machinetranslation/overview/index

### 代码位置
- API服务实现: `lib/services/baidu_dict_service.dart`
- 五级查询逻辑: `lib/services/simple_dictionary_service.dart`
- 调试界面: `lib/pages/dictionary_debug_page.dart`
- 使用指南: `docs/BAIDU_DICT_API_GUIDE.md`

### 相关决策
- 有道API评估: `docs/YOUDAO_API_GUIDE.md` (已废弃)
- 第三方认证: `docs/THIRD_PARTY_AUTH.md`
- 项目总览: `docs/PROJECT_OVERVIEW.md`

---

## ❓ 常见问题

### Q1: 为什么只支持中英互查?
**A**: 百度词典版API的`dict`字段仅在`from=zh`或`from=en`时返回。其他语种调用API会成功,但只返回`dst`翻译结果,无词典数据。如需日韩等语种词典,需考虑有道商务版或其他方案。

### Q2: Token过期怎么办?
**A**: `BaiduDictService`自动管理Token:
- 首次调用: 自动获取Token
- Token缓存: 存储在内存,有效期30天
- 自动刷新: 检测到过期时自动重新获取
- 手动清除: `BaiduDictService().clearTokenCache()`

### Q3: 如何处理API限流?
**A**: 百度API免费版QPS限制为10次/秒:
- `translateBatch()`方法已内置100ms延迟
- 如遇`58003`错误(访问频率受限),增加延迟或升级付费版

### Q4: API调用失败如何降级?
**A**: 五级查询自动降级:
1. L4失败 → 进入L5拼音兜底
2. 返回`WordDetailModel(pinyin: xxx, summary: '(暂无释义)')`
3. 用户仍可看到拼音,不会完全报错

### Q5: 能否离线使用?
**A**: 部分场景可离线:
- **有缓存词条**: L1/L2/L3缓存命中,无需API调用
- **新词查询**: 必须联网调用L4 API
- **建议**: 预热常用词到L3,提升离线可用性

### Q6: 如何调试API问题?
**A**: 三步排查:
1. **检查配置**: 调试页面查看`L4 百度词典版API`状态
2. **查看日志**: 搜索`✅`/`❌`标记的API日志
3. **手动测试**: 
   ```bash
   flutter logs | grep -i baidu
   ```
   调试页面输入"你好" → 点击"清空缓存后测试"

---

## 🔮 未来优化

### Phase 1: 当前实现 ✅
- [x] 百度词典版API集成
- [x] 中英互查支持
- [x] Access Token自动管理
- [x] 五级缓存架构
- [x] 调试工具页面

### Phase 2: 成本优化 (计划中)
- [ ] HSK核心词汇预热 (L3预填充9000词)
- [ ] 批量查询合并 (减少API调用30%)
- [ ] 缓存命中率监控 (目标85%+)

### Phase 3: 多语种增强 (待定)
- [ ] 评估百度通用翻译API (非词典版)
- [ ] 考虑混合方案: 百度(中英词典) + 其他(日韩词典)
- [ ] 或等有道商务版报价后决策

### Phase 4: 高级特性 (远期)
- [ ] TTS MP3播放 (利用API返回的`src_tts`/`dst_tts`)
- [ ] 核心词汇标签展示 (高考/CET4/考研)
- [ ] 词形变化显示 (复数/过去式等)
- [ ] 近义词推荐功能

---

**最后更新**: 2026年1月26日  
**版本**: v1.0.0  
**维护者**: ToneUp开发团队
