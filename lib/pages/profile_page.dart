import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/components/avatar_upload_widget.dart';
import 'package:toneup_app/components/components.dart';
import 'package:toneup_app/components/feedback_button.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/providers/subscription_provider.dart';
import 'package:toneup_app/routes.dart';
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
    context.push(AppRoutes.SETTINGS);
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
              await subscriptionProvider.loadSubscription();
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
                    _buildListCeil(label: 'Profile Settings', call: goSettings),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 8,
                      children: [
                        _buildLink(
                          icon: Icons.assignment_turned_in_outlined,
                          label: 'Condition & Terms',
                          call: () {},
                        ),
                        _buildLink(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy',
                          call: null,
                        ),
                        _buildLink(
                          icon: Icons.info_outline,
                          label: 'About',
                          call: null,
                        ),
                        _buildLink(
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

  Future<void> _logout() async {
    // Provider.of<PlanProvider>(context, listen: false).cleanAllPlans();
    await Supabase.instance.client.auth.signOut();
  }

  Widget _buildSubscriptionStatusCard() {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscription, child) {
        return subscription.isPro ? _buildManageButtons() : _buildUpgradeCard();
      },
    );
  }

  /// 管理订阅按钮
  Widget _buildManageButtons() {
    return FeedbackButton(
      onTap: () => context.push(AppRoutes.SUBSCRIPTION_MANAGE),
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
      onTap: () => context.push(AppRoutes.PAYWALL),
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
              Text(
                (profileProvider.profile == null ||
                        profileProvider.profile!.nickname == null)
                    ? 'Nickname'
                    : profileProvider.profile!.nickname!,
                style: theme.textTheme.titleLarge!.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
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
              tagLabel(
                context: context,
                backColor: subscriptionProvider.isPro
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.secondaryContainer,
                frontColor: subscriptionProvider.isPro
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSecondaryContainer,
                label: subscriptionProvider.isPro ? 'PRO PLAN' : 'FREE PLAN',
              ),
            ],
          ),
          Spacer(),
          _buildEXP(),
        ],
      ),
    );
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 10,
          children: [
            if (label != null)
              Text(
                label,
                style: theme.textTheme.titleMedium!.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            if (hit != null)
              Expanded(
                child: Text(
                  textAlign: TextAlign.right,
                  hit,
                  style: theme.textTheme.labelLarge!.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w300,
                  ),
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

  /// 图标文字链
  Widget _buildLink({
    required String label,
    IconData? icon,
    VoidCallback? call,
  }) {
    return TextButton.icon(
      icon: Icon(icon, size: 20, color: theme.colorScheme.outline),
      onPressed: call,
      label: Text(
        label,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.secondary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
