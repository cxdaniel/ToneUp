import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:toneup_app/models/enumerated_types.dart';

class SupabaseConfig {
  static const String url = 'https://kixonwnuivnjqlraydmz.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtpeG9ud251aXZuanFscmF5ZG16Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4MjUxMjMsImV4cCI6MjA3MjQwMTEyM30.PWwgMIdde9OMJLA-D5kzlEl9APUvAoeFwWtInXzb4a0';
}
// https://kixonwnuivnjqlraydmz.supabase.co/functions/v1/create-plan

class RevenueCatConfig {
  static const bool useTestKey = kDebugMode;

  static const String apiKeyIOS = useTestKey
      ? 'test_shpnmmJxpcaomwUSHhOLGIfqrAy'
      : 'appl_PfoovuEVLvjtBrZlHZMBaHdnpqW';
  static const String apiKeyAndroid = useTestKey
      ? 'test_shpnmmJxpcaomwUSHhOLGIfqrAy'
      : 'YOUR_ANDROID_API_KEY';
  static const String entitlementId = 'pro_features';

  // ✅ 产品 ID（必须与 App Store Connect 中的一致）
  static const String monthlyProductId = 'toneup_monthly_sub';
  static const String yearlyProductId = 'toneup_annually_sub';
}

class PlatformUtils {
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

  /// App Store 下载链接
  static const String appStoreUrl =
      'https://apps.apple.com/app/toneup/id123456789';

  /// Google Play 下载链接
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.yourcompany.toneup';
}
