import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toneup_app/components/chars_with_pinyin.dart';
import 'package:toneup_app/components/feedback_button.dart';
import 'package:toneup_app/components/wave_animation.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/quizzes/quiz_model.dart';
import 'package:toneup_app/models/quizzes/quiz_options_model.dart';
import 'package:toneup_app/providers/quiz_provider.dart';
import 'package:toneup_app/providers/tts_provider.dart';
import '../providers/practice_provider.dart';

/// Quiz 答题页面：展示单个练习实例的具体题目和答题交互
class QuizChoiceWidget extends StatefulWidget {
  const QuizChoiceWidget({super.key});
  @override
  State<QuizChoiceWidget> createState() => _QuizChoiceWidgetState();
}

class _QuizChoiceWidgetState extends State<QuizChoiceWidget> {
  late QuizChoice quiz;
  dynamic voicePosition;

  @override
  void initState() {
    super.initState();
    final tts = Provider.of<TTSProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      final quiz = quizProvider.quiz as QuizChoice;
      if (quiz.actInstance.activity!.quizTemplate == QuizTemplate.voiceToText) {
        voicePosition = quiz.material;
        tts.play(quiz.material.voice);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizProvider = Provider.of<QuizProvider>(context);
    quiz = quizProvider.quiz as QuizChoice;
    return Consumer<QuizProvider>(
      builder: (ctx, quizProvider, _) {
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 24,
                children: [
                  Text(quizProvider.quiz.actInstance.id.toString()),

                  /// 题干区域 //////////////////////////////////////////////////
                  _buildMaterial(quizProvider, quiz),

                  /// 题问区 ////////////////////////////////////////////////////
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          if (quiz.isRenewal)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: ShapeDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    width: 1,
                                    strokeAlign: BorderSide.strokeAlignCenter,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondaryFixedDim,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                'Renewal',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSecondaryContainer,
                                    ),
                              ),
                            ),
                          Text(
                            '${quiz.actInstance.activity!.quizTemplate.name}: ${quiz.question}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  /// 选项区 ////////////////////////////////////////////////////
                  _buildQuizOptions(quizProvider, quiz),

                  /// 底部安全距离 ///////////////////////////////////////////////
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 60),
                    ),
                  ),
                  // const SizedBox(height: 60),
                ],
              ),
            ),

            /// 反馈区 //////////////////////////////////////////////////////////
            if (quizProvider.state != QuizState.intouch &&
                quizProvider.state != QuizState.initial)
              _buildFeedbackBoard(quizProvider, quiz),
          ],
        );
      },
    );
  }

  /// 题干区工具条
  Widget _buildMaterialTools(QuizProvider provider, QuizChoice quiz) {
    if (quiz.actInstance.activity!.quizTemplate == QuizTemplate.textToVoice) {
      return SizedBox.shrink();
    }
    final tts = context.watch<TTSProvider>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 8,
      children: [
        IconButton(
          iconSize: 24,
          padding: EdgeInsets.all(0),
          // constraints: BoxConstraints.tight(Size.square(24)),
          style: IconButton.styleFrom(
            backgroundColor:
                (tts.state == TTSState.playing &&
                    voicePosition == quiz.material)
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.secondaryContainer,
          ),
          color:
              (tts.state == TTSState.playing && voicePosition == quiz.material)
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.primary,
          icon: Icon(Icons.volume_up_rounded),
          onPressed: () {
            voicePosition = quiz.material;
            tts.play(quiz.material.voice);
          },
        ),
        Row(
          spacing: 4,
          children: [
            OutlinedButton.icon(
              label: Text('Pinyin'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.secondaryFixedDim,
                ),
                // minimumSize: Size(0, 32),
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: Icon(size: 20, Icons.bubble_chart_outlined),
              //TODO: 点击拼音显示逻辑
              onPressed: () {},
            ),
            OutlinedButton.icon(
              label: Text('1.0x'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).colorScheme.secondaryFixedDim,
                ),
                // minimumSize: Size(0, 32),
                padding: EdgeInsets.symmetric(horizontal: 12),
              ),
              icon: Icon(size: 20, Icons.speed),
              //TODO: 点击切换速度逻辑
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }

  /// 构建题干区
  Widget _buildMaterial(QuizProvider provider, QuizChoice quiz) {
    switch (quiz.actInstance.activity!.quizTemplate) {
      case QuizTemplate.voiceToText: //听音选文
        return _voiceToTextMaterial(provider, quiz);
      default:
        return _textToTextMaterial(provider, quiz);
    }
  }

  /// 题干组件-文本选文本
  Widget _textToTextMaterial(QuizProvider provider, QuizChoice quiz) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFF7F2FA) /* Schemes-Surface-Container-Low */,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          _buildMaterialTools(provider, quiz),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 110),
            child: Wrap(
              alignment: WrapAlignment.start,
              runAlignment: WrapAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: quiz.material.text.split('').map<Widget>((char) {
                return CharsWithPinyin(chinese: char, size: 48);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 题干组件-听音选文本
  Widget _voiceToTextMaterial(QuizProvider provider, QuizChoice quiz) {
    final tts = context.watch<TTSProvider>();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: const Color(0xFFF7F2FA) /* Schemes-Surface-Container-Low */,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          _buildMaterialTools(provider, quiz),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 80),
            child: Center(
              child: WaveAnimation(
                isPlaying: tts.state == TTSState.playing,
                isLoading: tts.state == TTSState.loading,
                size: Size(320, 40),
                barWidth: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建选项组件
  Widget _buildQuizOptions(QuizProvider provider, QuizChoice quiz) {
    switch (quiz.actInstance.activity!.quizTemplate) {
      case QuizTemplate.textToText: //看文选文
        return _textToTextOptions(provider, quiz);
      case QuizTemplate.textToVoice: //看文选音
        return _textToVoiceOptions(provider, quiz);
      default: //看文选文
        return _textToTextOptions(provider, quiz);
    }
  }

  /// 选项组件-文本选文本
  Widget _textToTextOptions(QuizProvider provider, QuizChoice quiz) {
    return Column(
      spacing: 16,
      children: quiz.options.map<Widget>((option) {
        return FeedbackButton(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            provider.updateAnswer(option);
          },
          child: Ink(
            decoration: ShapeDecoration(
              color: option.state == OptionStatus.pass
                  ? Color(0xFFD1E2C8)
                  : option.state == OptionStatus.fail
                  ? Color(0xFFFFD8E4)
                  : option.state == OptionStatus.select
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                spacing: 4,
                children: [
                  option.state == OptionStatus.pass
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF4A6B38),
                        )
                      : option.state == OptionStatus.fail
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF7D5260),
                        )
                      : option.state == OptionStatus.select
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryFixedDim,
                        ),
                  Text(
                    option.text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: option.state == OptionStatus.pass
                          ? Color(0xFF4A6B38)
                          : option.state == OptionStatus.fail
                          ? Color(0xFF7D5260)
                          : option.state == OptionStatus.select
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 选项组件-看文本选音
  Widget _textToVoiceOptions(QuizProvider provider, QuizChoice quiz) {
    final tts = context.watch<TTSProvider>();
    return Column(
      spacing: 16,
      children: quiz.options.map<Widget>((option) {
        return FeedbackButton(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            provider.updateAnswer(option);
            voicePosition = option;
            tts.play(option.voice);
          },
          child: Ink(
            decoration: ShapeDecoration(
              color: option.state == OptionStatus.pass
                  ? Color(0xFFD1E2C8)
                  : option.state == OptionStatus.fail
                  ? Color(0xFFFFD8E4)
                  : option.state == OptionStatus.select
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerLowest,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                spacing: 4,
                children: [
                  option.state == OptionStatus.pass
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF4A6B38),
                        )
                      : option.state == OptionStatus.fail
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF7D5260),
                        )
                      : option.state == OptionStatus.select
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryFixedDim,
                        ),
                  Text(
                    option.text,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: option.state == OptionStatus.pass
                          ? Color(0xFF4A6B38)
                          : option.state == OptionStatus.fail
                          ? Color(0xFF7D5260)
                          : option.state == OptionStatus.select
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Spacer(),
                  WaveAnimation(
                    isPlaying:
                        tts.state == TTSState.playing &&
                        voicePosition == option,
                    isLoading:
                        tts.state == TTSState.loading &&
                        voicePosition == option,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 题目解析反馈区
  Widget _buildFeedbackBoard(QuizProvider provider, QuizChoice quiz) {
    final practiceProvider = Provider.of<PracticeProvider>(
      context,
      listen: false,
    );
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        // padding: EdgeInsets.all(24),
        padding: EdgeInsets.fromLTRB(24, 24, 24, 48),
        decoration: ShapeDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
        child: Column(
          spacing: 16,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 答案反馈
            if (provider.state == QuizState.fail)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  Text(
                    'Not quite right',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Color(0xFFFFD8E4),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    provider.feedbackMessage,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ), // Color(0xFFFFD8E4)
                  ),
                ],
              )
            else if (provider.state == QuizState.pass)
              Column(
                spacing: 16,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Awesome!',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Color(0xFFB7EC9B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    provider.feedbackMessage,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            // 提交/重试按钮（根据状态动态变化）
            if (provider.state == QuizState.touched)
              ElevatedButton(
                onPressed: () =>
                    _handleSubmit(quiz, practiceProvider, provider),
                child: const Text('提交答案'),
              )
            else if (provider.state == QuizState.fail &&
                quiz.retryCount < quiz.maxRetryTime)
              ElevatedButton(
                onPressed: () => provider.retry(),
                child: const Text('重新答题'),
              )
            else
              ElevatedButton(
                onPressed: () => practiceProvider.nextQuiz(),
                child: const Text('继续'),
              ),
          ],
        ),
      ),
    );
  }

  /// 处理答案提交
  void _handleSubmit(
    QuizBase quiz,
    PracticeProvider practiceProvider,
    QuizProvider quizProvider,
  ) {
    quizProvider.submitAnswer();
    practiceProvider.markQuizResult(quiz);
  }
}
