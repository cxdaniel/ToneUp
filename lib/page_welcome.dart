import 'package:flutter/material.dart';
import 'package:toneup_app/components/feedback_button.dart';
import 'package:toneup_app/services/utils.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});
  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final nikenameCtrl = TextEditingController();
  late PageController _pageController;
  late ThemeData theme;
  late MediaQueryData screen;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentStep, keepPage: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
                // physics: const AlwaysScrollableScrollPhysics(),
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
        padding: EdgeInsets.fromLTRB(24, 40, 24, 80),
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
                  TextSpan(
                    text: 'Let’s start with a learning nickname',
                    style: TextStyle(fontSize: 20),
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
                CircleAvatar(
                  radius: 60,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 4,
                  children: [
                    SizedBox(width: 40),
                    SizedBox(
                      width: 160,
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
                _mainActButton(
                  label: 'Continue',
                  icon: Icons.arrow_right_alt_rounded,
                  callback: nikenameCtrl.text.isEmpty ? null : nextStep,
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
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          minHeight:
              screen.size.height -
              screen.padding.top -
              screen.viewInsets.bottom,
        ),
        padding: EdgeInsets.fromLTRB(24, 40, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 36,
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
                children: [
                  TextSpan(
                    text: 'What’s your main purpose for learning Chinese?',
                    style: TextStyle(
                      fontSize: 28,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            _mainActButton(
              label: 'Continue',
              icon: Icons.arrow_right_alt_rounded,
              callback: nikenameCtrl.text.isEmpty ? null : nextStep,
            ),
          ],
        ),
      ),
    );
  }

  /// 学习时长部分
  Widget _sectionDuration() {
    return SingleChildScrollView(
      child: Container(
        constraints: BoxConstraints(
          minHeight:
              screen.size.height -
              screen.padding.top -
              screen.viewInsets.bottom,
        ),
        padding: EdgeInsets.fromLTRB(24, 40, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 36,
          children: [
            Text.rich(
              TextSpan(
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.normal,
                  fontSize: 16,
                ),
                children: [
                  TextSpan(
                    text: 'How much time can you spend learning each day?',
                    style: TextStyle(
                      fontSize: 28,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            _mainActButton(
              label: 'Continue',
              icon: Icons.arrow_right_alt_rounded,
              callback: nikenameCtrl.text.isEmpty ? null : nextStep,
            ),
          ],
        ),
      ),
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
        padding: EdgeInsets.fromLTRB(24, 40, 24, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 36,
          children: [
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
            _mainActButton(
              label: 'Continue',
              icon: Icons.arrow_right_alt_rounded,
              callback: nikenameCtrl.text.isEmpty ? null : nextStep,
            ),
          ],
        ),
      ),
    );
  }

  /// 主操作按钮
  Widget _mainActButton({
    required String label,
    VoidCallback? callback,
    IconData? icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: FeedbackButton(
        borderRadius: BorderRadius.circular(16),
        onTap: callback,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: ShapeDecoration(
            color: callback == null
                ? theme.colorScheme.secondaryFixed
                : theme.colorScheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 10,
            children: [
              if (icon != null) SizedBox(width: 24),
              Text(
                label,
                style: theme.textTheme.titleMedium!.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (icon != null) Icon(icon, color: theme.colorScheme.onPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
