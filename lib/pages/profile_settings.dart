import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:toneup_app/components/feedback_button.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/routes.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});
  @override
  State<StatefulWidget> createState() => _ProfileSettings();
}

class _ProfileSettings extends State<ProfileSettings> {
  final List<Map<String, dynamic>> durationOptions = [
    {'label': '10 mins/day', 'value': 60},
    {'label': '20 mins/day', 'value': 100},
    {'label': '30 mins/day', 'value': 150},
  ];
  final nicknameController = TextEditingController();
  final FocusNode focusNode = FocusNode();
  late ThemeData theme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  /// 获取时长显示
  String _displayDuration() {
    if (ProfileProvider().profile == null) return '--';
    final target = durationOptions.firstWhere(
      (item) => item['value'] == ProfileProvider().profile!.planDurationMinutes,
      orElse: () => {'label': '--', 'value': 0},
    );
    return target['label'];
  }

  /// 设置周学习时长
  Future<void> setWeeklyDuration() async {
    final selectedValue = await showModalBottomSheet<int?>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom, //+ 56,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 10),
                child: Text(
                  'Set Weekly Study Duration',
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Divider(
                height: 20,
                thickness: 1,
                color: theme.colorScheme.outlineVariant,
              ),
              ...durationOptions.map((option) {
                return FeedbackButton(
                  onTap: () {
                    Navigator.pop(context, option['value']);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Text(
                      option['label'],
                      style: theme.textTheme.titleMedium!.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                );
              }),
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );

    if (selectedValue != null) {
      ProfileProvider().profile!.planDurationMinutes = selectedValue;
      await ProfileProvider().saveProfile();
    }
  }

  /// 设置用户昵称
  Future<void> setNickname() async {
    nicknameController.text = ProfileProvider().profile?.nickname ?? '--';
    await showDialog(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint('setNickname::::');
          FocusScope.of(context).requestFocus(focusNode);
        });
        return AlertDialog(
          // backgroundColor: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Edit Nickname',
            style: theme.textTheme.titleMedium!.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            focusNode: focusNode,
            controller: nicknameController,
            style: theme.textTheme.bodyLarge!.copyWith(
              color: theme.colorScheme.secondary,
            ),
            decoration: InputDecoration(
              hintText: 'Please enter your new nickname',
              hintStyle: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.outline,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
            maxLength: 16, // 输入限制
            maxLengthEnforcement:
                MaxLengthEnforcement.truncateAfterCompositionEnds,
            keyboardType: TextInputType.text, // 键盘类型：文本输入
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              _confirmNickname(context, nicknameController.text.trim());
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // 关闭弹窗，不做任何操作
              child: Text(
                'Cancel',
                style: theme.textTheme.titleSmall!.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  _confirmNickname(context, nicknameController.text.trim()),
              child: Text(
                'Confirm',
                style: theme.textTheme.titleSmall!.copyWith(
                  color: theme.colorScheme.primary, // 确认按钮用主题主色突出
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    ).whenComplete(() {});
  }

  /// 处理昵称确认逻辑
  void _confirmNickname(BuildContext dialogContext, String newNickname) {
    if (newNickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nickname cannot be empty'),
          backgroundColor: theme.colorScheme.error, // 错误提示用红色
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating, // 悬浮样式，不遮挡输入框
        ),
      );
      return;
    }

    ProfileProvider().profile?.nickname = newNickname;
    ProfileProvider().saveProfile();
    Navigator.pop(dialogContext);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Settings',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                spacing: 24,
                children: [
                  _buildListCeil(
                    label: 'Nickname',
                    hit: provider.profile!.nickname ?? '--',
                    call: setNickname,
                  ),
                  _buildListCeil(
                    label: 'Weekly study duration',
                    hit: _displayDuration(),
                    call: setWeeklyDuration,
                  ),
                  _buildListCeil(
                    label: 'Account Management',
                    hit: 'Email, Apple, Google',
                    call: () => context.push(AppRoutes.ACCOUNT_SETTINGS),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// 列表项
  Widget _buildListCeil({String? label, String? hit, VoidCallback? call}) {
    return FeedbackButton(
      borderRadius: BorderRadius.circular(16),
      onTap: call,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: theme.colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            if (label != null)
              Text(
                label,
                style: theme.textTheme.titleMedium!.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Spacer(),
            if (hit != null)
              Text(
                hit,
                style: theme.textTheme.labelLarge!.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w300,
                ),
              ),
            if (call != null)
              Icon(
                Icons.navigate_next_rounded,
                size: 24,
                color: theme.colorScheme.secondary,
              ),
          ],
        ),
      ),
    );
  }
}
