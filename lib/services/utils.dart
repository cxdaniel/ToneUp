import 'dart:io' show Platform;

import 'package:faker/faker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:jieba_flutter/analysis/jieba_segmenter.dart';
import 'package:toneup_app/models/enumerated_types.dart' show PlatformType;

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

  static bool isEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// 是否为移动平台（iOS 或 Android）
  static bool get isMobile {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isAndroid;
  }

  /// 是否为 Web 平台
  static bool get isWeb => kIsWeb;

  /// 是否为 iOS
  static bool get isIOS {
    if (kIsWeb) return false;
    return Platform.isIOS;
  }

  /// 是否为 Android
  static bool get isAndroid {
    if (kIsWeb) return false;
    return Platform.isAndroid;
  }

  /// 是否支持应用内购买
  static bool get supportsInAppPurchase => isMobile;

  /// 获取平台名称
  static PlatformType get platformName {
    if (kIsWeb) return PlatformType.web;
    if (Platform.isIOS) return PlatformType.iOS;
    if (Platform.isAndroid) return PlatformType.android;
    return PlatformType.unknown;
  }
}
