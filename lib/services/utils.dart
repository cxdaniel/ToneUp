import 'package:faker/faker.dart';
import 'package:jieba_flutter/analysis/jieba_segmenter.dart';

class AppUtils {
  /// 中文分词（精确模式，拆分字词）
  static List<String> processChineseText(String text) {
    final seg = JiebaSegmenter();
    return seg.sentenceProcess(text);
  }

  /// 辅助工具：判断是否为中文字符
  static bool isChinese(String str) {
    return RegExp(r'[\u4e00-\u9fa5]').hasMatch(str);
  }

  /// 获取随机昵称
  static String generateRandomNickname() {
    final adjectives = Faker().randomGenerator.element([
      'Swift',
      'Brave',
      'Clever',
      'Mighty',
      'Wise',
      'Fierce',
      'Nimble',
      'Bold',
      'Gentle',
    ]);
    final nouns = Faker().randomGenerator.element([
      'Dragon',
      'Phoenix',
      'Tiger',
      'Tortoise',
      'Lion',
      'Wolf',
      'Eagle',
      'Shark',
      'Panda',
    ]);
    return '$adjectives $nouns';
  }
}
