import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:toneup_app/components/feedback_button.dart';
import 'package:toneup_app/components/quiz_choice_widget.dart';
import 'package:toneup_app/providers/evaluation_provider.dart';
import 'package:toneup_app/providers/quiz_provider.dart';
import 'package:toneup_app/providers/tts_provider.dart';
import 'package:toneup_app/routes.dart';
import 'package:toneup_app/theme_data.dart';

class EvaluationPage extends StatefulWidget {
  const EvaluationPage({super.key});

  @override
  State<EvaluationPage> createState() => _EvaluationPageState();
}

class _EvaluationPageState extends State<EvaluationPage> {
  bool _isSubmitting = false;
  late TTSProvider ttsProvider;
  late ThemeData theme;
  late EvaluationProvider evaluationProvider;
  late int targetLevel;

  @override
  void initState() {
    super.initState();
    ttsProvider = Provider.of<TTSProvider>(context, listen: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  void dispose() {
    try {
      ttsProvider.stop();
    } catch (e) {
      debugPrint('tts dispose::::,$e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>;
    targetLevel = extra['level'];
    return ChangeNotifierProvider(
      create: (ctx) => EvaluationProvider()..initialize(targetLevel),
      child: Consumer<EvaluationProvider>(
        builder: (ctx, provider, _) {
          evaluationProvider = provider;
          final quizzes = provider.quizzes;
          return Scaffold(
            appBar: (!provider.isPracticeCompleted)
                ? AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: context.pop,
                    ),
                    title: LinearProgressIndicator(
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                      value: provider.progress,
                      backgroundColor: theme.colorScheme.primary.withAlpha(40),
                    ),
                    actionsPadding: EdgeInsets.symmetric(horizontal: 16),
                    actions: [Icon(Icons.more_horiz)],
                    backgroundColor: theme.colorScheme.surface,
                    surfaceTintColor: theme.colorScheme.secondary,
                    shadowColor: theme.colorScheme.surfaceContainerLowest,
                    scrolledUnderElevation: 1,
                  )
                : null,
            body:
                (provider.isLoading) // 加载中状态
                ? _buildLoadingState()
                : (provider.errorMessage != null) // 错误状态
                ? _buildErrorState()
                : (provider.isPracticeCompleted) // 完成状态
                ? _buildFinishedState()
                : (quizzes.isEmpty) //无题状态
                ? _buildEmptyState()
                : _buildDataState(), //正常数据状态
          );
        },
      ),
    );
  }

  /// 加载中状态
  Widget _buildLoadingState() {
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
            'Preparing practice...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  /// 无题状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 20,
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            color: theme.colorScheme.surfaceDim,
            size: 50.0,
          ),
          Text(
            'Evaluation is Empty',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor: theme.colorScheme.surfaceDim,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: context.pop,
            child: Text(
              "Back",
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 正常数据状态
  Widget _buildDataState() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        final isNewChild =
            child.key == ValueKey(evaluationProvider.currentTouchedCount);
        final inOffset = const Offset(1.0, 0.0); //从右进入
        final outOffset = const Offset(-1.0, 0.0); // 往左出
        final inAnimation = Tween<Offset>(begin: inOffset, end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn),
            ); // 入场动画
        final outAnimation =
            Tween<Offset>(
                  begin: Offset.zero,
                  end: outOffset,
                ) //Curves.fastOutSlowIn
                .animate(
                  CurvedAnimation(
                    parent: ReverseAnimation(animation),
                    curve: Curves.fastOutSlowIn,
                  ),
                ); // 出场动画
        return SlideTransition(
          position: isNewChild ? inAnimation : outAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: ChangeNotifierProvider(
        key: ValueKey(evaluationProvider.currentTouchedCount),
        create: (context) =>
            QuizProvider()..initQuiz(evaluationProvider.currentQuiz),
        child: QuizChoiceWidget(callNextQuiz: nextQuiz),
      ),
    );
  }

  /// 错误状态
  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 20,
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 50.0,
            ),
            Text(
              'Loading failed: ${evaluationProvider.errorMessage}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (evaluationProvider.retryFunc != null || true)
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  disabledBackgroundColor: theme.colorScheme.surfaceDim,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: evaluationProvider.retryFunc,
                child: Text(
                  evaluationProvider.retryLabel ?? "Retry",
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 下一题
  void nextQuiz() {
    ttsProvider.stop();
    evaluationProvider.nextQuiz();
  }

  /// 练习完成状态
  Widget _buildFinishedState() {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: evaluationProvider.score > .8
              ? _resultExcellent()
              : evaluationProvider.score > .25
              ? _resultPass()
              : _resultFail(),
        ),
      ),
    );
  }

  Widget _resultPass() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 60,
      children: [
        Icon(
          Icons.thumb_up_alt_rounded,
          color: theme.extension<AppThemeExtensions>()?.statePassOnPrimary,
          size: 80,
        ),
        Column(
          spacing: 24,
          children: [
            Text(
              'Perfect Match!',
              style: theme.textTheme.headlineLarge!.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Righteous',
              ),
            ),
            Text(
              'Warm-up Result',
              style: theme.textTheme.titleLarge!.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            _scoreProgress(),
            Text(
              'Awesome! Your level fits like a glove~ Click “Let’s Start Now” to dive into your Chinese learning journey!',
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        _actButton(
          iconRight: Icons.arrow_right_alt_rounded,
          label: 'Let\'s Start Now',
          waiting: 'Creating your Goal ...',
          onTap: _confirmToStart,
        ),
      ],
    );
  }

  Widget _resultFail() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 60,
      children: [
        Icon(
          Icons.heart_broken_rounded,
          color: theme.extension<AppThemeExtensions>()?.stateFailOnPrimary,
          size: 80,
        ),
        Column(
          spacing: 24,
          children: [
            Text(
              'Take It Step by Step',
              style: theme.textTheme.headlineLarge!.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Righteous',
              ),
            ),
            Text(
              'Warm-up Result',
              style: theme.textTheme.titleLarge!.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            _scoreProgress(),
            Text(
              'Don’t sweat it~ This level is a bit of a stretch right now.  We’d suggest going back to pick a lower level. Laying a solid foundation first will make your learning journey way smoother!',
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        _actButton(
          iconLeft: Icons.arrow_back_rounded,
          label: 'Back to Choose Another Level',
          onTap: () {
            context.pop();
          },
        ),
      ],
    );
  }

  Widget _resultExcellent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 60,
      children: [
        Icon(
          Icons.switch_access_shortcut_add_rounded,
          color: theme.extension<AppThemeExtensions>()?.exp,
          size: 80,
        ),
        Column(
          spacing: 24,
          children: [
            Text(
              'Level Up Ready!',
              style: theme.textTheme.headlineLarge!.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
                fontFamily: 'Righteous',
              ),
            ),
            Text(
              'Warm-up Result',
              style: theme.textTheme.titleLarge!.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            _scoreProgress(),
            Text(
              'Wow! You crushed this level—you’re totally primed for a bigger challenge~ Head back to choose a higher level and keep leveling up your Chinese skills!',
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Column(
          spacing: 16,
          children: [
            _actButton(
              iconLeft: Icons.arrow_back_rounded,
              label: 'Back to Another Level',
              onTap: () {
                context.pop();
              },
            ),
            _actButton(
              iconRight: Icons.arrow_right_alt_rounded,
              label: 'Start with Level HSK $targetLevel',
              waiting: 'Creating your Goal ...',
              onTap: _confirmToStart,
            ),
          ],
        ),
      ],
    );
  }

  ///  分数进度条
  Widget _scoreProgress() {
    return SizedBox(
      width: 240,
      child: Stack(
        children: [
          LinearProgressIndicator(
            value: evaluationProvider.score,
            minHeight: 20,
            borderRadius: BorderRadius.circular(20),
            color: theme.extension<AppThemeExtensions>()!.exp,
            backgroundColor: theme.colorScheme.surfaceContainerHigh,
            // backgroundColor: theme.colorScheme.primary.withAlpha(40),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: 240 * 0.25),
              if (targetLevel != 1)
                SizedBox(
                  width: 0,
                  height: 20,
                  child: VerticalDivider(
                    thickness: 2,
                    color: theme.colorScheme.surface,
                  ),
                ),
              SizedBox(width: 240 * 0.55),
              if (targetLevel != 9)
                SizedBox(
                  width: 0,
                  height: 20,
                  child: VerticalDivider(
                    thickness: 2,
                    color: theme.colorScheme.surface,
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24, left: 4, right: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  targetLevel == 1 ? '' : 'HSK ${targetLevel - 1}',
                  style: theme.textTheme.labelMedium!.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'HSK $targetLevel',
                  style: theme.textTheme.labelMedium!.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  targetLevel == 9 ? '' : 'HSK ${targetLevel + 1}',
                  style: theme.textTheme.labelMedium!.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 行动按钮
  Widget _actButton({
    required String label,
    required VoidCallback onTap,
    IconData? iconRight,
    IconData? iconLeft,
    waiting = 'Waiting...',
  }) {
    // _isSubmitting = false;
    return FeedbackButton(
      borderRadius: BorderRadius.circular(24),
      onTap: _isSubmitting
          ? null
          : () {
              HapticFeedback.mediumImpact();
              onTap();
            },
      child: Ink(
        padding: EdgeInsets.all(12),
        decoration: ShapeDecoration(
          color: _isSubmitting
              ? theme.colorScheme.secondaryContainer
              : theme.colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(24),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 12,
          children: [
            iconLeft != null
                ? Icon(iconLeft, size: 24, color: theme.colorScheme.onPrimary)
                : SizedBox(width: 10),
            Text(
              _isSubmitting ? waiting : label,
              style: theme.textTheme.titleMedium!.copyWith(
                color: _isSubmitting
                    ? theme.colorScheme.onSecondaryContainer
                    : theme.colorScheme.onPrimary,
              ),
            ),
            _isSubmitting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.secondary,
                    ),
                  )
                : iconRight != null
                ? Icon(iconRight, size: 24, color: theme.colorScheme.onPrimary)
                : SizedBox(width: 10),
          ],
        ),
      ),
    );
  }

  /// 确定级别
  Future<void> _confirmToStart() async {
    setState(() {
      _isSubmitting = true;
    });
    try {
      await evaluationProvider.createProfileAndGoal(targetLevel);
      if (mounted) {
        context.go(AppRoutes.HOME);
      }
    } catch (e) {
      // 处理错误，如显示错误提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败: ${e.toString()}'),
            showCloseIcon: true,
            // duration: Durations.long4,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
