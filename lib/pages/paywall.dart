import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:toneup_app/components/components.dart';
import 'package:toneup_app/main.dart'; // RevenueCat UI 库

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // RevenueCat 提供的现成 Paywall Widget
      body: PaywallView(
        offering: null, // null = 使用 default offering
        onPurchaseStarted: (rcPackage) {
          // 开始购买
          LoadingOverlay.show(context, label: 'Starting purchase...');
          if (kDebugMode) {
            debugPrint('Purchase started for package: ${rcPackage.identifier}');
          }
        },
        onPurchaseCompleted: (customerInfo, storeTransaction) {
          // 购买成功
          LoadingOverlay.hide();
          if (context.canPop()) context.pop();
          showGlobalSnackBar('Welcome to Pro! 🎉', isError: false);
        },
        onPurchaseCancelled: () {
          // 用户取消购买
          LoadingOverlay.hide();
          showGlobalSnackBar('Purchase cancelled', isError: true);
        },
        onPurchaseError: (error) {
          // 购买失败
          LoadingOverlay.hide();
          showGlobalSnackBar(
            'Purchase failed: ${error.message}',
            isError: true,
          );
        },
        onRestoreError: (error) {
          // 恢复购买失败
          LoadingOverlay.hide();
          showGlobalSnackBar('Restore failed: ${error.message}', isError: true);
        },
        onRestoreCompleted: (customerInfo) {
          // 恢复购买成功
          LoadingOverlay.hide();
          if (context.canPop()) context.pop();
          showGlobalSnackBar('Purchases restored');
        },
        onDismiss: () {
          // 用户关闭 Paywall
          LoadingOverlay.hide();
          if (context.canPop()) context.pop();
        },
      ),
    );
  }
}
