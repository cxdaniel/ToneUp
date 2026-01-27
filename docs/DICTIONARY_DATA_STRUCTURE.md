# 词典数据结构规范

## 概述
本文档定义了ToneUp App词典系统的标准数据格式，用于：
1. 扣子工作流的API返回格式
2. Supabase数据库存储格式
3. Flutter应用内部数据模型

## 核心数据模型

### 1. WordDetailModel (词条完整信息)

**用途**: 词典面板显示的完整词条数据

**Dart模型定义**:
```dart
class WordDetailModel {
  final String word;              // 汉字词语
  final String pinyin;            // 拼音（带声调）
  final String? summary;          // 简短释义
  final List<WordEntry> entries;  // 详细词条（按词性分组）
  final String? contextSentence;  // 上下文例句（可选）
  final int? hskLevel;            // HSK等级（1-6）
}
```

**JSON格式** (扣子工作流返回 & Supabase存储):
```json
{
  "word": "学习",
  "pinyin": "xué xí",
  "summary": "to study; to learn",
  "hsk_level": 2,
  "entries": [
    {
      "pos": "v.",
      "definitions": [
        "to study",
        "to learn"
      ],
      "examples": [
        "我每天都学习中文。 - I study Chinese every day.",
        "他很爱学习。 - He loves to learn."
      ]
    },
    {
      "pos": "n.",
      "definitions": [
        "study",
        "learning"
      ],
      "examples": [
        "学习是一个长期的过程。 - Learning is a long-term process."
      ]
    }
  ]
}
```

### 2. WordEntry (词条详细解释)

**用途**: 按词性分组的释义和例句

**Dart模型定义**:
```dart
class WordEntry {
  final String pos;               // 词性标注
  final List<String> definitions; // 释义列表
  final List<String> examples;    // 例句列表
}
```

**JSON格式**:
```json
{
  "pos": "v.",
  "definitions": [
    "to study",
    "to learn"
  ],
  "examples": [
    "我在学习编程。 - I'm learning programming."
  ]
}
```

## 字段详细说明

### 必填字段

| 字段名 | 类型 | 说明 | 示例 |
|--------|------|------|------|
| `word` | string | 汉字词语（查询输入） | "你好" |
| `pinyin` | string | 汉语拼音，带声调符号 | "nǐ hǎo" |
| `summary` | string | 简短释义，用于卡片快速显示 | "hello; hi" |
| `entries` | array | 详细词条数组（可为空数组） | 见下方 |

**注意**: 
- `pinyin` 如果扣子工作流未生成，Flutter端会自动补充
- `summary` 为空时会降级显示 `entries` 的第一个释义

### 可选字段

| 字段名 | 类型 | 说明 | 示例 | 默认值 |
|--------|------|------|------|--------|
| `hsk_level` | int | HSK等级 (1-6) | 3 | null |
| `contextSentence` | string | 上下文例句（来自播客等） | "你好吗？" | null |

**说明**:
- `hsk_level`: 用于学习计划筛选和难度标记
- `contextSentence`: 播客等场景下提供的实际上下文

### entries 数组元素 (WordEntry)

| 字段名 | 类型 | 必填 | 说明 | 示例 |
|--------|------|------|------|------|
| `pos` | string | 是 | 词性标注 | "v.", "n.", "adj." |
| `definitions` | array\<string\> | 是 | 释义列表 | ["to study", "to learn"] |
| `examples` | array\<string\> | 否 | 例句列表 | ["我在学习。 - I'm studying."] |

## 词性标注规范 (pos)

使用标准缩写形式：

| 缩写 | 完整形式 | 中文 | 示例 |
|------|----------|------|------|
| `n.` | noun | 名词 | 学生 (student) |
| `v.` | verb | 动词 | 学习 (to study) |
| `adj.` | adjective | 形容词 | 好 (good) |
| `adv.` | adverb | 副词 | 很 (very) |
| `prep.` | preposition | 介词 | 在 (at, in) |
| `conj.` | conjunction | 连词 | 和 (and) |
| `pron.` | pronoun | 代词 | 我 (I, me) |
| `intj.` | interjection | 感叹词 | 哇 (wow) |
| `num.` | numeral | 数词 | 一 (one) |
| `mw.` | measure word | 量词 | 个 (classifier) |
| `part.` | particle | 助词 | 的 (particle) |

**注意**: 
- 可以组合使用，如 "v./n." 表示动词/名词兼用
- 中文专用词性如量词(mw.)、助词(part.)需要标注

## 例句格式规范

**标准格式**: `中文句子 - English translation`

**示例**:
```json
"examples": [
  "你好，很高兴认识你。 - Hello, nice to meet you.",
  "你好吗？ - How are you?",
  "大家好！ - Hello, everyone!"
]
```

**要求**:
1. 中英文用 ` - ` (空格-空格) 分隔
2. 中文例句使用中文标点（。！？）
3. 英文翻译使用英文标点（. ! ?）
4. 例句应实用、常见，涵盖不同使用场景

## 扣子工作流返回格式要求

### 完整示例

**请求** (Supabase Edge Function → 扣子):
```json
{
  "word": "学习",
  "target_language": "en",
  "context": "教育场景"
}
```

**响应** (扣子 → Supabase Edge Function):
```json
{
  "pinyin": "xué xí",
  "summary": "to study; to learn",
  "hsk_level": 2,
  "entries": [
    {
      "pos": "v.",
      "definitions": [
        "to study",
        "to learn",
        "to acquire knowledge"
      ],
      "examples": [
        "我每天都学习中文。 - I study Chinese every day.",
        "学习新技能需要时间。 - Learning new skills takes time.",
        "他在图书馆学习。 - He studies in the library."
      ]
    },
    {
      "pos": "n.",
      "definitions": [
        "study",
        "learning",
        "studies"
      ],
      "examples": [
        "学习是一个终身的过程。 - Learning is a lifelong process.",
        "他的学习成绩很好。 - His academic performance is good."
      ]
    }
  ]
}
```

### 错误响应

**格式**:
```json
{
  "error": "错误描述",
  "error_code": "ERROR_CODE"
}
```

**示例**:
```json
{
  "error": "工作流执行失败",
  "error_code": "WORKFLOW_EXECUTION_FAILED"
}
```

## 多语种支持

### 支持的目标语言

**语言代码对应 `ProfileModel.nativeLanguage` 字段**，默认值为 `'en'`。

| 语言代码 | 语言名称 | 示例 | 说明 |
|----------|----------|------|------|
| `en` | 英语 | hello | 默认 |
| `zh` | 中文 | 你好 | 中文母语 |
| `ja` | 日语 | こんにちは | 日语母语 |
| `ko` | 韩语 | 안녕하세요 | 韩语母语 |
| `es` | 西班牙语 | hola | 西班牙语母语 |
| `fr` | 法语 | bonjour | 法语母语 |
| `de` | 德语 | hallo | 德语母语 |

### 多语种示例

**日语翻译**:
```json
{
  "word": "你好",
  "pinyin": "nǐ hǎo",
  "summary": "こんにちは",
  "hsk_level": 1,
  "entries": [
    {
      "pos": "intj.",
      "definitions": [
        "こんにちは",
        "やあ"
      ],
      "examples": [
        "你好，请问你是谁？ - こんにちは、お名前は？"
      ]
    }
  ]
}
```

## 数据验证规则

### 必须满足的条件

1. **word**: 非空字符串
2. **pinyin**: 非空字符串（可以由Flutter端自动生成）
3. **summary**: 非空字符串
4. **entries**: 数组（可为空）
5. **hsk_level**: 如果存在，必须是 1-6 的整数

### 推荐满足的条件

1. **entries**: 至少包含一个词条
2. **definitions**: 每个词条至少包含一个释义
3. **examples**: 每个词条至少包含1-3个例句
4. **pinyin**: 使用标准声调符号 (ā á ǎ à)

### 数据质量检查

```typescript
// 伪代码：扣子工作流输出验证
function validateDictionaryResponse(data) {
  // 必填字段检查
  if (!data.word || !data.summary) {
    throw new Error('缺少必填字段: word, summary');
  }
  
  // entries格式检查
  if (data.entries && Array.isArray(data.entries)) {
    for (const entry of data.entries) {
      if (!entry.pos || !entry.definitions) {
        throw new Error('entries元素必须包含pos和definitions');
      }
      if (!Array.isArray(entry.definitions) || entry.definitions.length === 0) {
        throw new Error('definitions必须是非空数组');
      }
    }
  }
  
  // HSK等级检查
  if (data.hsk_level && (data.hsk_level < 1 || data.hsk_level > 6)) {
    throw new Error('hsk_level必须在1-6之间');
  }
  
  return true;
}
```

## Supabase数据库存储格式

### dictionary表结构

```sql
CREATE TABLE dictionary (
  word TEXT PRIMARY KEY,
  pinyin TEXT NOT NULL,
  hsk_level INT,
  translations JSONB NOT NULL,  -- 多语言翻译数据
  source TEXT,                  -- 数据来源 (coze, mdx, manual)
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

### translations字段格式

**JSONB结构**:
```json
{
  "en": {
    "summary": "hello; hi",
    "entries": [
      {
        "pos": "intj.",
        "definitions": ["hello", "hi"],
        "examples": ["你好！ - Hello!"]
      }
    ]
  },
  "ja": {
    "summary": "こんにちは",
    "entries": [...]
  },
  "ko": {
    "summary": "안녕하세요",
    "entries": [...]
  }
}
```

**说明**:
- 使用语言代码作为key
- 每种语言包含 `summary` 和 `entries`
- 支持同一词语的多语言版本

### 查询示例

```dart
// 查询中文词"你好"的英文翻译
final response = await supabase
  .from('dictionary')
  .select('word, pinyin, hsk_level, translations')
  .eq('word', '你好')
  .maybeSingle();

final translations = response['translations'] as Map<String, dynamic>;
final enData = translations['en'] as Map<String, dynamic>;
final summary = enData['summary']; // "hello; hi"
final entries = enData['entries']; // 词条数组
```

## 扣子工作流Prompt模板

### 推荐的AI Prompt

```
你是一个专业的中文词典编纂助手。用户会给你一个中文词语，你需要生成专业的词典条目。

**输入参数**:
- word: {word} (中文词语)
- target_language: {target_language} (目标语言代码，如 en, ja, ko)
- context: {context} (可选的上下文信息)

**输出要求**:
请严格按照以下JSON格式输出，不要包含任何其他文字说明：

{
  "pinyin": "汉语拼音（必须带声调符号，如 nǐ hǎo）",
  "summary": "简短翻译（1-3个词，用分号或逗号分隔）",
  "hsk_level": HSK等级（1-6的整数，如果不确定可省略此字段）,
  "entries": [
    {
      "pos": "词性标注（如 v., n., adj. 等）",
      "definitions": [
        "释义1",
        "释义2",
        "释义3"
      ],
      "examples": [
        "中文例句1 - English translation 1",
        "中文例句2 - English translation 2",
        "中文例句3 - English translation 3"
      ]
    }
  ]
}

**具体要求**:
1. pinyin: 使用标准声调符号 (ā á ǎ à ē é ě è...)，不要用数字标调
2. summary: 简洁明了，适合快速浏览
3. hsk_level: 参考官方HSK词表，1级最简单，6级最难
4. pos: 使用标准缩写 (v.动词, n.名词, adj.形容词, adv.副词, prep.介词, conj.连词, intj.感叹词, pron.代词, num.数词, mw.量词, part.助词)
5. definitions: 准确、自然，符合目标语言习惯，优先级从高到低排序
6. examples: 实用、常见，涵盖不同使用场景，格式必须为 "中文 - 目标语言"
7. 至少提供1个词条（entry），推荐2-3个不同词性的词条
8. 每个词条至少3个释义，2-3个例句

**重要**: 输出必须是有效的JSON格式，不能包含注释或其他文字。
```

### 测试用例

**输入**:
```json
{
  "word": "吃",
  "target_language": "en",
  "context": ""
}
```

**预期输出**:
```json
{
  "pinyin": "chī",
  "summary": "to eat; to consume",
  "hsk_level": 1,
  "entries": [
    {
      "pos": "v.",
      "definitions": [
        "to eat",
        "to have (a meal)",
        "to consume"
      ],
      "examples": [
        "我想吃饭。 - I want to eat.",
        "你吃过早餐了吗？ - Have you had breakfast?",
        "我们一起去吃午饭吧。 - Let's go have lunch together."
      ]
    },
    {
      "pos": "v.",
      "definitions": [
        "to suffer",
        "to endure"
      ],
      "examples": [
        "他吃了很多苦。 - He suffered a lot.",
        "吃亏是福。 - A loss may turn out to be a gain."
      ]
    }
  ]
}
```

## Flutter端使用示例

### 调用词典服务

```dart
final service = SimpleDictionaryService();

// 查询单词
final word = await service.getWordDetail(
  word: '学习',
  language: 'en',
  contextTranslation: 'study context',
);

print('拼音: ${word.pinyin}');           // xué xí
print('释义: ${word.summary}');          // to study; to learn
print('HSK: ${word.hskLevel}');         // 2
print('详细: ${word.allDefinitions}');   // v. to study, to learn; n. study, learning
```

### 显示词条详情

```dart
ListView.builder(
  itemCount: word.entries.length,
  itemBuilder: (context, index) {
    final entry = word.entries[index];
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 词性
          Text(entry.pos, style: TextStyle(fontWeight: FontWeight.bold)),
          // 释义
          ...entry.definitions.map((def) => Text('• $def')),
          // 例句
          ...entry.examples.map((ex) => Text(
            ex,
            style: TextStyle(fontStyle: FontStyle.italic),
          )),
        ],
      ),
    );
  },
)
```

## 版本历史

| 版本 | 日期 | 变更说明 |
|------|------|----------|
| 1.0 | 2026-01-27 | 初始版本，定义基础数据结构 |

## 常见问题

### Q: 如果扣子工作流返回的数据缺少某些字段怎么办？

A: Flutter端有容错处理：
- `pinyin` 缺失时会自动生成
- `summary` 缺失时会降级为 `entries` 第一个释义
- `entries` 为空时仍可正常显示（只显示summary）

### Q: 拼音声调符号怎么生成？

A: 推荐使用Unicode声调符号：
- ā (U+0101), á (U+00E1), ǎ (U+01CE), à (U+00E0)
- ē (U+0113), é (U+00E9), ě (U+011B), è (U+00E8)
- ī (U+012B), í (U+00ED), ǐ (U+01D0), ì (U+00EC)
- ō (U+014D), ó (U+00F3), ǒ (U+01D2), ò (U+00F2)
- ū (U+016B), ú (U+00FA), ǔ (U+01D4), ù (U+00F9)
- ǖ (U+01D6), ǘ (U+01D8), ǚ (U+01DA), ǜ (U+01DC)

### Q: 例句格式必须是中英对照吗？

A: 是的，固定格式 `中文 - 目标语言`，便于解析和显示。

### Q: 如何处理多义词？

A: 使用多个 `WordEntry`，每个词性或用法单独成条：
```json
{
  "entries": [
    {"pos": "v.", "definitions": ["吃饭的意思"], ...},
    {"pos": "v.", "definitions": ["吃亏的意思"], ...}
  ]
}
```

---

**维护人**: ToneUp开发团队  
**最后更新**: 2026年1月27日
