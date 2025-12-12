// lib/components/premium_feature_gate.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:toneup_app/providers/subscription_provider.dart';
import 'package:toneup_app/router_config.dart';

class PremiumFeatureGate extends StatelessWidget {
  final Widget child;
  final VoidCallback? onUpgradeRequired;
  final String? featureName;

  const PremiumFeatureGate({
    super.key,
    required this.child,
    this.onUpgradeRequired,
    this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, subscription, _) {
        // 如果是 Pro 用户，直接显示内容
        if (subscription.isPro) {
          return child;
        }

        // 否则显示升级提示
        return GestureDetector(
          onTap: () {
            if (onUpgradeRequired != null) {
              onUpgradeRequired!();
            } else {
              context.push(AppRouter.PAYWALL);
            }
          },
          child: Stack(
            children: [
              // 模糊的内容预览
              Opacity(opacity: 0.3, child: AbsorbPointer(child: child)),

              // 升级提示
              Center(
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(height: 16),
                      Text(
                        featureName != null ? '$featureName 是高级功能' : '这是高级功能',
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '升级到 Pro 解锁所有 AI 功能',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          context.push(AppRouter.PAYWALL);
                        },
                        child: Text('查看订阅选项'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
