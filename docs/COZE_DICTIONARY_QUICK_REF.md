# 扣子词典工作流 - 快速配置卡

## 🎯 工作流输入参数

```json
{
  "word": "你好",              // 必填：中文词语
  "target_language": "en",     // 必填：目标语言 (en/ja/ko等)
  "context": ""                // 可选：上下文信息
}
```

## ✅ 工作流标准输出格式

```json
{
  "pinyin": "nǐ hǎo",
  "summary": "hello; hi",
  "hsk_level": 1,
  "entries": [
    {
      "pos": "intj.",
      "definitions": ["hello", "hi", "how do you do"],
      "examples": [
        "你好，很高兴认识你。 - Hello, nice to meet you.",
        "你好吗？ - How are you?"
      ]
    }
  ]
}
```

## 📋 字段说明速查

| 字段 | 类型 | 必填 | 说明 | 示例 |
|------|------|------|------|------|
| `pinyin` | string | 是 | 拼音(带声调) | "nǐ hǎo" |
| `summary` | string | 是 | 简短释义 | "hello; hi" |
| `hsk_level` | int | 否 | HSK等级(1-6) | 1 |
| `entries` | array | 是 | 词条数组 | 见下方 |

### entries 子字段

| 字段 | 类型 | 必填 | 说明 | 示例 |
|------|------|------|------|------|
| `pos` | string | 是 | 词性 | "v.", "n.", "adj." |
| `definitions` | array | 是 | 释义列表 | ["to study", "to learn"] |
| `examples` | array | 否 | 例句列表 | ["我学习。 - I study."] |

## 🏷️ 词性标注速查表

| 缩写 | 中文 | 英文 | 示例 |
|------|------|------|------|
| `v.` | 动词 | verb | 学习 |
| `n.` | 名词 | noun | 学生 |
| `adj.` | 形容词 | adjective | 好 |
| `adv.` | 副词 | adverb | 很 |
| `intj.` | 感叹词 | interjection | 哇 |
| `prep.` | 介词 | preposition | 在 |
| `conj.` | 连词 | conjunction | 和 |
| `pron.` | 代词 | pronoun | 我 |
| `mw.` | 量词 | measure word | 个 |
| `part.` | 助词 | particle | 的 |

## 📝 扣子Prompt模板（简化版）

```
请为中文词"{word}"生成{target_language}词典条目。

严格按此JSON格式输出（不要其他文字）：
{
  "pinyin": "带声调拼音",
  "summary": "简短翻译",
  "hsk_level": HSK等级1-6,
  "entries": [
    {
      "pos": "词性(v./n./adj.等)",
      "definitions": ["释义1", "释义2", "释义3"],
      "examples": ["中文例句 - English translation"]
    }
  ]
}

要求：
1. pinyin用声调符号(nǐ hǎo)，不用数字
2. summary简洁(1-3个词)
3. 至少1个entry，推荐2-3个
4. 每个entry至少3个definitions、2个examples
5. examples格式: "中文 - 目标语言"
6. 只输出JSON，不要其他解释
```

## 🧪 测试用例

### 测试1：基础词汇

**输入**:
```json
{"word": "吃", "target_language": "en"}
```

**预期输出**:
```json
{
  "pinyin": "chī",
  "summary": "to eat",
  "hsk_level": 1,
  "entries": [
    {
      "pos": "v.",
      "definitions": ["to eat", "to have (a meal)", "to consume"],
      "examples": [
        "我想吃饭。 - I want to eat.",
        "你吃了吗？ - Have you eaten?"
      ]
    }
  ]
}
```

### 测试2：多义词

**输入**:
```json
{"word": "打", "target_language": "en"}
```

**预期输出**:
```json
{
  "pinyin": "dǎ",
  "summary": "to hit; to make; to play",
  "hsk_level": 2,
  "entries": [
    {
      "pos": "v.",
      "definitions": ["to hit", "to strike", "to beat"],
      "examples": ["他打了我。 - He hit me."]
    },
    {
      "pos": "v.",
      "definitions": ["to play (sports/games)", "to fight"],
      "examples": ["打篮球 - to play basketball"]
    },
    {
      "pos": "v.",
      "definitions": ["to make (a call)", "to send"],
      "examples": ["打电话 - to make a phone call"]
    }
  ]
}
```

### 测试3：日语翻译

**输入**:
```json
{"word": "谢谢", "target_language": "ja"}
```

**预期输出**:
```json
{
  "pinyin": "xiè xie",
  "summary": "ありがとう",
  "hsk_level": 1,
  "entries": [
    {
      "pos": "v.",
      "definitions": ["ありがとう", "どうも"],
      "examples": ["谢谢你。 - ありがとうございます。"]
    }
  ]
}
```

## ⚠️ 常见错误

### ❌ 错误1：拼音使用数字标调
```json
{"pinyin": "ni3 hao3"}  // 错误
```
✅ 正确：
```json
{"pinyin": "nǐ hǎo"}
```

### ❌ 错误2：例句格式不对
```json
{"examples": ["I study Chinese"]}  // 缺少中文
```
✅ 正确：
```json
{"examples": ["我学习中文。 - I study Chinese."]}
```

### ❌ 错误3：返回额外文字
```
这是词典条目：
{"pinyin": "nǐ hǎo", ...}
```
✅ 正确：只返回纯JSON
```json
{"pinyin": "nǐ hǎo", ...}
```

### ❌ 错误4：definitions为空
```json
{"pos": "v.", "definitions": []}
```
✅ 正确：至少1个释义
```json
{"pos": "v.", "definitions": ["to study"]}
```

## 🔗 完整文档

详细说明请参考: [DICTIONARY_DATA_STRUCTURE.md](./DICTIONARY_DATA_STRUCTURE.md)

---

**更新**: 2026-01-27
