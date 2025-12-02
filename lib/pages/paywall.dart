import 'package:flutter/material.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart'; // RevenueCat UI 库

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // RevenueCat 提供的现成 Paywall Widget
      body: PaywallView(
        offering: null, // null = 使用 default offering
        onPurchaseCompleted: (customerInfo, storeTransaction) {
          // 购买成功
          Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Welcome to Pro! 🎉')));
        },
        onRestoreCompleted: (customerInfo) {
          // 恢复购买成功
          Navigator.pop(context);
        },
        onDismiss: () {
          // 用户关闭 Paywall
          Navigator.pop(context);
        },
      ),
    );
  }
}
