import 'package:jieba_flutter/analysis/jieba_segmenter.dart';

class ChineseWordsService {
  // 单例模式：确保全局只有一个服务实例
  static final ChineseWordsService _instance = ChineseWordsService._internal();
  factory ChineseWordsService() => _instance;
  ChineseWordsService._internal();
}

/// 中文分词（精确模式，拆分字词）
List<String> processChineseText(String text) {
  final seg = JiebaSegmenter();
  return seg.sentenceProcess(text);
}

// 辅助工具：判断是否为中文字符
bool isChinese(String str) {
  return RegExp(r'[\u4e00-\u9fa5]').hasMatch(str);
}
