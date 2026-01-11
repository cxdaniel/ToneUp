import 'package:flutter/foundation.dart';
import 'package:toneup_app/router_config.dart' show AppRouter;
import 'package:toneup_app/services/utils.dart';

class UriConfig {
  /// App Store 下载链接
  static const String appStoreUrl =
      'https://apps.apple.com/app/toneup/id123456789';

  /// Google Play 下载链接
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.yourcompany.toneup';

  /// 应用的自定义 URI Scheme
  static String get appScheme => 'io.supabase.toneup:/';

  static String get loginCallbackUri => kIsWeb
      ? '${Uri.base.origin}${AppRouter.LOGIN_CALLBACK}/'
      : '$appScheme${AppRouter.LOGIN_CALLBACK}/';

  static String get linkingCallbackUri => kIsWeb
      ? '${Uri.base.origin}${AppRouter.LINKING_CALLBACK}/'
      : '$appScheme${AppRouter.LINKING_CALLBACK}/';

  static String get emailChangeCallbackUri => kIsWeb
      ? '${Uri.base.origin}${AppRouter.EMAIL_CHANGE_CALLBACK}/'
      : '$appScheme${AppRouter.EMAIL_CHANGE_CALLBACK}/';

  static String get resetPasswordCallbackUri => kIsWeb
      ? '${Uri.base.origin}${AppRouter.RESET_PASSWORD_CALLBACK}/'
      : '$appScheme${AppRouter.RESET_PASSWORD_CALLBACK}/';
}

class OAuthConfig {
  // ⚠️ Google Sign In 配置
  // Web Client ID: 用于 Web 平台和作为移动端的 serverClientId
  static const String googleClientIdWeb =
      '751058148799-7s2ml5l7rn89c3826ind938uim04is5g.apps.googleusercontent.com';
  // iOS Client ID: iOS 平台的 clientId
  static const String googleClientIdIos =
      '751058148799-i8vpdms0d3dcr2o5uoud99044bbgs7ss.apps.googleusercontent.com';
  // Android Client ID: 在 Google Cloud Console 配置但不在代码中使用
  // Android 应使用 Web Client ID 作为 serverClientId
  static const String googleClientIdAndroid =
      '751058148799-9vsop6jt8e11h3v256lev3p5pfa29ni0.apps.googleusercontent.com';

  static String get clientIDGoogle => kIsWeb
      ? googleClientIdWeb
      : (AppUtils.isIOS
            ? googleClientIdIos
            : googleClientIdWeb); // Android 使用 Web Client ID

  // ⚠️ Apple Sign In 配置
  // Web/Android: 使用 Service ID (top.toneup.service) 进行 OAuth
  // iOS: 使用 Bundle ID (top.toneup.app) 进行原生登录
  static const String appleClientIdWeb = 'top.toneup.service';
  static const String appleClientIdNative = 'top.toneup.app';

  static String get clientIDApple {
    if (kIsWeb) return appleClientIdWeb;
    if (AppUtils.isIOS) return appleClientIdNative;
    return appleClientIdWeb; // Android 使用 Web Client ID
  }
}

/// Supabase 配置
class SupabaseConfig {
  static const String url = 'https://kixonwnuivnjqlraydmz.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtpeG9ud251aXZuanFscmF5ZG16Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4MjUxMjMsImV4cCI6MjA3MjQwMTEyM30.PWwgMIdde9OMJLA-D5kzlEl9APUvAoeFwWtInXzb4a0';
}

/// RevenueCat 配置
class RevenueCatConfig {
  static const bool useTestKey = kDebugMode;
  static bool get isBetaFreeTrial => true;
  static const String apiKeyIOS = useTestKey
      ? 'test_shpnmmJxpcaomwUSHhOLGIfqrAy'
      : 'appl_PfoovuEVLvjtBrZlHZMBaHdnpqW';
  // ⚠️ TODO: 请从 RevenueCat Dashboard 获取 Android Production API Key
  // 位置: RevenueCat Dashboard → Project → API Keys → Google Play
  static const String apiKeyAndroid = useTestKey
      ? 'test_shpnmmJxpcaomwUSHhOLGIfqrAy'
      : 'goog_YOUR_ANDROID_PRODUCTION_KEY'; // 替换为实际的 Android Production Key
  static const String entitlementId = 'pro_features';

  // ✅ 产品 ID（必须与 App Store Connect 中的一致）
  static const String monthlyProductId = 'toneup_monthly_sub';
  static const String yearlyProductId = 'toneup_annually_sub';
}
