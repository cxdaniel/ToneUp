import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:toneup_app/components/quiz_choice_widget.dart';
import 'package:toneup_app/providers/evaluation_provider.dart';
import 'package:toneup_app/providers/quiz_provider.dart';
import 'package:toneup_app/providers/tts_provider.dart';
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
    final int targetLevel = extra['level'];
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            Icon(
              Icons.check_circle,
              color: theme.extension<AppThemeExtensions>()?.statePass,
              size: 80,
            ),
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
                      _submitHandeller();
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
  Future<void> _submitHandeller() async {
    setState(() {
      _isSubmitting = true;
    });
    try {
      await evaluationProvider.submitPracticeResult();
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
