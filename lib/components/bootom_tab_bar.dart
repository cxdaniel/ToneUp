import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:toneup_app/router_config.dart';
// 1. 导入所有 Tab 对应的页面（确保路径正确，避免循环导入）

/// 通用底 Tab 栏组件（内部封装跳转逻辑）
/// [selectedIndex]：当前页面对应的 Tab 索引（0=Practice，1=Podcasts，2=Me）
class BottomTabBar extends StatelessWidget {
  final int selectedIndex;

  const BottomTabBar({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    // 3. Tab 切换逻辑（内部封装，引用页无需关心）
    void handleTabTap(int tappedIndex) {
      // 点击当前已选中的 Tab，不执行任何操作（避免重复跳转）
      if (tappedIndex == selectedIndex) return;
      // 跳转到对应页面（用 pushReplacement 避免页面栈叠加）
      switch (tappedIndex) {
        case 0:
          context.replace(AppRouter.HOME); // 跳转到 Practice 页面
          break;
        case 1:
          context.replace(AppRouter.PODCASTS); // 跳转到 Podcasts 页面
          break;
        case 2:
          context.replace(AppRouter.PROFILE); // 跳转到 Me 页面
          break;
        default:
          context.replace(AppRouter.HOME); // 跳转到 Practice 页面
          break;
      }
    }

    // 4. Tab 样式配置（不变）
    final List<BottomNavigationBarItem> tabItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.book_outlined),
        label: "Practices",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.podcasts_outlined),
        label: "Podcasts",
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outlined),
        label: "Me",
      ),
    ];

    return BottomNavigationBar(
      currentIndex: selectedIndex,
      onTap: handleTabTap, // 调用内部切换逻辑
      type: BottomNavigationBarType.fixed,
      elevation: 4,
      iconSize: 24,
      // 主题样式（复用全局主题）
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
      selectedLabelStyle: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
      unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
      // Tab 项
      items: tabItems,
    );
  }
}
