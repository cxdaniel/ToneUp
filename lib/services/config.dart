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
  static const String googleClientIdWeb =
      '751058148799-7s2ml5l7rn89c3826ind938uim04is5g.apps.googleusercontent.com';
  static const String googleClientIdIos =
      '751058148799-i8vpdms0d3dcr2o5uoud99044bbgs7ss.apps.googleusercontent.com';

  static String get clientIDGoogle =>
      kIsWeb ? googleClientIdWeb : (AppUtils.isIOS ? googleClientIdIos : '');

  // ⚠️ Apple Sign In 配置
  // 对于原生登录: 使用 Bundle ID (top.toneup.app) - Apple 会将其作为 audience
  static const String appleClientIdWeb = 'top.toneup.service';
  static const String appleClientIdNative = 'top.toneup.app';

  static String get clientIDApple =>
      kIsWeb ? appleClientIdWeb : appleClientIdNative;
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
