/// 词条详细解释（按词性分组）
class WordEntry {
  final String pos; // 词性：v. (verb), n. (noun), adj., adv., etc.
  final List<String> definitions; // 该词性下的释义列表
  final List<String> examples; // 例句列表

  WordEntry({
    required this.pos,
    required this.definitions,
    required this.examples,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    return WordEntry(
      pos: json['pos'] as String? ?? '',
      definitions:
          (json['definitions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      examples:
          (json['examples'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'pos': pos, 'definitions': definitions, 'examples': examples};
  }
}

/// 词语详情模型
/// 用于显示词典面板的词条信息
class WordDetailModel {
  final String word; // 汉字词语
  final String pinyin; // 拼音（带声调）
  final String? summary; // 关键释意（简短概括）
  final List<WordEntry> entries; // 详细解释（按词性分组）
  final String? contextSentence; // 上下文例句（来自播客）
  final int? hskLevel; // HSK等级（可选）

  WordDetailModel({
    required this.word,
    required this.pinyin,
    this.summary,
    this.entries = const [],
    this.contextSentence,
    this.hskLevel,
  });

  /// 获取所有释义的文本（用于简单显示）
  String get allDefinitions {
    if (entries.isEmpty) return summary ?? '';
    return entries
        .map((e) => '${e.pos} ${e.definitions.join(', ')}')
        .join('; ');
  }

  /// 获取第一个例句（如果有）
  String? get firstExample {
    for (final entry in entries) {
      if (entry.examples.isNotEmpty) return entry.examples.first;
    }
    return null;
  }

  factory WordDetailModel.fromJson(Map<String, dynamic> json) {
    return WordDetailModel(
      word: json['word'] as String? ?? '',
      pinyin: json['pinyin'] as String? ?? '',
      summary: json['summary'] as String?,
      entries:
          (json['entries'] as List<dynamic>?)
              ?.map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      contextSentence: json['contextSentence'] as String?,
      hskLevel: json['hsk'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'pinyin': pinyin,
      'summary': summary,
      'entries': entries.map((e) => e.toJson()).toList(),
      'contextSentence': contextSentence,
      'hsk': hskLevel,
    };
  }
}
