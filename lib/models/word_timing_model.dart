/// 字级别时间信息模型
/// 用于播放器字幕高亮同步
class WordTiming {
  /// 字符
  final String char;

  /// 起始时间（毫秒）
  final int startMs;

  WordTiming({required this.char, required this.startMs});

  /// 从紧凑数组格式解析 [char, startMs]
  factory WordTiming.fromJson(List<dynamic> json) {
    return WordTiming(char: json[0] as String, startMs: json[1] as int);
  }

  /// 转换为紧凑数组格式
  List<dynamic> toJson() => [char, startMs];

  /// 计算结束时间（从下一个字的起始时间推算）
  /// [nextWord] 下一个字的时间信息
  /// [segmentEndMs] 当前段落的结束时间（毫秒）
  int getEndMs(WordTiming? nextWord, int segmentEndMs) {
    return nextWord?.startMs ?? segmentEndMs;
  }

  @override
  String toString() => 'WordTiming(char: $char, startMs: $startMs)';
}

/// 所有段落的字级别时间数据
class WordTimingsData {
  /// 每个segment的字时间信息
  /// key: segmentId (字符串形式的数字，如 "1", "2")
  /// value: 该segment中所有字的时间信息列表
  final Map<String, List<WordTiming>> segmentTimings;

  WordTimingsData(this.segmentTimings);

  /// 从JSON解析
  /// JSON格式: {"1": [["今", 160], ["天", 320]], "2": [...]}
  factory WordTimingsData.fromJson(Map<String, dynamic> json) {
    final Map<String, List<WordTiming>> timings = {};

    json.forEach((segmentId, wordList) {
      if (wordList is List) {
        timings[segmentId] = wordList
            .map((w) => WordTiming.fromJson(w as List))
            .toList();
      }
    });

    return WordTimingsData(timings);
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};
    segmentTimings.forEach((segmentId, words) {
      result[segmentId] = words.map((w) => w.toJson()).toList();
    });
    return result;
  }

  /// 根据播放位置找到当前高亮的字在列表中的索引
  /// [segmentId] 段落ID
  /// [currentMs] 当前播放位置（毫秒）
  /// 返回字在words列表中的索引，如果未找到返回null
  int? getCurrentCharIndex(String segmentId, int currentMs) {
    final words = segmentTimings[segmentId];
    if (words == null || words.isEmpty) return null;

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final nextWord = i < words.length - 1 ? words[i + 1] : null;

      // 估算当前字的结束时间
      final endMs = nextWord?.startMs ?? (currentMs + 1000);

      if (currentMs >= word.startMs && currentMs < endMs) {
        return i;
      }
    }

    return null;
  }

  /// 获取指定segment的所有字
  List<WordTiming>? getSegmentWords(String segmentId) {
    return segmentTimings[segmentId];
  }

  /// 获取指定segment中指定索引的字
  WordTiming? getWordAt(String segmentId, int index) {
    final words = segmentTimings[segmentId];
    if (words == null || index < 0 || index >= words.length) {
      return null;
    }
    return words[index];
  }

  /// 获取所有segment的总字符数
  int get totalCharCount {
    int count = 0;
    for (var words in segmentTimings.values) {
      count += words.length;
    }
    return count;
  }

  @override
  String toString() {
    return 'WordTimingsData(segments: ${segmentTimings.length}, totalChars: $totalCharCount)';
  }
}
