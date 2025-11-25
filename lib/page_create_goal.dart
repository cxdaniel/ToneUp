import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toneup_app/components/components.dart';
import 'package:toneup_app/models/indicator_result_model.dart';
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
        if (provider.isCreated) {
          return _buildCreateState();
        }
        if (provider.indicatorResult != null) {
          return _buildIndicatorState();
        }
        return _buildLoadingState();
      },
    );
  }

  Future<void> _createNewGoal() async {
    await provider!.createGoal(ProfileProvider().profile?.level ?? 1);
  }

  Widget _buildCreateState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Goal Page')),
      body: const Center(child: Text('This is the Create Goal Page')),
    );
  }

  Widget _buildIndicatorState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Goal Page')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsetsGeometry.only(top: 40, left: 24, right: 24),
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

  Widget _indicatorCard(IndicatorCoreDetailModel indicator) {
    return Card(
      shadowColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 4,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              indicator.indicatorName,
              style: theme.textTheme.titleMedium!.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: ShapeDecoration(
                color: theme.colorScheme.secondaryContainer,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 1,
                    strokeAlign: BorderSide.strokeAlignCenter,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSecondaryContainer.withAlpha(40),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Targets Words',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 4),
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
          ],
        ),
      ),
    );
  }

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

  /// ⏳ 加载中状态
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
}
