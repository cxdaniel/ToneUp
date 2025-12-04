import 'package:flutter/foundation.dart';

class SupabaseConfig {
  static const String url = 'https://kixonwnuivnjqlraydmz.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtpeG9ud251aXZuanFscmF5ZG16Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY4MjUxMjMsImV4cCI6MjA3MjQwMTEyM30.PWwgMIdde9OMJLA-D5kzlEl9APUvAoeFwWtInXzb4a0';
}
// https://kixonwnuivnjqlraydmz.supabase.co/functions/v1/create-plan

class RevenueCatConfig {
  static const String apiKeyIOS = kDebugMode
      ? 'test_shpnmmJxpcaomwUSHhOLGIfqrAy'
      : 'appl_PfoovuEVLvjtBrZlHZMBaHdnpqW';
  static const String apiKeyAndroid = kDebugMode
      ? 'test_shpnmmJxpcaomwUSHhOLGIfqrAy'
      : 'YOUR_ANDROID_API_KEY';
  static const String entitlementId = 'pro_features';
}
