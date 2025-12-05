import 'package:flutter/foundation.dart';

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
