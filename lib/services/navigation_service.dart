import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 全局导航 key，用于关联根 Navigator
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

class NavigationService {
  static GoRouter get router => GoRouter.of(rootNavigatorKey.currentContext!);

  static void go(String location) {
    debugPrint('NavigationService:::${rootNavigatorKey.currentContext}');
    if (rootNavigatorKey.currentContext != null) {
      router.go(location);
    }
  }

  // 可以添加更多方法：push、replace等
}

// 使用时
// NavigationService.go(AppRoutes.HOME);
