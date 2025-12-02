import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:jieba_flutter/conversion/common_conversion_definition.dart';
import 'package:toneup_app/components/components.dart';
import 'package:toneup_app/components/feedback_button.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/routes.dart';
import 'package:toneup_app/services/utils.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

enum STEPS { nickname, purpose, duration, level }

class _WelcomePageState extends State<WelcomePage> {
  late PageController _pageController;
  late CarouselSliderController _sliderController;
  late ThemeData theme;
  late MediaQueryData screen;
  int _currentStep = 0;

  final nikenameCtrl = TextEditingController();

  final Map<STEPS, bool> validations = {
    STEPS.nickname: false,
    STEPS.purpose: false,
    STEPS.duration: false,
    STEPS.level: false,
  };
  void validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        validations[STEPS.nickname] = nikenameCtrl.text.length >= 2;
        break;
      case 1:
        validations[STEPS.purpose] =
            ProfileProvider().tempProfile.purpose != null;
        break;
      case 2:
        validations[STEPS.duration] =
            ProfileProvider().tempProfile.planDurationMinutes != null;
        break;
      case 3:
        validations[STEPS.level] = true;
        break;
    }
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentStep, keepPage: true);
    _sliderController = CarouselSliderController();
    nikenameCtrl.addListener(() {
      validateCurrentStep();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    nikenameCtrl.text = ProfileProvider().tempProfile.nickname ?? '';
    theme = Theme.of(context);
  }

  @override
  void dispose() {
    nikenameCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        body: LayoutBuilder(
          builder: (ctx, cons) {
            screen = MediaQueryData.fromView(View.of(ctx));
            return Padding(
              padding: EdgeInsets.only(top: screen.padding.top),
              child: PageView(
                physics: NeverScrollableScrollPhysics(),
                // physics: AlwaysScrollableScrollPhysics(),
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _sectionNickname(),
                  _sectionPurpose(),
                  _sectionDuration(),
                  _sectionLevels(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// 下一步
  void nextStep() {
    setState(() {
      FocusManager.instance.primaryFocus?.unfocus();
      _pageController.animateToPage(
        (_currentStep + 1) % 4,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  void lastStep() {
    setState(() {
      FocusManager.instance.primaryFocus?.unfocus();
      _pageController.animateToPage(
        (_currentStep - 1) % 4,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  /// 去测评
  Future<void> gotoEvaluation(int level) async {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: theme.colorScheme.primary,
      barrierColor: theme.colorScheme.shadow.withAlpha(40),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48), // 保持原padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Quick Warm-Up',
                style: theme.textTheme.titleLarge!.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              Text(
                'To make sure this level is just right for you, we’ve prepared a quick warm-up test~ After completing it, you’ll know if this level matches your actual proficiency!',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              mainActionButton(
                context: ctx,
                icon: Icons.text_snippet,
                iconAlignment: IconAlignment.end,
                label: 'Start Test',
                backColor: theme.colorScheme.primaryContainer,
                frontColor: theme.colorScheme.onPrimaryContainer,
                onTap: () {
                  Navigator.pop(ctx);
                  ctx.push(AppRoutes.EVALUATION, extra: {'level': level});
                },
              ),
            ],
          ),
        );
      },
    );
    // .whenComplete(() {
    //   debugPrint('sheet compelte....');
    // });
  }

  ///  昵称部分
  Widget _sectionNickname() {
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          minHeight:
              screen.size.height -
              screen.padding.top -
              screen.viewInsets.bottom,
        ),
        padding: EdgeInsets.fromLTRB(24, 40, 24, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 36,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Welcome to ', style: TextStyle(fontSize: 36)),
                  TextSpan(
                    text: 'ToneUp\n',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Righteous',
                      fontSize: 40,
                    ),
                  ),
                  TextSpan(
                    text: 'Start Your Chinese Journey!\n',
                    style: TextStyle(fontSize: 26),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                height: 2,
                fontWeight: FontWeight.w300,
                color: theme.colorScheme.secondary,
              ),
            ),
            Column(
              spacing: 24,
              children: [
                // AvatarUploadWidget(
                //   radius: 60,
                //   onAvatarChanged: (bytes) {
                //     ProfileProvider().avatarBytes = bytes;
                //     validateCurrentStep();
                //   },
                //   initialAvatar: ProfileProvider().avatarBytes,
                // ),
                Text.rich(
                  style: TextStyle(
                    height: 2,
                    fontWeight: FontWeight.w300,
                    color: theme.colorScheme.secondary,
                  ),
                  TextSpan(
                    text: 'Let’s start with a learning nickname',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // crossAxisAlignment: CrossAxisAlignment.center,
                  spacing: 4,
                  children: [
                    SizedBox(width: 40),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge,
                        controller: nikenameCtrl,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainer,
                          labelText: 'Nickname',
                          floatingLabelBehavior: FloatingLabelBehavior.never,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: theme.colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ),
                        maxLength: 16,
                        maxLengthEnforcement:
                            MaxLengthEnforcement.truncateAfterCompositionEnds,
                      ),
                    ),
                    FeedbackButton(
                      onTap: () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        nikenameCtrl.text = AppUtils.generateRandomNickname();
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.casino,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(),
            Column(
              spacing: 24,
              children: [
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(text: 'We will create a personalized '),
                      TextSpan(
                        text: 'Learning Profile',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          // fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(text: ' for you.'),
                    ],
                  ),
                ),
                mainActionButton(
                  context: context,
                  label: 'Continue',
                  icon: Icons.arrow_right_alt_rounded,
                  iconAlignment: IconAlignment.end,
                  onTap: validations.get(STEPS.nickname) ?? false
                      ? () {
                          ProfileProvider().tempProfile.nickname =
                              nikenameCtrl.text;
                          nextStep();
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 目的部分
  Widget _sectionPurpose() {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: lastStep,
                    label: Text('nickname'),
                    icon: Icon(Icons.arrow_back_rounded),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      enableFeedback: true,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.normal,
                        fontSize: 16,
                      ),
                      children: [
                        TextSpan(
                          text:
                              'What’s your main purpose for learning Chinese?',
                          style: TextStyle(
                            fontSize: 28,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 16,
                      children: [
                        _optionItem(
                          label: 'For Interest',
                          description:
                              'Massive fun content, from poetry to slang.',
                          selected:
                              ProfileProvider().tempProfile.purpose ==
                              PurposeType.interest,
                          onTap: () => ProfileProvider().tempProfile.purpose =
                              PurposeType.interest,
                        ),
                        _optionItem(
                          label: 'For Work',
                          description: 'Business Chinese scenario library.',
                          selected:
                              ProfileProvider().tempProfile.purpose ==
                              PurposeType.work,
                          onTap: () => ProfileProvider().tempProfile.purpose =
                              PurposeType.work,
                        ),
                        _optionItem(
                          label: 'For Travel',
                          description:
                              'Scenario-based dialogue cards offline translation.',
                          selected:
                              ProfileProvider().tempProfile.purpose ==
                              PurposeType.travel,
                          onTap: () => ProfileProvider().tempProfile.purpose =
                              PurposeType.travel,
                        ),
                        _optionItem(
                          label: 'For HSK Exam',
                          description:
                              'Break down test points review mistakes, sprint to high scores efficiently.',
                          selected:
                              ProfileProvider().tempProfile.purpose ==
                              PurposeType.exam,
                          onTap: () => ProfileProvider().tempProfile.purpose =
                              PurposeType.exam,
                        ),
                        _optionItem(
                          label: 'For Study/Life',
                          description:
                              'Essential for international students: opening a bank account, seeing a doctor, campus socializing.',
                          selected:
                              ProfileProvider().tempProfile.purpose ==
                              PurposeType.life,
                          onTap: () => ProfileProvider().tempProfile.purpose =
                              PurposeType.life,
                        ),
                        SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 60),
            color: theme.colorScheme.surface.withAlpha(200),
            child: mainActionButton(
              context: context,
              label: 'Continue',
              icon: Icons.arrow_right_alt_rounded,
              iconAlignment: IconAlignment.end,
              onTap: validations.get(STEPS.purpose) ?? false ? nextStep : null,
            ),
          ),
        ),
      ],
    );
  }

  /// 学习时长部分
  Widget _sectionDuration() {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 16,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: lastStep,
                    label: Text('main purpose'),
                    icon: Icon(Icons.arrow_back_rounded),
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      enableFeedback: true,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.normal,
                        fontSize: 16,
                      ),
                      children: [
                        TextSpan(
                          text:
                              'How much time can you spend learning each day?',
                          style: TextStyle(
                            fontSize: 28,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 16,
                      children: [
                        _optionItem(
                          label: '10 mins/day',
                          description:
                              'Perfect for fragmented time! Master core word and  practical sentence in 10 minutes~',
                          selected:
                              ProfileProvider()
                                  .tempProfile
                                  .planDurationMinutes ==
                              60,
                          onTap: () =>
                              ProfileProvider()
                                      .tempProfile
                                      .planDurationMinutes =
                                  60,
                        ),
                        _optionItem(
                          label: '20 mins/day',
                          description:
                              'Golden learning duration! Complete a full module of ‘vocabulary + grammar + dialogue’ and see progress clearly~',
                          selected:
                              ProfileProvider()
                                  .tempProfile
                                  .planDurationMinutes ==
                              100,
                          onTap: () =>
                              ProfileProvider()
                                      .tempProfile
                                      .planDurationMinutes =
                                  100,
                        ),
                        _optionItem(
                          label: '30 mins/day',
                          description:
                              'Deep learning mode! Support ‘thematic courses + extended reading’ to improve Chinese comprehensively~',
                          selected:
                              ProfileProvider()
                                  .tempProfile
                                  .planDurationMinutes ==
                              150,
                          onTap: () =>
                              ProfileProvider()
                                      .tempProfile
                                      .planDurationMinutes =
                                  150,
                        ),
                        SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 60),
            color: theme.colorScheme.surface.withAlpha(200),
            child: mainActionButton(
              context: context,
              label: 'Continue',
              icon: Icons.arrow_right_alt_rounded,
              iconAlignment: IconAlignment.end,
              onTap: validations.get(STEPS.duration) ?? false ? nextStep : null,
            ),
          ),
        ),
      ],
    );
  }

  ///  级别部分
  Widget _sectionLevels() {
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          minHeight:
              screen.size.height -
              screen.padding.top -
              screen.viewInsets.bottom,
        ),
        padding: EdgeInsets.fromLTRB(24, 12, 24, 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: lastStep,
                  label: Text('spend time each day'),
                  icon: Icon(Icons.arrow_back_rounded),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    enableFeedback: true,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.normal,
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: 'What’s your current Chinese proficiency?',
                        style: TextStyle(
                          fontSize: 28,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Text(
              'Please select the Chinese level you think you’re at. We’ll help you verify and start learning right away~',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.secondary,
              ),
            ),
            CarouselSlider(
              carouselController: _sliderController,
              disableGesture: true,
              options: CarouselOptions(
                initialPage: 0,
                autoPlayCurve: Curves.fastOutSlowIn,
                clipBehavior: Clip.none,
                height: 480,
                autoPlay: false, // 自动播放
                autoPlayInterval: const Duration(seconds: 5), // 播放间隔
                autoPlayAnimationDuration: const Duration(
                  milliseconds: 500,
                ), // 动画时长
                viewportFraction: 0.99, // 显示比例
                enlargeFactor: 0.2,
                enlargeCenterPage: true,
                enableInfiniteScroll: false, // 无限循环
                pageSnapping: true,
                disableCenter: true,
                onPageChanged: (index, reason) {
                  ProfileProvider().tempProfile.level = index + 1;
                  validateCurrentStep();
                },
              ),
              items: [
                _levelCard(
                  level: 1,
                  title: "Introductory Greeting Level",
                  example: [
                    'Can say 5 basic greetings like "你好 (Hello), 再见 (Goodbye), 谢谢 (Thank you), 对不起 (Sorry)"',
                    'Recognize less than 10 high-frequency characters like "你 (you), 好 (good), 谢 (thank), 再 (again)"',
                    'Can understand simple questions like "你叫什么名字？(What\'s your name?)"',
                  ],
                ),
                _levelCard(
                  level: 2,
                  title: "Basic Self-Intro & Daily Tasks",
                  example: [
                    'Can introduce yourself with "我叫___，我来自___" (I’m ___, I’m from ___)',
                    'Recognize numbers 1-20 and time expressions like "早上 (morning), 下午 (afternoon)"',
                    'Follow simple instructions like "请坐 (Please sit down), 打开书 (Open the book)"',
                  ],
                ),
                _levelCard(
                  level: 3,
                  title: "Daily Conversation & Life Scenarios",
                  example: [
                    'Can shop by asking "这个多少钱？(How much is this?), 我要一个___ (I want one ___)"',
                    'Talk about family, weather, and directions like "你家有几口人？(How many people are in your family?)"',
                    'Hold short conversations with 5-8 sentences on daily topics',
                  ],
                ),
                _levelCard(
                  level: 4,
                  title: "Practical Life & Social Interaction",
                  example: [
                    'Order food with "我想点一份___，不要辣 (I’d like to order ___, no spicy)"',
                    'Discuss work, school, and travel plans like "你在哪里工作？(Where do you work?)"',
                    'Understand complex sentences with conjunctions (因为… 所以…, 虽然… 但是…)',
                  ],
                ),
                _levelCard(
                  level: 5,
                  title: "Hobbies, Social Issues & Extended Reading",
                  example: [
                    'Talk about hobbies: "我喜欢看电影，周末常去电影院 (I like watching movies, I often go to the cinema on weekends)"',
                    'Discuss social topics like environmental protection, technology impact',
                    'Read and summarize 300-500 character articles on daily life',
                  ],
                ),
                _levelCard(
                  level: 6,
                  title: "Cultural Discussion & Academic Expression",
                  example: [
                    'Express opinions: "我认为___，因为___ (I think ___, because ___)"',
                    'Discuss Chinese culture (festivals, history) and global issues',
                    'Read and analyze 600-800 character essays with logical structures',
                  ],
                ),
                _levelCard(
                  level: 7,
                  title: "Professional Communication & Classical Chinese",
                  example: [
                    'Conduct business talks: "我们想和贵公司合作 (We want to cooperate with your company)"',
                    'Understand basic classical Chinese phrases like "三人行，必有我师焉 (When three people walk together, one can be my teacher)"',
                    'Write 300-500 character reports on professional topics',
                  ],
                ),
                _levelCard(
                  level: 8,
                  title: "Intercultural Communication & Advanced Writing",
                  example: [
                    'Communicate across cultures on topics like international business, education',
                    'Read and interpret academic papers or literary works in Chinese',
                    'Write 800-1000 character speeches or research summaries',
                  ],
                ),
                _levelCard(
                  level: 9,
                  title: "Near-Native Proficiency & Scholarly",
                  example: [
                    'Understand complex classical Chinese and modern literature deeply',
                    'Conduct research and write academic theses in Chinese',
                    'Engage in high-level debates on global issues with nuanced expression',
                  ],
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: [
                for (int i = 0; i < 9; i++)
                  Container(
                    width: (i == ProfileProvider().tempProfile.level! - 1)
                        ? 24
                        : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(20),
                      color: (i == ProfileProvider().tempProfile.level! - 1)
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
            Column(
              spacing: 24,
              children: [
                Text(
                  'Not sure? Start with HSK 1 and we’ll adjust based on your performance.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 选项组件
  Widget _optionItem({
    required String label,
    required String description,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      child: FeedbackButton(
        onTap: () {
          onTap();
          validateCurrentStep();
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: selected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 10,
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      description, //bodyMedium
                      style: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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

  /// 级别轮播卡片
  Widget _levelCard({
    int level = 1,
    String title = 'Title text here.',
    List<String> example = const ['descripts..'],
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: ShapeDecoration(
        color: theme.colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
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
              'HSK $level',
              style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
            ),
          ),
          Text(
            title,
            style: theme.textTheme.titleLarge!.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            'Let\'s see what you can do ➞',
            style: theme.textTheme.bodyMedium,
          ),
          Expanded(
            child: Column(
              spacing: 10,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text(
                //   'Let\'s see what you can do ➞'.padRight(2, '>>'),
                //   style: theme.textTheme.bodyMedium,
                // ),
                ...example.map((e) {
                  return Text(
                    e,
                    style: theme.textTheme.bodyLarge!.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  );
                }),
              ],
            ),
          ),
          mainActionButton(
            context: context,
            label: 'Start HSK $level',
            icon: Icons.arrow_right_alt_rounded,
            iconAlignment: IconAlignment.end,
            onTap: () => gotoEvaluation(level),
          ),
        ],
      ),
    );
  }
}
