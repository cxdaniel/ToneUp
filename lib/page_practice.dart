import 'package:carousel_slider/carousel_slider.dart';
import 'package:jieba_flutter/analysis/jieba_segmenter.dart';
import 'package:toneup_app/components/chars_with_pinyin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:toneup_app/components/quiz_choice_widget.dart';
import 'package:toneup_app/models/user_practice_model.dart';
import 'package:toneup_app/models/user_weekly_plan_model.dart';
import 'package:toneup_app/providers/quiz_provider.dart';
import 'package:toneup_app/providers/tts_provider.dart';
import 'package:toneup_app/theme_data.dart';
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
  late PracticeProvider practiceProvider;

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
        builder: (ctx, provider, _) {
          practiceProvider = provider;
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
          _buildMaterialCarousel(),
          SizedBox(height: 10),
        ],
      ),
    );
  }

  /// 加载轮播组件
  Widget _buildMaterialCarousel() {
    final tags = practiceProvider.materials.map((m) => m.content).toList();
    return CarouselSlider(
      options: CarouselOptions(
        height: 90,
        autoPlay: true, // 自动播放
        autoPlayInterval: const Duration(seconds: 3), // 播放间隔
        autoPlayAnimationDuration: const Duration(milliseconds: 500), // 动画时长
        viewportFraction: 0.8, // 显示比例
        enlargeFactor: 10,
        enlargeCenterPage: true,
        enableInfiniteScroll: true, // 无限循环
        disableCenter: true,
      ),
      items: tags.map((tag) {
        return Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: JiebaSegmenter().sentenceProcess(tag).map<Widget>((char) {
            return CharsWithPinyin(chinese: char, size: 24);
          }).toList(),
        );
      }).toList(),
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
  Widget _buildDataState() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (child, animation) {
        final isNewChild =
            child.key == ValueKey(practiceProvider.currentTouchedCount);
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
        key: ValueKey(practiceProvider.currentTouchedCount),
        create: (context) =>
            QuizProvider()..initQuiz(practiceProvider.currentQuiz),
        child: QuizChoiceWidget(),
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
