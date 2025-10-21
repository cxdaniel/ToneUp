// 新增一个外壳页面，用于嵌套路由
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  // 切换底部导航项时调用
  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          navigationShell,
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              // 设置圆角和边距
              // margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                // borderRadius: BorderRadius.circular(28),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                  bottom: Radius.zero,
                ), // 圆角弧度
                boxShadow: [
                  BoxShadow(
                    // 可选：添加阴影增强立体感
                    color: Colors.black12,
                    blurRadius: 16,
                  ),
                ],
              ),
              child: BottomNavigationBar(
                enableFeedback: true,
                currentIndex: navigationShell.currentIndex,
                onTap: _goBranch,
                // 主题样式（复用全局主题）
                type: BottomNavigationBarType.fixed,
                elevation: 0, //阴影高度（控制底部导航栏的立体感）
                backgroundColor: Colors.transparent,
                iconSize: 24,
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Theme.of(
                  context,
                ).colorScheme.secondaryFixed,
                selectedLabelStyle: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                unselectedLabelStyle: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(fontWeight: FontWeight.normal),
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
