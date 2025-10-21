import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/components/feedback_button.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 78, 24, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: [
              _buildUserHeader(),
              _buildOverview(),
              _buildListCeil(
                label: 'Weekly study duration',
                hit: '50 minutes',
                call: () {},
              ),
              _buildListCeil(label: 'Profile Settings', call: () {}),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  TextButton.icon(
                    icon: Icon(
                      Icons.assignment_turned_in_outlined,
                      size: 24,
                      color: colorScheme.secondary,
                    ),
                    onPressed: () {},
                    label: Text(
                      'Condition & Terms',
                      style: textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.privacy_tip_outlined,
                      size: 24,
                      color: colorScheme.secondary,
                    ),
                    onPressed: () {},
                    label: Text('Privacy', style: textTheme.titleMedium),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.info_outline,
                      size: 24,
                      color: colorScheme.secondary,
                    ),
                    onPressed: () {},
                    label: Text('About', style: textTheme.titleMedium),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.logout_rounded,
                      size: 24,
                      color: colorScheme.secondary,
                    ),
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                    },
                    label: Text('Logout', style: textTheme.titleMedium),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 用户头像块
  Widget _buildUserHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        spacing: 24,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: ShapeDecoration(
              color: Theme.of(context).colorScheme.surfaceDim,
              shape: OvalBorder(),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Username',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              Text(
                '@userid · joined in 2025',
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 数据统计块
  Widget _buildOverview() {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Ink(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Column(
        spacing: 16,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: ShapeDecoration(
              color: Colors.amber[500],
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
                  color: colorScheme.onPrimary,
                ),
                Text(
                  '1873 EXP',
                  style: textTheme.titleMedium!.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Row(
            // mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoCard(
                icon: Icons.signal_cellular_alt_rounded,
                title: 'HSK 2',
                sub: 'Level',
                call: null,
              ),
              _buildInfoCard(
                icon: Icons.track_changes_outlined,
                title: '5',
                sub: 'Goals',
                call: null,
              ),
              _buildInfoCard(
                icon: Icons.local_activity_outlined,
                title: '63',
                sub: 'Practices',
                call: null,
              ),
            ],
          ),
          Divider(height: 0, thickness: 1, color: colorScheme.surfaceDim),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoCard(
                icon: Icons.translate_rounded,
                title: '175',
                sub: 'Characters',
                call: null,
              ),
              _buildInfoCard(
                icon: Icons.library_books_outlined,
                title: '24',
                sub: 'Sentences',
                call: null,
              ),
              _buildInfoCard(
                icon: Icons.perm_data_setting_outlined,
                title: '12',
                sub: 'Grammars',
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
    Function? call,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: FeedbackButton(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: colorScheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32),
              Text(
                title,
                style: textTheme.titleMedium!.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                sub,
                style: textTheme.labelSmall!.copyWith(
                  color: colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 列表项
  Widget _buildListCeil({String? label, String? hit, Function? call}) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return FeedbackButton(
      borderRadius: BorderRadius.circular(16),
      onTap: (call != null) ? () => call : null,
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: colorScheme
              .surfaceContainerLow /* Schemes-Surface-Container-Low */,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          children: [
            if (label != null)
              Text(
                label,
                style: textTheme.titleMedium!.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                ),
              ),
            Spacer(),
            if (hit != null)
              Text(
                hit,
                style: textTheme.labelLarge!.copyWith(
                  color: colorScheme.secondaryFixed,
                  fontWeight: FontWeight.w300,
                ),
              ),
            if (call != null)
              Icon(
                Icons.navigate_next_rounded,
                size: 24,
                color: colorScheme.secondary,
              ),
          ],
        ),
      ),
    );
  }
}
