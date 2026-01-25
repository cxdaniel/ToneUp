# 词典系统实现指南

## 数据结构设计

### 1. 词典JSON格式 (`assets/dict/cedict_hsk.json`)

```json
{
  "词语": {
    "pinyin": "cí yǔ",              // 拼音（带声调）
    "summary": "word; expression",   // 关键释意（简短概括，2-3个主要意思）
    "entries": [                     // 详细解释（按词性分组）
      {
        "pos": "n.",                 // 词性标签
        "definitions": [             // 该词性下的释义列表
          "word",
          "phrase",
          "expression"
        ],
        "examples": [                // 例句（中英对照）
          "这个词语很常用。This word is very common.",
          "学习新词语很重要。Learning new words is important."
        ]
      },
      {
        "pos": "v.",
        "definitions": ["to express"],
        "examples": []
      }
    ],
    "hsk": 4                         // HSK等级（可选，1-6）
  }
}
```

### 2. 词性标签规范

- `n.` - 名词 (noun)
- `v.` - 动词 (verb)
- `adj.` - 形容词 (adjective)
- `adv.` - 副词 (adverb)
- `pron.` - 代词 (pronoun)
- `prep.` - 介词 (preposition)
- `conj.` - 连词 (conjunction)
- `int.` - 感叹词 (interjection)
- `mw.` - 量词 (measure word)
- `part.` - 助词 (particle)

### 3. 数据模型

#### WordDetailModel (主模型)
```dart
class WordDetailModel {
  final String word;                // 汉字词语
  final String pinyin;              // 拼音
  final String? summary;            // 关键释意
  final List<WordEntry> entries;    // 详细解释
  final String? contextSentence;    // 上下文例句（来自播客）
  final int? hskLevel;              // HSK等级
}
```

#### WordEntry (词条模型)
```dart
class WordEntry {
  final String pos;                 // 词性
  final List<String> definitions;   // 释义列表
  final List<String> examples;      // 例句列表
}
```

## UI展示层级

### 词典面板显示顺序

1. **汉字 + TTS播放按钮** (最顶部，大字体)
2. **拼音** (汉字下方，灰色)
3. **关键释意** (`summary`) - 简洁卡片，主要释义概括
4. **详细解释** (`entries`) - 按词性分组展示：
   - 词性标签（如 "v.", "n."）
   - 该词性的所有释义（编号列表）
   - 该词性的例句（斜体，浅色背景）
5. **原句** (`contextSentence`) - 播客中的上下文句子

## 词典维护方案

### 方案对比

| 方案 | 优点 | 缺点 | 适用场景 |
|------|------|------|----------|
| **A. 内嵌JSON** | 离线可用、查询快速、无API调用成本 | 需手动维护、包体积增大 | **当前方案（推荐）** |
| B. 在线API | 词库完整、无需维护 | 需网络、有延迟、API成本 | 词库扩展阶段 |
| C. 混合方案 | 平衡离线和在线优势 | 实现复杂 | 大规模应用 |

### 当前维护策略（方案A）

#### 词典构建流程

1. **数据来源**
   - CC-CEDICT开源词典
   - HSK官方词汇表
   - 常用中文词语库

2. **词条优先级**
   ```
   HSK 1-2: 600词（高频基础）
   HSK 3-4: 1200词（进阶常用）
   HSK 5-6: 2500词（高级词汇）
   播客专用词: 按内容添加
   ```

3. **手动维护步骤**
   ```bash
   # 1. 编辑词典文件
   vi assets/dict/cedict_hsk.json
   
   # 2. 验证JSON格式
   cat cedict_hsk.json | jq .
   
   # 3. 添加到assets
   # pubspec.yaml已配置 - assets/dict/
   
   # 4. 热重载测试
   flutter run
   ```

4. **词条编写规范**
   - `pinyin`: 使用声调符号（ā á ǎ à）
   - `summary`: 2-3个核心释义，用分号分隔
   - `definitions`: 从常用到少用排序
   - `examples`: 优先使用短句，中英对照
   - `hsk`: 标注HSK等级（便于分级学习）

#### 批量导入脚本（可选）

创建 `scripts/import_cedict.dart`:
```dart
/// 将CC-CEDICT格式转换为项目JSON格式
/// 输入：cedict_ts.u8（标准CC-CEDICT）
/// 输出：cedict_hsk.json
void main() {
  // 读取CC-CEDICT文件
  // 解析每行：传统字 简体字 [pin1 yin1] /def1/def2/
  // 转换为JSON格式
  // 写入assets/dict/cedict_hsk.json
}
```

### 扩展方向

#### 1. 短期（1-3个月）
- [ ] 添加HSK 1-4完整词库（~2400词）
- [ ] 为每个词条添加音频URL（可选）
- [ ] 添加词语使用频率标注

#### 2. 中期（3-6个月）
- [ ] 实现混合方案：本地缓存 + 在线API fallback
- [ ] 添加用户生词本功能
- [ ] 支持词根词缀分析

#### 3. 长期（6个月+）
- [ ] AI生成例句（基于上下文）
- [ ] 词语关联网络（近义词、反义词）
- [ ] 多语言支持（日语、韩语等）

## 代码集成说明

### SimpleDictionaryService 单例模式

```dart
// 初始化（app启动时自动）
SimpleDictionaryService();  // 构造函数会自动加载词典

// 查询词语
final wordDetail = SimpleDictionaryService().getWordDetail(
  word: '欢迎',
  contextTranslation: segment.translation,  // 可选
  contextSentence: segment.text,            // 可选
);

// 返回 WordDetailModel，包含完整词条信息
```

### 降级策略

当词典中没有词条时：
1. 使用 `pinyin` 库生成拼音
2. 使用 `contextTranslation`（segment英文翻译）作为 `summary`
3. `entries` 为空列表
4. UI仅显示：汉字、拼音、上下文翻译

## 性能优化

### 当前实现
- 单例模式，app启动时一次性加载
- 内存缓存全部词条（~6词约50KB）
- 查询时间：O(1) HashMap查找

### 大规模优化（>10000词）
- 按HSK等级分文件：`cedict_hsk1.json`, `cedict_hsk2.json`...
- 懒加载：按需加载对应等级词典
- 索引优化：添加首字母索引

## 测试建议

```dart
// 测试词典加载
test('词典加载测试', () async {
  final service = SimpleDictionaryService();
  await Future.delayed(Duration(milliseconds: 100));  // 等待加载
  
  final detail = service.getWordDetail(word: '欢迎');
  expect(detail.pinyin, 'huān yíng');
  expect(detail.summary, isNotNull);
  expect(detail.entries.length, greaterThan(0));
});

// 测试降级逻辑
test('未知词语降级测试', () {
  final detail = service.getWordDetail(
    word: '测试词',
    contextTranslation: 'test word',
  );
  expect(detail.pinyin, isNotEmpty);  // 拼音库生成
  expect(detail.summary, 'test word');  // 使用上下文
});
```

## 常见问题

### Q1: 如何添加新词条？
A: 直接编辑 `assets/dict/cedict_hsk.json`，按照上述JSON格式添加，热重载即可。

### Q2: 词典文件过大怎么办？
A: 可以分文件存储（按HSK等级），或使用gzip压缩（Flutter支持）。

### Q3: 如何支持繁体字？
A: 在词典JSON中添加 `"traditional"` 字段，查询时同时匹配简繁。

### Q4: 能否自动更新词典？
A: 可以实现热更新机制：从服务器下载最新JSON → 保存到本地 → 重新加载。

---

**维护者**: ToneUp开发团队  
**最后更新**: 2026-01-18  
**版本**: v1.0
