import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    ttsProvider = Provider.of<TTSProvider>(context, listen: false);
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
    // 1. 获取路由参数（此时 context 已可用，可安全调用 GoRouterState.of）
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>;
    final UserPracticeModel practiceData = extra['practiceData'];
    final UserWeeklyPlanModel planData = extra['planData'];
    final String topic = planData.materialSnapshot.topicTag;
    final String culture = planData.materialSnapshot.cultureTag;
    // 2. 通过 ChangeNotifierProvider 创建并初始化 PracticeProvider
    return ChangeNotifierProvider(
      create: (ctx) =>
          PracticeProvider()
            ..initialize(practiceData, planData, topic, culture),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        body: Consumer<PracticeProvider>(
          builder: (ctx, practiceProvider, _) {
            final quizzes = practiceProvider.quizzes;

            /// 加载状态
            if (practiceProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            /// 错误状态
            if (practiceProvider.errorMessage != null) {
              _buildErrorState(practiceProvider);
            }

            /// 练习完成状态
            if (practiceProvider.isPracticeCompleted) {
              _buildFinishedState(practiceProvider);
            }

            /// 无题状态
            if (quizzes.isEmpty) {
              return const Center(child: Text('暂无练习数据'));
            }

            /// 正常状态
            return Scaffold(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHigh,
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: context.pop,
                ),
                title: LinearProgressIndicator(
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(10),
                  value: practiceProvider.progress,
                ),
                actionsPadding: EdgeInsets.symmetric(horizontal: 16),
                actions: [Icon(Icons.more_horiz)],
              ),
              body: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                switchInCurve: Curves.easeInOut,
                // 出场 & 入场动画：根据 forward/backward 区分方向
                transitionBuilder: (child, animation) {
                  // 判断当前 child 是否是新页面
                  final isNewChild =
                      child.key ==
                      ValueKey(practiceProvider.currentTouchedCount);
                  // 不同方向的位移设置
                  final inOffset = const Offset(1.0, 0.0); //从右进入
                  final outOffset = const Offset(-1.0, 0.0); // 往左出
                  // 入场动画
                  final inAnimation =
                      Tween<Offset>(begin: inOffset, end: Offset.zero).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutQuad,
                        ),
                      );
                  // 出场动画
                  final outAnimation =
                      Tween<Offset>(begin: Offset.zero, end: outOffset).animate(
                        CurvedAnimation(
                          parent: ReverseAnimation(animation),
                          curve: Curves.easeInOutQuad,
                        ),
                      );

                  // 区分新旧页面应用不同动画
                  return SlideTransition(
                    position: isNewChild ? inAnimation : outAnimation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: ChangeNotifierProvider(
                  key: ValueKey(practiceProvider.currentTouchedCount),
                  create: (context) =>
                      QuizProvider()..initQuiz(practiceProvider.currentQuiz),
                  child: QuizChoiceWidget(),
                ),
              ),
            );
          },
        ),
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
              color: Theme.of(context).colorScheme.error,
              size: 50.0,
            ),
            Text('加载失败: ${practiceProvider.errorMessage}'),
            const SizedBox(height: 20),
            if (practiceProvider.retryFunc != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  practiceProvider.retryFunc!();
                },
                child: Text(
                  practiceProvider.retryLabel ?? "Retry",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 20),
          const Text('Practice Completed!', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () async {
                    setState(() {
                      _isSubmitting = true;
                    });
                    try {
                      await practiceProvider.submitPracticeResult();
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
                  },
            child: _isSubmitting
                ? Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                      const Text('Submiting...'),
                    ],
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }
}
