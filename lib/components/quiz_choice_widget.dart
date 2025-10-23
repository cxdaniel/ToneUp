import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:toneup_app/components/chars_with_pinyin.dart';
import 'package:toneup_app/components/feedback_button.dart';
import 'package:toneup_app/components/quiz_feedback_board.dart';
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

enum ColorState { fill, border, above }

class _QuizChoiceWidgetState extends State<QuizChoiceWidget> {
  dynamic voicePosition;
  bool _isBottomSheetShowing = false;
  late QuizChoice quiz;
  late QuizProvider quizProvider;
  late PracticeProvider practiceProvider;
  late ThemeData theme;
  late TTSProvider tts;
  late Map<ColorState, Color> colorPass;
  late Map<ColorState, Color> colorFail;
  late Map<ColorState, Color> colorSelect;
  late Map<ColorState, Color> colorIdle;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
    tts = context.watch<TTSProvider>();

    colorPass = {
      ColorState.fill: Color(0xFFD1E2C8),
      ColorState.border: Color(0x28496A38),
      ColorState.above: Color(0xFF4A6B38),
    };
    colorFail = {
      ColorState.fill: theme.colorScheme.tertiaryContainer, //0xFFFFD8E4
      ColorState.border: Color(0x286750A4),
      ColorState.above: Color(0xFF7D5260),
    };
    colorSelect = {
      ColorState.fill: theme.colorScheme.primaryContainer, //0xFFEADDFF
      ColorState.border: Color(0x286750A4),
      ColorState.above: theme.colorScheme.onPrimaryContainer, //0xFF4F378A,
    };
    colorIdle = {
      ColorState.fill: theme.colorScheme.surfaceContainerLowest, //White
      ColorState.border: Colors.transparent,
      ColorState.above: theme.colorScheme.primary, //0xFF6750A4,
    };
  }

  @override
  void initState() {
    super.initState();
    practiceProvider = Provider.of<PracticeProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      tts = Provider.of<TTSProvider>(context, listen: false);
      quizProvider = Provider.of<QuizProvider>(context, listen: false);
      quiz = quizProvider.quiz as QuizChoice;
      if (quiz.actInstance.activity!.quizTemplate == QuizTemplate.voiceToText) {
        voicePosition = quiz.material;
        tts.play(quiz.material.voice);
      }
    });
  }

  /// 弹出反馈面板
  void _showFeedbackBottomSheet({
    required BuildContext context,
    required QuizProvider quizProvider,
    required PracticeProvider practiceProvider,
  }) {
    _isBottomSheetShowing = true;
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: theme.colorScheme.primary,
      barrierColor: theme.colorScheme.inverseSurface.withAlpha(50),
      builder: (context) => QuizFeedbackBoard(
        quizProvider: quizProvider,
        practiceProvider: practiceProvider,
        theme: theme,
      ),
    ).whenComplete(() {
      _isBottomSheetShowing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = kToolbarHeight;
    double statusBarHeight = MediaQuery.of(context).viewPadding.top;
    // MediaQuery.of(context).padding.vertical +
    // MediaQuery.of(context).viewInsets.vertical;

    // final appBarKey = GlobalKey();
    final effectiveMinHeight = screenHeight - appBarHeight - statusBarHeight;

    debugPrint(
      'screenHeight:$screenHeight / appBarHeight:$appBarHeight / statusBarHeight: $statusBarHeight = effectiveMinHeight:$effectiveMinHeight',
    );

    return Consumer<QuizProvider>(
      builder: (ctx, provider, _) {
        quizProvider = provider;
        quiz = provider.quiz as QuizChoice;

        if ((quizProvider.state == QuizState.fail ||
                quizProvider.state == QuizState.pass) &&
            mounted &&
            !_isBottomSheetShowing) {
          Future.microtask(() {
            if (mounted) {
              _showFeedbackBottomSheet(
                context: ctx,
                quizProvider: quizProvider,
                practiceProvider: practiceProvider,
              );
            }
          });
        }
        return Stack(
          children: [
            SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.all(24),
                constraints: BoxConstraints(minHeight: effectiveMinHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 24,
                  children: [
                    _buildMaterial(quizProvider, quiz),
                    _buildQuestion(),
                    Column(
                      spacing: 24,
                      children: [
                        // 选项
                        _buildQuizOptions(quizProvider, quiz),
                        // 底部空间
                        Text(
                          'actId: ${quizProvider.quiz.actInstance.id} / ${quiz.actInstance.activity!.quizTemplate}',
                          style: theme.textTheme.labelSmall!.copyWith(
                            color: theme.colorScheme.primaryFixed,
                          ),
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutQuart,
                          child: SizedBox(
                            height:
                                (quizProvider.state != QuizState.initial &&
                                    quizProvider.state != QuizState.intouch)
                                ? 50
                                : 0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            _buildCheckButton((quizProvider.state == QuizState.touched)),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      // crossAxisAlignment: CrossAxisAlignment.end,
      spacing: 8,
      children: [
        FeedbackButton(
          onTap:
              (tts.state == TTSState.loading && voicePosition == quiz.material)
              ? null
              : () {
                  HapticFeedback.heavyImpact();
                  voicePosition = quiz.material;
                  tts.play(quiz.material.voice);
                },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 40,
            height: 40,
            padding: EdgeInsets.all(8),
            decoration: ShapeDecoration(
              color:
                  (tts.state == TTSState.playing &&
                      voicePosition == quiz.material)
                  ? theme.colorScheme.primary
                  : theme.colorScheme.secondaryContainer,
              shape: CircleBorder(),
            ),
            child:
                (tts.state == TTSState.loading &&
                    voicePosition == quiz.material)
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.primaryFixed,
                  )
                : Icon(
                    Icons.volume_up_rounded,
                    color:
                        (tts.state == TTSState.playing &&
                            voicePosition == quiz.material)
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
          ),
        ),
        Row(
          spacing: 4,
          children: [
            OutlinedButton.icon(
              label: Text('Pinyin'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.secondaryFixedDim),
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
                side: BorderSide(color: theme.colorScheme.secondaryFixedDim),
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
        color: theme.colorScheme.surfaceContainerLow,
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
                if (quiz.material.text.length < 20) {
                  return CharsWithPinyin(chinese: char, size: 48);
                } else {
                  return CharsWithPinyin(chinese: char, size: 32);
                }
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 题干组件-听音选文本
  Widget _voiceToTextMaterial(QuizProvider provider, QuizChoice quiz) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: theme
            .colorScheme
            .surfaceContainerLow, //const Color(0xFFF7F2FA) /* Schemes-Surface-Container-Low */,
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

  /// 构建题问区
  Widget _buildQuestion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        if (quiz.isRenewal)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: ShapeDecoration(
              color: theme.colorScheme.secondaryContainer,
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignCenter,
                  color: theme.colorScheme.secondaryFixedDim,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Renewal',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        Text(
          quiz.question,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
                  ? colorPass[ColorState.fill]
                  : option.state == OptionStatus.fail
                  ? colorFail[ColorState.fill]
                  : option.state == OptionStatus.select
                  ? colorSelect[ColorState.fill]
                  : colorIdle[ColorState.fill],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  width: 2,
                  color: option.state == OptionStatus.pass
                      ? colorPass[ColorState.border]!
                      : option.state == OptionStatus.fail
                      ? colorFail[ColorState.border]!
                      : option.state == OptionStatus.select
                      ? colorSelect[ColorState.border]!
                      : colorIdle[ColorState.border]!,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                spacing: 8,
                children: [
                  option.state == OptionStatus.pass
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: colorPass[ColorState.above],
                        )
                      : option.state == OptionStatus.fail
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: colorFail[ColorState.above],
                        )
                      : option.state == OptionStatus.select
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: colorSelect[ColorState.above],
                        )
                      : Icon(
                          Icons.circle_outlined,
                          color: theme.colorScheme.secondaryFixedDim,
                        ),
                  Text(
                    option.text,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: option.state == OptionStatus.pass
                          ? colorPass[ColorState.above]
                          : option.state == OptionStatus.fail
                          ? colorFail[ColorState.above]
                          : option.state == OptionStatus.select
                          ? colorSelect[ColorState.above]
                          : colorIdle[ColorState.above],
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
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerLowest,
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
                          color: theme.colorScheme.primary,
                        )
                      : Icon(
                          Icons.circle_outlined,
                          color: Theme.of(
                            context,
                          ).colorScheme.secondaryFixedDim,
                        ),
                  Text(
                    option.text,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: option.state == OptionStatus.pass
                          ? Color(0xFF4A6B38)
                          : option.state == OptionStatus.fail
                          ? Color(0xFF7D5260)
                          : option.state == OptionStatus.select
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.primary,
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

  /// 底部行动按钮
  Widget _buildCheckButton(bool isShow) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      // top: 0,
      child: AnimatedSlide(
        offset: isShow ? Offset(0, 0) : Offset(0, 1),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutQuart,
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 640),
            padding: EdgeInsets.fromLTRB(24, 24, 24, 48),
            decoration: ShapeDecoration(
              color: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: FeedbackButton(
                borderRadius: BorderRadius.circular(16),
                onTap: _handleCheckAnswer,
                child: Ink(
                  padding: EdgeInsets.all(12),
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
                      Icon(
                        Icons.rule_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      Text(
                        'Check',
                        style: theme.textTheme.titleMedium!.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 验证答案
  void _handleCheckAnswer() {
    final practiceProvider = Provider.of<PracticeProvider>(
      context,
      listen: false,
    );
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);
    quizProvider.submitAnswer();
    practiceProvider.markQuizResult(quiz);
  }
}
