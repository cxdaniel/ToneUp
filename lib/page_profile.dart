import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/components/feedback_button.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/theme_data.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ThemeData theme;
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          // backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 78, 24, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 24,
                children: [
                  _buildUserHeader(provider),
                  _buildOverview(provider),
                  _buildListCeil(
                    label: 'Weekly study duration',
                    hit:
                        (provider.profile == null ||
                            provider.profile!.planDurationMinutes == null)
                        ? '--'
                        : '${provider.profile!.planDurationMinutes} minutes',
                    call: provider.updateMaterials,
                  ),
                  _buildListCeil(label: 'Profile Settings', call: null),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        icon: Icon(
                          Icons.assignment_turned_in_outlined,
                          size: 24,
                          color: theme.colorScheme.secondary,
                        ),
                        onPressed: () {},
                        label: Text(
                          'Condition & Terms',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(
                          Icons.privacy_tip_outlined,
                          size: 24,
                          color: theme.colorScheme.secondary,
                        ),
                        onPressed: () {},
                        label: Text(
                          'Privacy',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(
                          Icons.info_outline,
                          size: 24,
                          color: theme.colorScheme.secondary,
                        ),
                        onPressed: () {},
                        label: Text(
                          'About',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        icon: Icon(
                          Icons.logout_rounded,
                          size: 24,
                          color: theme.colorScheme.secondary,
                        ),
                        onPressed: _logout,
                        label: Text(
                          'Logout',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                ],
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

  /// 用户头像块
  Widget _buildUserHeader(ProfileProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        spacing: 24,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: ShapeDecoration(
              color: theme.colorScheme.surfaceContainer,
              shape: OvalBorder(),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (provider.profile == null || provider.profile!.nickname == null)
                    ? 'Nickname'
                    : provider.profile!.nickname!,
                style: theme.textTheme.titleLarge!.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                (provider.profile == null)
                    ? ''
                    : 'joined in ${provider.profile!.createdAt.year}-${provider.profile!.createdAt.month}',
                style: theme.textTheme.labelMedium!.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 数据统计块
  Widget _buildOverview(ProfileProvider provider) {
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: ShapeDecoration(
              color: theme.extension<AppThemeExtensions>()?.exp,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            // 经验值
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 4,
              children: [
                Icon(
                  Icons.energy_savings_leaf_rounded,
                  color: theme.extension<AppThemeExtensions>()?.onExpContainer,
                ),
                Text(
                  (provider.profile == null || provider.profile!.exp == null)
                      ? '-- EXP'
                      : '${provider.profile!.exp!} EXP',
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: theme
                        .extension<AppThemeExtensions>()
                        ?.onExpContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildInfoCard(
                icon: Icons.signal_cellular_alt_rounded,
                title:
                    (provider.profile == null || provider.profile!.exp == null)
                    ? '--'
                    : 'HSK ${provider.profile!.level}',
                sub: 'Level',
                call: null,
              ),
              _buildInfoCard(
                icon: Icons.track_changes_outlined,
                title:
                    (provider.profile == null ||
                        provider.profile!.plans == null)
                    ? '--'
                    : '${provider.profile!.plans}',
                sub: 'Goals',
                call: null,
              ),
              _buildInfoCard(
                icon: Icons.local_activity_outlined,
                title:
                    (provider.profile == null ||
                        provider.profile!.practices == null)
                    ? '--'
                    : '${provider.profile!.practices}',
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
                    (provider.profile == null ||
                        provider.profile!.characters == null)
                    ? '--'
                    : '${provider.profile!.characters}',
                sub: 'Characters',
                call: null,
              ),
              _buildInfoCard(
                icon: Icons.category_outlined, //content_copy_rounded
                title:
                    (provider.profile == null ||
                        provider.profile!.words == null)
                    ? '--'
                    : '${provider.profile!.words}',
                sub: 'Words',
                call: null,
              ),
              _buildInfoCard(
                icon: Icons.library_books_outlined,
                title:
                    (provider.profile == null ||
                        provider.profile!.sentences == null)
                    ? '--'
                    : '${provider.profile!.sentences}',
                sub: 'Sentences',
                call: null,
              ),
            ],
          ),
        ],
      ),
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
