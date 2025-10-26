import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:toneup_app/components/feedback_button.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/routes.dart';
import 'package:toneup_app/services/navigation_service.dart';
import '../providers/plan_provider.dart';
import '../components/sliver_headers.dart'; // 吸顶代理类
import 'models/user_weekly_plan_model.dart';

class PlanPage extends StatefulWidget {
  const PlanPage({super.key});
  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  final ScrollController _scrollController = ScrollController();
  int? _activeItemGlobalIndex;
  late ThemeData theme;
  @override
  void initState() {
    super.initState();
    if (Provider.of<PlanProvider>(context, listen: false).allPlans.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<PlanProvider>(context, listen: false).getAllPlans();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 计算激活计划的索引
  void _calculateActiveItemIndex(
    List<UserWeeklyPlanModel> allPlans,
    UserWeeklyPlanModel? activePlan,
  ) {
    if (activePlan == null) return;
    for (int i = 0; i < allPlans.length; i++) {
      if (allPlans[i].id == activePlan.id) {
        _activeItemGlobalIndex = i; // 返回全局索引
      }
    }
  }

  Future<void> _changeGoal(UserWeeklyPlanModel plan) async {
    PlanProvider planProvider = Provider.of<PlanProvider>(
      context,
      listen: false,
    );
    final isActive = plan == planProvider.activePlan;
    // 显示确认对话框
    final shouldSwitch = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isActive
              ? 'This is the goal you are currently ongoing.'
              : 'Change Goal',
        ),
        content: isActive
            ? null
            : Text(
                'Do you want to switch goals? After that, the status of the current goal will be changed to pending.',
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(isActive ? 'OK' : 'Cancle'),
          ),
          if (!isActive)
            ElevatedButton.icon(
              icon: Icon(Icons.swap_calls_rounded, size: 24),
              label: Text("Change"),
              onPressed: () => Navigator.pop(context, true),
            ),
        ],
      ),
    );
    // 仅当用户确认切换时才执行后续操作
    if (shouldSwitch == true) {
      await planProvider.activatePlan(plan);
      NavigationService.go(AppRoutes.HOME);
    }
  }

  void _scrollToActiveItem() {
    if (_activeItemGlobalIndex == null) return;
    // 计算每个item的高度（根据你的_planItem高度估算，或动态获取）
    // 假设每个planItem高度约为100（包含margin和padding）
    const double itemHeight = 100;

    // 计算滚动目标位置（索引 * 单个item高度）
    final double targetOffset = (_activeItemGlobalIndex! * itemHeight).clamp(
      0,
      _scrollController.position.maxScrollExtent,
    );

    // debugPrint('targetOffset...$targetOffset');
    // 执行滚动（带动画）
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuad,
    );
  }

  // 加载中状态
  Widget _buildLoadingState(BuildContext context, PlanProvider planProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // SpinKitFadingCircle(
          //   color: theme.colorScheme.primaryFixed,
          //   size: 50.0,
          // ),
          CircularProgressIndicator(
            strokeCap: StrokeCap.round,
            backgroundColor: theme.colorScheme.secondaryContainer,
          ),
          const SizedBox(height: 20),
          Text(
            planProvider.loadingMessage ?? "Loading...",
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  // 错误状态
  Widget _buildErrorState(BuildContext context, PlanProvider planProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50.0),
          const SizedBox(height: 20),
          Text(
            "Loading Failed, Please Try Again.",
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () async {
              if (planProvider.retryFunc != null) planProvider.retryFunc!();
            },
            child: Text(
              "Retry",
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: theme.colorScheme.surfaceContainerHigh,
      //TODO: 改到主导航，暂时去掉顶部appBar
      // appBar: AppBar(title: const Text('Goals'), centerTitle: true),
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, child) {
          // 加载状态
          if (planProvider.isLoading) {
            return _buildLoadingState(context, planProvider);
          }
          // 加载错误状态
          if (planProvider.errorMessage != null) {
            return _buildErrorState(context, planProvider);
          }
          // 空状态
          if (planProvider.allPlans.isEmpty) {
            return Center(
              child: Text(
                "Your have no Active Goal yet.",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
            );
          }
          // 延迟执行滚动
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _scrollToActiveItem(),
          );
          // 从 Provider 获取分组数据
          final groupedPlans = planProvider.groupPlansByLevelAndMonth();
          // 按级别升序排序
          final levelKeys = groupedPlans.keys.toList()..sort();
          final allPlans = groupedPlans.values
              .expand((l) => l.values)
              .expand((m) => m)
              .toList();

          // 激活计划的索引
          _calculateActiveItemIndex(allPlans, planProvider.activePlan);

          return Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 88),
            child: RefreshIndicator(
              onRefresh: () async {
                await planProvider.getAllPlans();
              },
              backgroundColor: theme.colorScheme.secondaryContainer,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverAppBar(
                    surfaceTintColor: theme.colorScheme.surface,
                    backgroundColor: theme.colorScheme.surface,
                    title: Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Align(
                        alignment: AlignmentGeometry.centerLeft,
                        child: Text(
                          'Goals',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                    pinned: true,
                  ),
                  // 遍历所有级别分组
                  ...levelKeys.expand((level) {
                    final monthGroups = groupedPlans[level]!;
                    // 按月份升序排序
                    final monthKeys = monthGroups.keys.toList()..sort();
                    return [
                      // 级别吸顶头
                      SliverPersistentHeader(
                        delegate: LevelHeaderDelegate(title: 'HSK $level'),
                        pinned: true, // 吸顶效果
                      ),
                      // 遍历该级别下的所有月份分组
                      ...monthKeys.expand((monthKey) {
                        final plansInMonth = monthGroups[monthKey]!;
                        // 生成月份显示文本（如 "Aug. 2025"，保留你的格式）
                        final monthLabel = DateFormat(
                          'MMM. yyyy',
                        ).format(plansInMonth.first.createdAt);

                        return [
                          // 月份吸顶头（复用你的 MonthHeaderDelegate）
                          SliverPersistentHeader(
                            delegate: MonthHeaderDelegate(title: monthLabel),
                            pinned: true, // 吸顶效果
                          ),
                          // 该月份下的计划列表（保留你的列表结构）
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final plan = plansInMonth[index];
                              // 判断当前计划是否为激活状态（从 Provider 获取）
                              final isActive =
                                  plan.status == PlanStatus.active ||
                                  plan.status == PlanStatus.reactive;
                              // planProvider.activePlan?.id == plan.id;
                              return _buildPlanItem(
                                plan: plan,
                                isActive: isActive,
                                theme: theme,
                                onTap: () => _changeGoal(plan),
                              );
                            }, childCount: plansInMonth.length),
                          ),
                        ];
                      }),
                    ];
                  }),
                  SliverPadding(
                    padding: EdgeInsetsGeometry.only(top: 20, bottom: 100),
                    sliver: SliverToBoxAdapter(
                      child: Center(child: Text('No more data')),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 单个计划项
  Widget _buildPlanItem({
    required UserWeeklyPlanModel plan,
    required bool isActive,
    required ThemeData theme,
    VoidCallback? onTap,
  }) {
    IconData icon;
    Color iconColor;
    if (isActive) {
      icon = Icons.play_circle_filled_sharp;
      iconColor = Colors.amber;
    } else if (plan.status == PlanStatus.done) {
      icon = Icons.flag; //flag
      iconColor = Colors.amber;
    } else {
      icon = Icons.track_changes_rounded;
      iconColor = theme.colorScheme.onSecondaryFixedVariant;
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isActive && plan.progress != null)
            Text(
              'Ongoing...',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          FeedbackButton(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Ink(
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(icon, color: iconColor),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 10,
                        children: [
                          Text(
                            plan.topicTitle ?? 'No Plan Title',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isActive && plan.progress != null)
                            LinearProgressIndicator(
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(10),
                              value: calculatePlanProgress(plan),
                              backgroundColor: theme.colorScheme.primary
                                  .withAlpha(40),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
