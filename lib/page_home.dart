import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:toneup_app/components/feedback_button.dart';
import 'package:toneup_app/models/user_practice_model.dart';
import 'package:toneup_app/models/user_weekly_plan_model.dart';
import 'package:toneup_app/providers/plan_provider.dart';
import 'package:toneup_app/routes.dart';
import 'package:toneup_app/theme_data.dart';

// 1. 先定义 Tab 对应的页面（Practice 对应首页，其他页面占位，后续可补充）
// 首页（原 HomePage，对应 Practice Tab）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  UserWeeklyPlanModel? _planData;
  late ThemeData theme;

  @override
  void initState() {
    super.initState();
    if (Provider.of<PlanProvider>(context, listen: false).activePlan == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<PlanProvider>(context, listen: false).initialize();
        // Provider.of<PlanProvider>(context, listen: false).getAllPlans();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  void _gotoPagePlan() {
    if (kDebugMode) debugPrint('on tap');
    // context.push(AppRoutes.GOAL_LIST);
    context.go(AppRoutes.GOAL_LIST);
  }

  // 生成活动卡片
  List<Widget> _buildActivityCards(BuildContext context) {
    if (_planData == null) return [];
    List<UserPracticeModel>? practices = _planData!.practiceData;
    if (practices == null || practices.isEmpty) {
      debugPrint("target_activities 为空");
      return [];
    }
    // 动态计算卡片宽高（三等分）
    final double screenWidth = MediaQuery.of(context).size.width;
    final double paddingHorizontal = 24;
    final double cardSpacing = 16;
    final double cardWidth =
        (screenWidth - 2 * paddingHorizontal - 2 * cardSpacing) / 3;
    final double cardHeight = cardWidth * 1; // 1:1 正方形卡片
    // 生成卡片列表
    List<Widget> activityCards = [];
    for (int i = 0; i < practices.length; i++) {
      final practiceData = practices[i];
      if (practiceData.instances.isEmpty) continue;
      activityCards.add(
        FeedbackButton(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await context.push(
              AppRoutes.PRACTICE,
              extra: {'practiceData': practiceData, 'planData': _planData},
            );
            if (context.mounted) {
              Provider.of<PlanProvider>(context, listen: false).refreshPlan();
            }
          },
          child: Ink(
            decoration: ShapeDecoration(
              color: (practiceData.score > 0)
                  ? theme.extension<AppThemeExtensions>()?.expContainer
                  : theme.colorScheme.primaryContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: SizedBox(
              width: cardWidth,
              height: cardHeight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 56,
                    color: (practiceData.score > 0)
                        ? theme.extension<AppThemeExtensions>()?.exp
                        : theme.colorScheme.primaryFixedDim,
                  ),
                  Text(
                    '${practiceData.instances.length} Quizes',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: (practiceData.score > 0)
                          ? theme
                                .extension<AppThemeExtensions>()
                                ?.onExpContainer
                          : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // 空状态处理
    if (activityCards.isEmpty) {
      return [
        Container(
          width: cardWidth,
          height: cardHeight,
          padding: const EdgeInsets.all(12),
          decoration: ShapeDecoration(
            color: theme.colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Center(
            child: Text(
              "暂无活动",
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ),
      ];
    }

    return activityCards;
  }

  /// 构建目标词汇
  Widget _buildTargetWords() {
    if (_planData == null) {
      return const Text("Loading...");
    }
    final List<dynamic> chars = _planData!.materialSnapshot.charsNew;
    final List<dynamic> words = _planData!.materialSnapshot.wordsNew;
    final List<dynamic> targetWords = [...chars, ...words].cast<String>();

    return Text.rich(
      TextSpan(
        children: targetWords
            .asMap()
            .entries
            .map((entry) {
              final int index = entry.key;
              final String word = entry.value;
              final bool isLast = index == targetWords.length - 1;
              return [
                TextSpan(
                  text: word,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
                    decorationStyle: TextDecorationStyle.dotted,
                    decorationThickness: 1,
                    height: 2,
                    letterSpacing: 0.50,
                  ),
                ),
                if (!isLast)
                  TextSpan(
                    text: '、',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                      height: 2,
                      letterSpacing: 0.50,
                    ),
                  ),
              ];
            })
            .expand((e) => e)
            .toList(),
      ),
    );
  }

  /// 构建常用句子
  List<Widget> _buildCommonSentences() {
    if (_planData == null) {
      return [const Text("Loading...")];
    }
    final List<dynamic> commonSentences = _planData!.materialSnapshot.sentences;

    return commonSentences.map((sentence) {
      return Text.rich(
        TextSpan(
          text: sentence,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.dotted,
            decorationThickness: 1,
            height: 2,
            letterSpacing: 0.50,
          ),
        ),
      );
    }).toList();
  }

  /// 构建核心语法
  Widget _buildKeyGrammar() {
    if (_planData == null) {
      return const Text("Loading...");
    }
    final List<dynamic> keyGrammar = _planData!.materialSnapshot.grammars;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 12,
      children: keyGrammar.map((grammar) {
        return Text(
          grammar,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        );
      }).toList(),
    );
  }

  /// 正常数据状态
  Widget _buildDataState() {
    final int currentLevel = _planData!.level;
    final String topicTag = _planData!.topicTitle!;
    final double progress = calculatePlanProgress(_planData);
    final planProvider = Provider.of<PlanProvider>(context, listen: false);
    if (progress == 1) {
      planProvider.completeActivePlan();
    }
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 100, 24, 120),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          spacing: 24,
          children: [
            /// 标题与进度卡片
            Column(
              spacing: 16,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Keep Advancing Your Goal',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                FeedbackButton(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _gotoPagePlan,
                  child: Ink(
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          width: 1,
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: ShapeDecoration(
                              color: const Color(0xFFFF9500),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'HSK $currentLevel',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            topicTag,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          LinearProgressIndicator(
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(10),
                            value: progress,
                            color: theme.colorScheme.primary,
                            backgroundColor: theme.colorScheme.primary
                                .withAlpha(40),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            /// 计划全部完成
            if (progress == 1)
              Container(
                padding: EdgeInsets.all(24),
                // width: double.infinity,
                decoration: ShapeDecoration(
                  // color: theme.highlightColor,
                  color: Colors.amber[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 24,
                  children: [
                    Icon(
                      Icons.celebration_rounded,
                      color: Colors.white,
                      size: 80.0,
                    ),
                    Text(
                      "Congratulations! \n You have completed the goal!",
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Wrap(
                      // crossAxisAlignment: CrossAxisAlignment.stretch,
                      // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 20,
                      runSpacing: 20,
                      runAlignment: WrapAlignment.spaceEvenly,
                      alignment: WrapAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size.square(48),
                            side: BorderSide(
                              width: 0,
                              color: theme.colorScheme.secondary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: _gotoPagePlan,
                          icon: Icon(
                            Icons.list,
                            color: theme.colorScheme.secondary,
                          ),
                          label: Text(
                            "View Your All Goals",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size.square(48),
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            planProvider.createPlan();
                          },
                          icon: Icon(
                            Icons.golf_course,
                            color: Colors.amber[800],
                          ),
                          label: Text(
                            "Start a New Goal",
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: Colors.amber[800],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            /// 活动卡片模块
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: 16,
                runSpacing: 16,
                children: [
                  Row(
                    children: [
                      Text(
                        'Practices',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      Spacer(),
                      Text(
                        'score: ${(_planData!.practiceData!.fold<double>(0, (s, p) => (s + p.score)) / _planData!.practiceData!.length * 100).toStringAsFixed(1)}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                          // fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                  ..._buildActivityCards(context),
                ],
              ),
            ),

            /// 关键笔记模块
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 16,
              children: [
                const Divider(),
                Text(
                  'Key Notes',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                // 目标词汇
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
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
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    _buildTargetWords(),
                  ],
                ),
                // 常用句子
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: ShapeDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer.withAlpha(40),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Common Sentences',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    ..._buildCommonSentences(),
                  ],
                ),
                // 核心语法
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 10,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: ShapeDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            width: 1,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer.withAlpha(40),
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'key Grammar Points',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    _buildKeyGrammar(),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: theme.colorScheme.surfaceContainerHigh,
      body: Consumer<PlanProvider>(
        builder: (context, planProvider, child) {
          _planData = planProvider.activePlan;
          if (planProvider.isLoading) {
            return _buildLoadingState(planProvider);
          }
          if (planProvider.errorMessage != null) {
            return _buildErrorState(planProvider);
          }
          if (_planData == null) {
            return _buildCreateState(planProvider);
          } else {
            return _buildDataState();
          }
        },
      ),
    );
  }

  /// 加载中状态
  Widget _buildLoadingState(PlanProvider planProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeCap: StrokeCap.round,
            backgroundColor: theme.colorScheme.secondaryContainer,
          ),
          const SizedBox(height: 20),
          Text(
            planProvider.loadingMessage ?? "Loading...",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  /// 错误状态
  Widget _buildErrorState(PlanProvider planProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 50.0),
          const SizedBox(height: 20),
          Text(
            planProvider.errorMessage ?? "Loading Failed, Please Try Again.",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 20),
          if (planProvider.retryFunc != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
              onPressed: () {
                planProvider.retryFunc!();
              },
              child: Text(
                planProvider.retryLabel ?? "Retry",
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 无可用计划状态
  Widget _buildCreateState(PlanProvider planProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 12,
        children: [
          Icon(
            Icons.celebration_rounded,
            color: theme.colorScheme.primary,
            size: 60,
          ),
          const SizedBox(height: 20),
          Text(
            "Your have no Active Goal yet.",
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(180, 40),
              backgroundColor: theme.colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            onPressed: () async {
              planProvider.createPlan();
            },
            child: Text(
              "Create a New Goal",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
          OutlinedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(180, 40),
              side: BorderSide(width: 1, color: theme.colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
            ),
            onPressed: _gotoPagePlan,
            child: Text(
              "View Your All Goals",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
