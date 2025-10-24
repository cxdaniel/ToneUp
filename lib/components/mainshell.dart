// 新增一个外壳页面，用于嵌套路由
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  // 切换底部导航项时调用
  void _goBranch(int index) {
    HapticFeedback.heavyImpact();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(36), //28
                  bottom: Radius.zero,
                ), // 圆角弧度
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withAlpha(30),
                    // blurRadius: 0,
                    offset: Offset(0, -1),
                  ),
                ],
              ),
              child: BottomNavigationBar(
                enableFeedback: true,
                currentIndex: navigationShell.currentIndex,
                onTap: _goBranch,
                type: BottomNavigationBarType.fixed,
                elevation: 0,
                backgroundColor: Colors.transparent,
                iconSize: 24,
                selectedItemColor: theme.colorScheme.primary,
                unselectedItemColor: theme.colorScheme.secondary,
                selectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.normal,
                ),
                selectedIconTheme: IconThemeData(size: 28),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.flag_rounded),
                    label: 'Practice',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.track_changes_outlined),
                    label: 'Goals',
                  ),
                  //TODO：暂替换为PlanPage
                  // BottomNavigationBarItem(
                  //   icon: Icon(Icons.podcasts),
                  //   label: 'Podcast',
                  // ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'Me',
                  ),
                ],
              ),
            ),
          ),
        ],
      ), // 嵌套路由的内容区域
      // bottomNavigationBar:
    );
  }
}
