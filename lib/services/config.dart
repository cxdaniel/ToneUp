import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:toneup_app/models/enumerated_types.dart';

class OAuthConfig {
  // ✅ 请替换为你的 OAuth 重定向 URI
  static String get redirectUri {
    if (kIsWeb) {
      return '${Uri.base.origin}/auth/callback/login/';
    } else if (Platform.isIOS) {
      return 'io.supabase.toneup://login-callback/';
    } else if (Platform.isAndroid) {
      return 'io.supabase.toneup://login-callback/';
    } else {
      throw UnsupportedError('Unsupported platform for Google OAuth');
    }
  }

  static String get clientIDGoogle => kIsWeb
      ? dotenv.env['GOOGLE_CLIENT_ID_WEB'] ?? ''
      : Platform.isIOS
      ? dotenv.env['GOOGLE_CLIENT_ID_IOS'] ?? ''
      : ''; // Android clientId 从 google-services.json 自动读取

  // ⚠️ 重要: serverClientId 用于获取 idToken (必须是 Web Client ID)
  // 这是 Google Sign In 7.x 的新要求
  static String get serverClientIDGoogle =>
      dotenv.env['GOOGLE_SERVER_CLIENT_ID'] ?? '';

  // ⚠️ Apple Sign In 配置
  // 对于原生登录: 使用 Bundle ID (top.toneup.app) - Apple 会将其作为 audience
  // 对于 Web OAuth: 使用 Service ID (top.toneup.service)
  static String get clientIDApple => kIsWeb
      ? dotenv.env['APPLE_CLIENT_ID_WEB'] ?? ''
      : dotenv.env['APPLE_CLIENT_ID_NATIVE'] ?? '';

  static String get clientSecretGoogle =>
      dotenv.env['GOOGLE_CLIENT_SECRET'] ?? '';
  static String get clientSecretApple =>
      dotenv.env['APPLE_CLIENT_SECRET'] ?? '';
}

class SupabaseConfig {
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
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
