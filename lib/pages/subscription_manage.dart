import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:toneup_app/main.dart';
import 'package:toneup_app/models/subscription_model.dart';
import 'package:toneup_app/providers/subscription_provider.dart';
import 'package:toneup_app/routes.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionManagePage extends StatelessWidget {
  const SubscriptionManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subscription = Provider.of<SubscriptionProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Subscription')),
      body: subscription.subscription == null
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 当前状态卡片
                  _buildStatusCard(context, subscription, theme),

                  SizedBox(height: 24),

                  // 功能列表
                  if (subscription.isPro) ...[
                    Text(
                      'Your Benefits',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    _buildBenefitsList(theme),
                    SizedBox(height: 24),
                  ],

                  // 管理订阅按钮
                  _buildManageButtons(context, subscription, theme),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(
    BuildContext context,
    SubscriptionProvider subscription,
    ThemeData theme,
  ) {
    final sub = subscription.subscription!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: subscription.isPro
              ? [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withAlpha(172),
                ]
              : [
                  theme.colorScheme.surfaceContainerHighest,
                  theme.colorScheme.surface,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(25),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                subscription.isPro ? Icons.star : Icons.person,
                color: subscription.isPro
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                size: 32,
              ),
              SizedBox(width: 12),
              Text(
                _getTitle(sub),
                // subscription.isPro ? 'ToneUp Pro' : 'Free Plan',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: subscription.isPro
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),

          if (subscription.isPro) ...[
            SizedBox(height: 16),
            Text(
              _getStatusText(sub),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withAlpha(230),
              ),
            ),

            if (sub.subscriptionEndAt != null) ...[
              SizedBox(height: 8),
              Text(
                _getExpiryText(sub),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withAlpha(172),
                ),
              ),
            ],
          ] else ...[
            SizedBox(height: 16),
            Text(
              'Upgrade to unlock unlimited AI-powered practice',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(172),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 获取类别标题
  String _getTitle(SubscriptionModel sub) {
    if (sub.isTrialing) {
      return 'ToneUp Pro (Trial)';
    } else if (sub.isPro) {
      return 'ToneUp Pro';
    } else {
      return 'Free Plan';
    }
  }

  Widget _buildBenefitsList(ThemeData theme) {
    final benefits = [
      'Unlimited practice sessions',
      'AI-personalized study plans',
      'Advanced pronunciation feedback',
      'Deep ability analytics',
      'Priority support',
    ];

    return Column(
      children: benefits.map((benefit) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(child: Text(benefit, style: theme.textTheme.bodyLarge)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildManageButtons(
    BuildContext context,
    SubscriptionProvider subscription,
    ThemeData theme,
  ) {
    return Column(
      children: [
        if (!subscription.isPro)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                context.push(AppRoutes.PAYWALL);
              },
              child: Text('Upgrade to Pro'),
            ),
          ),

        if (subscription.isPro) ...[
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () =>
                  _openManageSubscription(subscription.subscription!.platform),
              icon: Icon(Icons.settings),
              label: Text('Manage Subscription'),
            ),
          ),
          SizedBox(height: 12),
        ],

        SizedBox(
          width: double.infinity,
          height: 52,
          child: TextButton(
            onPressed: () async {
              await subscription.restorePurchases();
              if (context.mounted) {
                showGlobalSnackBar('Purchases restored');
              }
            },
            child: Text('Restore Purchases'),
          ),
        ),
      ],
    );
  }

  /// 获取状态文本
  String _getStatusText(SubscriptionModel sub) {
    if (sub.isTrialing) {
      final daysLeft = sub.trialDaysLeft ?? 0;
      return 'Free Trial Active - $daysLeft days remaining';
    } else if (sub.status == SubscriptionStatus.cancelled) {
      return 'Cancelled (Active until expiry)';
    } else {
      return '${sub.tier?.name.toUpperCase()} Subscription';
    }
  }

  /// 获取到期信息
  String _getExpiryText(SubscriptionModel sub) {
    if (sub.isTrialing && sub.trialEndAt != null) {
      final daysLeft = sub.trialDaysLeft ?? 0;
      return 'Trial ends ${_formatDate(sub.trialEndAt!)} (in $daysLeft days)';
    } else if (sub.subscriptionEndAt != null) {
      final daysLeft = sub.subscriptionEndAt!.difference(DateTime.now()).inDays;
      if (sub.status == SubscriptionStatus.cancelled) {
        return 'Access ends in $daysLeft days';
      } else {
        return 'Renews on ${_formatDate(sub.subscriptionEndAt!)}';
      }
    }
    return '';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Future<void> _openManageSubscription(String? platform) async {
    String url;

    debugPrint('Opening manage subscription for platform: $platform');
    if (platform == 'ios') {
      url = 'https://apps.apple.com/account/subscriptions';
    } else if (platform == 'android') {
      url = 'https://play.google.com/store/account/subscriptions';
    } else {
      return;
    }

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
