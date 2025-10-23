import 'package:flutter/material.dart';
import 'package:toneup_app/components/feedback_button.dart';
import 'package:toneup_app/models/quizzes/quiz_model.dart';
import 'package:toneup_app/providers/practice_provider.dart';
import 'package:toneup_app/providers/quiz_provider.dart';

class QuizFeedbackBoard extends StatelessWidget {
  final QuizProvider quizProvider;
  final PracticeProvider practiceProvider;
  final ThemeData theme;

  const QuizFeedbackBoard({
    super.key,
    required this.quizProvider,
    required this.practiceProvider,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 48), // 保持原padding
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 答案反馈文本（原逻辑不变）
          if (quizProvider.state == QuizState.fail)
            _buildFailFeedback(theme, quizProvider)
          else if (quizProvider.state == QuizState.pass)
            _buildPassFeedback(theme, quizProvider),
          // 2. 底部行动按钮
          _buildActionButton(
            theme: theme,
            quizProvider: quizProvider,
            practiceProvider: practiceProvider,
            context: context,
          ),
        ],
      ),
    );
  }

  /// 错误反馈
  Widget _buildFailFeedback(ThemeData theme, QuizProvider quizProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        Row(
          spacing: 10,
          children: [
            Icon(
              Icons.sentiment_very_dissatisfied,
              color: Color(0xFFFFD8E4),
              size: 32,
            ),
            Text(
              'Not quite right',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Color(0xFFFFD8E4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          quizProvider.feedbackMessage,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ), // Color(0xFFFFD8E4)
        ),
      ],
    );
  }

  /// 正确反馈
  Widget _buildPassFeedback(ThemeData theme, QuizProvider quizProvider) {
    return Column(
      spacing: 16,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: 10,
          children: [
            Icon(
              Icons.sentiment_very_satisfied,
              color: Color(0xFFB7EC9B),
              size: 32,
            ),
            Text(
              'Awesome!',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Color(0xFFB7EC9B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          quizProvider.feedbackMessage,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  /// 底部行动按钮
  Widget _buildActionButton({
    required ThemeData theme,
    required QuizProvider quizProvider,
    required PracticeProvider practiceProvider,
    required BuildContext context,
  }) {
    String label;
    IconData icon;
    VoidCallback? onTap;
    if (quizProvider.state == QuizState.fail &&
        quizProvider.quiz.retryCount < quizProvider.quiz.maxRetryTime) {
      label = 'Retry';
      icon = Icons.replay_rounded;
      onTap = () {
        quizProvider.retry();
        Navigator.pop(context);
      };
    } else {
      label = 'Continue';
      icon = Icons.arrow_right_alt_rounded;
      onTap = () {
        practiceProvider.nextQuiz();
        Navigator.pop(context);
      };
    }
    return Material(
      color: Colors.transparent,
      child: FeedbackButton(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: ShapeDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              Icon(icon, color: theme.colorScheme.onPrimaryContainer),
              Text(
                label,
                style: theme.textTheme.titleMedium!.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
