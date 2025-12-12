import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/components/avatar_upload_widget.dart';
import 'package:toneup_app/components/components.dart';
import 'package:toneup_app/components/feedback_button.dart';
import 'package:toneup_app/main.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/providers/subscription_provider.dart';
import 'package:toneup_app/router_config.dart';
import 'package:toneup_app/theme_data.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ThemeData theme;
  late ProfileProvider profileProvider;
  late SubscriptionProvider subscriptionProvider;

  final List<Map<String, dynamic>> durationOptions = [
    {'label': '10 mins/day', 'value': 60},
    {'label': '20 mins/day', 'value': 100},
    {'label': '30 mins/day', 'value': 150},
  ];
  final nicknameController = TextEditingController();
  final FocusNode focusNode = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  void initState() {
    super.initState();
    if (Provider.of<ProfileProvider>(context, listen: false).profile == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
      });
    }
  }

  Future<void> goSettings() async {
    context.push(AppRouter.SETTINGS);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ProfileProvider, SubscriptionProvider>(
      builder: (context, profile, suscription, child) {
        profileProvider = profile;
        subscriptionProvider = suscription;
        final viewPadding = MediaQuery.of(context).viewPadding;
        return Scaffold(
          body: RefreshIndicator(
            edgeOffset: MediaQuery.of(context).viewPadding.top,
            onRefresh: () async {
              LoadingOverlay.show(context, label: 'Refreshing profile...');
              await profileProvider.fetchProfile();
              await subscriptionProvider.loadUserSubdata();
              await subscriptionProvider.testRevenueCatConfig();
              LoadingOverlay.hide();
            },
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  viewPadding.top + 24,
                  24,
                  viewPadding.bottom + 90,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 24,
                  children: [
                    _buildUserHeader(),
                    _buildOverview(),
                    // listCeil(
                    //   context,
                    //   label: 'Profile Settings',
                    //   call: goSettings,
                    // ),
                    listCeil(
                      context,
                      label: 'Weekly study duration',
                      hit: _displayDuration(),
                      call: setWeeklyDuration,
                    ),
                    listCeil(
                      context,
                      label: 'Account Management',
                      hit: 'Email, Apple, Google',
                      call: () => context.push(AppRouter.ACCOUNT_SETTINGS),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        iconLink(
                          context,
                          icon: Icons.assignment_turned_in_outlined,
                          label: 'Terms of Service',
                          call: () => context.push(AppRouter.TERMS_OF_SERVICE),
                        ),
                        iconLink(
                          context,
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy Policy',
                          call: () => context.push(AppRouter.PRIVACY_POLICY),
                        ),
                        iconLink(
                          context,
                          icon: Icons.info_outline,
                          label: 'About ToneUp',
                          call: () => context.push(AppRouter.ABOUT),
                        ),
                        iconLink(
                          context,
                          icon: Icons.logout_rounded,
                          label: 'Logout',
                          call: _logout,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 登出
  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
  }

  /// 订阅状态卡片
  Widget _buildSubscriptionStatusCard() {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscription, child) {
        // Web 端且非 Pro:不显示升级按钮
        if (kIsWeb && !subscription.isPro) {
          return _buildWebFreeCard();
        }
        return subscription.isPro ? _buildManageButtons() : _buildUpgradeCard();
      },
    );
  }

  /// Web端免费用户卡片
  Widget _buildWebFreeCard() {
    return FeedbackButton(
      onTap: () {
        context.push(AppRouter.DOWNLOAD);
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.info_outline,
              size: 32,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 4),
            Text(
              'Please use mobile app to upgrade',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 管理订阅按钮
  Widget _buildManageButtons() {
    return FeedbackButton(
      onTap: () => context.push(AppRouter.SUBSCRIPTION_MANAGE),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 8),
            Icon(Icons.star, color: Colors.white, size: 40),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage Subscription',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'View plan details and billing',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.navigate_next_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  /// 升级卡片
  Widget _buildUpgradeCard() {
    return FeedbackButton(
      onTap: () => context.push(AppRouter.PAYWALL),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 8),
            Icon(Icons.star, color: Colors.white, size: 40),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Unlimited goals & AI features',
                    style: TextStyle(
                      color: Colors.white.withAlpha(200),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.navigate_next_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  /// 用户头像块
  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        spacing: 24,
        children: [
          AvatarUploadWidget(
            radius: 40,
            onAvatarChanged: (bytes) {
              if (bytes != null) {
                profileProvider.updateAvatar(bytes);
              }
            },
            initialAvatar: profileProvider.avatarBytes,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FeedbackButton(
                onTap: setNickname,
                child: Text(
                  (profileProvider.profile == null ||
                          profileProvider.profile!.nickname == null)
                      ? 'Nickname'
                      : profileProvider.profile!.nickname!,
                  style: theme.textTheme.titleLarge!.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                (profileProvider.profile == null)
                    ? ''
                    : 'joined in ${profileProvider.profile!.createdAt!.year}-${profileProvider.profile!.createdAt!.month}',
                style: theme.textTheme.labelMedium!.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              SizedBox(height: 8),
              _buildSubscriptionBadge(),
            ],
          ),
          Spacer(),
          _buildEXP(),
        ],
      ),
    );
  }

  /// 订阅状态徽章
  Widget _buildSubscriptionBadge() {
    final subscription = subscriptionProvider.subscription;

    if (subscription == null || subscription.isFree) {
      // 免费用户
      return tagLabel(
        context: context,
        backColor: theme.colorScheme.secondaryContainer,
        frontColor: theme.colorScheme.onSecondaryContainer,
        label: 'FREE PLAN',
      );
    } else if (subscription.isTrialing) {
      // 试用期用户
      final daysLeft = subscription.trialDaysLeft ?? 0;
      return tagLabel(
        context: context,
        backColor: theme.colorScheme.errorContainer,
        frontColor: theme.colorScheme.onErrorContainer,
        label: 'TRIAL: $daysLeft DAYS LEFT',
      );
    } else {
      // Pro 用户
      return tagLabel(
        context: context,
        backColor: theme.colorScheme.primaryContainer,
        frontColor: theme.colorScheme.onPrimaryContainer,
        label: 'PRO PLAN',
      );
    }
  }

  /// 数据统计块
  Widget _buildOverview() {
    return Ink(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        spacing: 16,
        children: [
          _buildSubscriptionStatusCard(),
          Row(
            children: [
              _buildInfoCard(
                icon: Icons.signal_cellular_alt_rounded,
                title:
                    (profileProvider.profile == null ||
                        profileProvider.profile!.level == null)
                    ? '--'
                    : 'HSK ${profileProvider.profile!.level}',
                sub: 'Level',
                call: null,
              ),
              _buildInfoCard(
                icon: Icons.track_changes_outlined,
                title:
                    (profileProvider.profile == null ||
                        profileProvider.profile!.plans == null)
                    ? '--'
                    : '${profileProvider.profile!.plans}',
                sub: 'Goals',
                call: null,
              ),
              _buildInfoCard(
                icon: Icons.local_activity_outlined,
                title:
                    (profileProvider.profile == null ||
                        profileProvider.profile!.practices == null)
                    ? '--'
                    : '${profileProvider.profile!.practices}',
                sub: 'Practices',
                call: null,
              ),
            ],
          ),
          Divider(height: 0, thickness: 1, color: theme.colorScheme.surfaceDim),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoCard(
                icon: Icons.translate_rounded,
                title:
                    (profileProvider.profile == null ||
                        profileProvider.profile!.characters == null)
                    ? '--'
                    : '${profileProvider.profile!.characters}',
                sub: 'Characters',
                call: null,
              ),
              _buildInfoCard(
                icon: Icons.category_outlined, //content_copy_rounded
                title:
                    (profileProvider.profile == null ||
                        profileProvider.profile!.words == null)
                    ? '--'
                    : '${profileProvider.profile!.words}',
                sub: 'Words',
                call: null,
              ),
              _buildInfoCard(
                icon: Icons.library_books_outlined,
                title:
                    (profileProvider.profile == null ||
                        profileProvider.profile!.sentences == null)
                    ? '--'
                    : '${profileProvider.profile!.sentences}',
                sub: 'Sentences',
                call: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEXP() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 4,
      children: [
        Text(
          (profileProvider.profile == null ||
                  profileProvider.profile!.exp == null)
              ? '--'
              : '${profileProvider.profile!.exp!} EXP',
          style: theme.textTheme.titleMedium!.copyWith(
            color: theme.extension<AppThemeExtensions>()?.exp,
            fontWeight: FontWeight.w700,
          ),
        ),
        Icon(
          Icons.energy_savings_leaf_rounded,
          color: theme.extension<AppThemeExtensions>()?.exp,
        ),
      ],
    );
  }

  /// 统计数据卡
  Widget _buildInfoCard({
    required String title,
    required String sub,
    required IconData icon,
    VoidCallback? call,
  }) {
    return Expanded(
      child: FeedbackButton(
        borderRadius: BorderRadius.circular(16),
        onTap: call,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.outline),
              Text(
                title,
                style: theme.textTheme.titleMedium!.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                sub,
                style: theme.textTheme.labelSmall!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      useRootNavigator: true,
      useSafeArea: true,
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
    final userNickname = await showDialog<String>(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          debugPrint('setNickname::::');
          FocusScope.of(context).requestFocus(focusNode);
        });
        return AlertDialog(
          title: Text(
            'Change Nickname',
            style: theme.textTheme.titleMedium!.copyWith(
              color: theme.colorScheme.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            focusNode: focusNode,
            controller: nicknameController,
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
              if (value.isEmpty) {
                showOverlayMessage(
                  context,
                  'Nickname cannot be empty',
                  isError: true,
                );
                return;
              }
              debugPrint('onSubmitted::::$value');
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
            FilledButton(
              onPressed: () {
                final newNickname = nicknameController.text.trim();
                if (newNickname.isEmpty) {
                  showOverlayMessage(
                    context,
                    'Nickname cannot be empty',
                    isError: true,
                  );
                  return;
                }
                Navigator.pop(context, newNickname);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
    if (userNickname != null) {
      ProfileProvider().profile?.nickname = userNickname;
      ProfileProvider().saveProfile();
    }
  }
}
