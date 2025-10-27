import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:toneup_app/components/quiz_choice_widget.dart';
import 'package:toneup_app/models/user_practice_model.dart';
import 'package:toneup_app/models/user_weekly_plan_model.dart';
import 'package:toneup_app/providers/quiz_provider.dart';
import 'package:toneup_app/providers/tts_provider.dart';
import '../providers/practice_provider.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  bool _isSubmitting = false;
  late TTSProvider ttsProvider;
  late ThemeData theme;

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
    final UserPracticeModel practiceData = extra['practiceData'];
    final UserWeeklyPlanModel planData = extra['planData'];
    final String topic = planData.materialSnapshot.topicTag;
    final String culture = planData.materialSnapshot.cultureTag;
    debugPrint('PagePractice: ${MediaQuery.of(context).viewPadding}');
    return ChangeNotifierProvider(
      create: (ctx) =>
          PracticeProvider()
            ..initialize(practiceData, planData, topic, culture),
      child: Consumer<PracticeProvider>(
        builder: (ctx, practiceProvider, _) {
          final quizzes = practiceProvider.quizzes;
          return Scaffold(
            appBar: (!practiceProvider.isPracticeCompleted)
                ? AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: context.pop,
                    ),
                    title: LinearProgressIndicator(
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(10),
                      value: practiceProvider.progress,
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
                (practiceProvider.isLoading) // 加载中状态
                ? _buildLoadingState()
                : (practiceProvider.errorMessage != null) // 错误状态
                ? _buildErrorState(practiceProvider)
                : (practiceProvider.isPracticeCompleted) // 完成状态
                ? _buildFinishedState(practiceProvider)
                : (quizzes.isEmpty) //无题状态
                ? _buildEmptyState()
                : _buildDataState(practiceProvider), //正常数据状态
          );
        },
      ),
    );
  }

  /// 加载中状态
  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        strokeCap: StrokeCap.round,
        backgroundColor: theme.colorScheme.secondaryContainer,
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
            'Practice is Empty',
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
  Widget _buildDataState(PracticeProvider provider) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        final isNewChild = child.key == ValueKey(provider.currentTouchedCount);
        final inOffset = const Offset(1.0, 0.0); //从右进入
        final outOffset = const Offset(-1.0, 0.0); // 往左出
        final inAnimation = Tween<Offset>(begin: inOffset, end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOutQuad),
            ); // 入场动画
        final outAnimation = Tween<Offset>(begin: Offset.zero, end: outOffset)
            .animate(
              CurvedAnimation(
                parent: ReverseAnimation(animation),
                curve: Curves.easeOutQuad,
              ),
            ); // 出场动画
        return SlideTransition(
          position: isNewChild ? inAnimation : outAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: ChangeNotifierProvider(
        key: ValueKey(provider.currentTouchedCount),
        create: (context) => QuizProvider()..initQuiz(provider.currentQuiz),
        child: QuizChoiceWidget(),
      ),
    );
  }

  /// 错误状态
  Widget _buildErrorState(PracticeProvider practiceProvider) {
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
              'Loading failed: ${practiceProvider.errorMessage}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            if (practiceProvider.retryFunc != null || true)
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
                onPressed: practiceProvider.retryFunc,
                child: Text(
                  practiceProvider.retryLabel ?? "Retry",
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

  /// 练习完成状态
  Widget _buildFinishedState(PracticeProvider practiceProvider) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            Text(
              'Practice Completed!',
              style: theme.textTheme.headlineSmall!.copyWith(
                color: theme.colorScheme.secondary,
                // fontWeight: FontWeight.w300,
              ),
            ),
            TextButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(120, 48),
                backgroundColor: theme.colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: _isSubmitting
                  ? null
                  : () {
                      HapticFeedback.heavyImpact();
                      _submitHandeller(practiceProvider);
                    },
              child: _isSubmitting
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Submiting...',
                          style: theme.textTheme.titleMedium!.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Submit',
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// 提交练习结果
  Future<void> _submitHandeller(PracticeProvider provider) async {
    setState(() {
      _isSubmitting = true;
    });
    try {
      await provider.submitPracticeResult();
      if (mounted) {
        context.pop();
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
