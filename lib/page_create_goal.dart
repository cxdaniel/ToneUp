import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:toneup_app/components/components.dart';
import 'package:toneup_app/models/indicator_result_model.dart';
import 'package:toneup_app/models/user_weekly_plan_model.dart';
import 'package:toneup_app/providers/create_goal_provider.dart';
import 'package:toneup_app/providers/profile_provider.dart';

class CreateGoalPage extends StatefulWidget {
  const CreateGoalPage({super.key});
  @override
  State<CreateGoalPage> createState() => _CreateGoalPageState();
}

class _CreateGoalPageState extends State<CreateGoalPage> {
  CreateGoalProvider? provider;
  late ThemeData theme;
  @override
  void initState() {
    super.initState();
    // 延迟调用以确保context可用
    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider = Provider.of<CreateGoalProvider>(context, listen: false);
      provider?.getResultfromHistory(ProfileProvider().profile?.level ?? 1);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CreateGoalProvider>(
      builder: (ctx, provider, child) {
        provider = provider;

        if (provider.errorMessage != null) {
          return _buildErrorState();
        }
        if (provider.creatingPlanProgress != null || provider.isCreated) {
          return _buildCreateProgressState();
        }
        if (provider.focusedIndicators != null) {
          return _buildIndicatorState();
        }
        return _buildLoadingState();
      },
    );
  }

  Future<void> _createNewGoal() async {
    provider!.createGoal(ProfileProvider().profile?.level ?? 1);
  }

  /// ⏳✅ 计划创建中&创建成功状态
  Widget _buildCreateProgressState() {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).viewPadding.top,
          bottom: 80,
          left: 40,
          right: 40,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 24,
          children: [
            Icon(
              provider!.isCreated
                  ? Icons.celebration_rounded
                  : Icons.insights_rounded,
              color: theme.colorScheme.primary,
              size: 64.0,
            ),
            Text(
              provider!.isCreated
                  ? 'Goal Created Successfully!'
                  : 'Creating Your Goal ...',
              style: theme.textTheme.headlineSmall!.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                if (provider!.creatingPlanProgress != null)
                  ...provider!.creatingPlanProgress!.map((
                    int key,
                    Map<String, dynamic> mesage,
                  ) {
                    return MapEntry(
                      key,
                      Text.rich(
                        TextSpan(
                          children: [
                            if (mesage['data'] != null)
                              WidgetSpan(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Icon(
                                    Icons.task_alt_rounded,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            TextSpan(
                              text: mesage['message'] as String,
                              style: theme.textTheme.titleMedium!.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            if (mesage['data'] == null)
                              WidgetSpan(
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).values,
              ],
            ),
            // SizedBox(height: 10),
            if (provider!.isCreated) _goalCard(provider!.newPlan!),
            mainActtionButton(
              context: context,
              label: 'Start Now',
              icon: Icons.radar_rounded,
              loadingLabel: provider!.isCreated
                  ? null
                  : 'Finalizing your goal...',
              onTap: provider!.isCreated ? () => context.pop() : null,
            ),
            Text(
              'Your new Goal has been created based on your practice data analysis. You can now start working towards achieving it!',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 📊 指标展示状态
  Widget _buildIndicatorState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Goal Page')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsetsGeometry.only(top: 40, left: 24, right: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: 24,
            children: [
              Text(
                'Based on the analysis of your practice data, The Core Indicators for this Goal',
                style: theme.textTheme.titleLarge!.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'select the top 3 indicators to focus on:',
                style: theme.textTheme.titleMedium!.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              Column(
                spacing: 10,
                children: [
                  ...provider!.focusedIndicators!.map((e) => _indicatorCard(e)),
                ],
              ),
              mainActtionButton(
                context: context,
                label: 'Generate new Goal',
                icon: Icons.radar_rounded,
                isLoading: provider!.isLoading,
                loadingLabel: provider!.loadingMessage,
                onTap: () {
                  _createNewGoal();
                },
              ),
              SizedBox(height: 0),
              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'You have ',
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: '1',
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: ' Goal generation left this month. ',
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    TextSpan(
                      text:
                          '\nUpgrade to the Pro Plan to enjoy unlimited plan.',
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ❌ 错误状态
  Widget _buildErrorState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Goal Page')),
      body: Center(
        child: Text(
          provider?.errorMessage ?? "An error occurred",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      ),
    );
  }

  /// ⏳ 默认加载中状态
  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Goal Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeCap: StrokeCap.round,
              backgroundColor: theme.colorScheme.secondaryContainer,
            ),
            const SizedBox(height: 20),
            Text(
              provider?.loadingMessage ?? "Loading...",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalCard(UserWeeklyPlanModel plan) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        spacing: 12,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tagLabel(
            context: context,
            label: 'HSK ${plan.level}',
            backColor: const Color(0xFFFF9500),
            frontColor: Colors.white,
          ),
          Text(
            plan.topicTitle ?? 'Unnamed Goal',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicatorCard(IndicatorCoreDetailModel indicator) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        spacing: 4,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              children: [
                WidgetSpan(
                  child: tagLabel(
                    context: context,
                    label: 'Recognition',
                    fontSize: 12,
                  ),
                ),
                WidgetSpan(child: SizedBox(width: 8)),
                TextSpan(
                  text: indicator.indicatorName,
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'AVG Score: ${(indicator.avgScore * 100).toStringAsFixed(2)}',
              ),
              Text(
                '${indicator.practiceCount.toStringAsFixed(0)}/${indicator.minimum.toStringAsFixed(0)} ',
              ),
            ],
          ),
          LinearProgressIndicator(
            minHeight: 10,
            borderRadius: BorderRadius.circular(10),
            value: (indicator.practiceCount / indicator.minimum).clamp(
              0.0,
              1.0,
            ),
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primary.withAlpha(40),
          ),
        ],
      ),
    );
  }
}
