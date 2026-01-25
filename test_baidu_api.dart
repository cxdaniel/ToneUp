import 'package:flutter/material.dart';
import 'package:toneup_app/services/baidu_dict_service.dart';

/// 百度词典版API快速测试脚本
/// 运行: flutter run -t test_baidu_api.dart -d "iPhone 15 Pro"
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final baiduDict = BaiduDictService();

  debugPrint('\n🧪 ========== 百度词典版API测试 ==========\n');

  // 测试1: 检查API配置
  if (!baiduDict.isConfigured) {
    return;
  }

  // 添加延迟避免QPS限流
  await Future.delayed(const Duration(milliseconds: 500));

  // 测试2: 中文→英文查询
  final result1 = await baiduDict.translate(word: '你好', from: 'zh', to: 'en');

  if (result1 != null) {
    if (result1.entries.isNotEmpty) {
      if (result1.entries.first.examples.isNotEmpty) {}
    }
  } else {}

  // 添加延迟避免QPS限流
  await Future.delayed(const Duration(milliseconds: 500));

  // 测试3: 英文→中文查询
  final result2 = await baiduDict.translate(
    word: 'hello',
    from: 'en',
    to: 'zh',
  );

  if (result2 != null) {
    if (result2.entries.isNotEmpty) {
      if (result2.entries.first.examples.isNotEmpty) {}
    }
  } else {}

  // 测试4: 测试不支持的语种
  final result3 = await baiduDict.translate(
    word: 'こんにちは',
    from: 'ja',
    to: 'zh',
  );

  if (result3 == null) {
  } else {}

  // 测试5: 查看使用统计
  baiduDict.getUsageStats();
}
