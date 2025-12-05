import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:toneup_app/components/components.dart';
import 'package:toneup_app/main.dart';
import 'package:toneup_app/providers/subscription_provider.dart'; // RevenueCat UI 库

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // RevenueCat 提供的现成 Paywall Widget
      body: PaywallView(
        offering: null, // null = 使用 default offering

        onPurchaseStarted: (rcPackage) async {
          // 开始购买
          LoadingOverlay.show(context, label: 'Starting purchase...');

          debugPrint('═══════════════════════════════════');
          debugPrint('🛒 Purchase Started');
          debugPrint('═══════════════════════════════════');
          debugPrint('Package ID: ${rcPackage.identifier}');
          debugPrint('Product ID: ${rcPackage.storeProduct.identifier}');
          debugPrint('Price: ${rcPackage.storeProduct.priceString}');
          debugPrint('Title: ${rcPackage.storeProduct.title}');
          debugPrint('Description: ${rcPackage.storeProduct.description}');

          // ✅ 检查当前环境
          try {
            final customerInfo = await Purchases.getCustomerInfo();
            debugPrint(
              'Current Customer ID: ${customerInfo.originalAppUserId}',
            );
            debugPrint(
              'Current Entitlements: ${customerInfo.entitlements.all.keys}',
            );
          } catch (e) {
            debugPrint('⚠️ Failed to get customer info: $e');
          }
        },

        onPurchaseCompleted: (customerInfo, storeTransaction) async {
          // 购买成功

          debugPrint('═══════════════════════════════════');
          debugPrint('✅ Purchase Completed!');
          debugPrint('═══════════════════════════════════');
          debugPrint(
            'Transaction ID: ${storeTransaction.transactionIdentifier}',
          );
          debugPrint('Product ID: ${storeTransaction.productIdentifier}');
          debugPrint('Purchase Date: ${storeTransaction.purchaseDate}');
          debugPrint('Customer ID: ${customerInfo.originalAppUserId}');

          // ✅ 检查 Entitlements
          debugPrint(
            'All Entitlements: ${customerInfo.entitlements.all.keys.toList()}',
          );

          final proEntitlement = customerInfo.entitlements.all['pro_features'];
          if (proEntitlement != null) {
            debugPrint('Pro Features Entitlement:');
            debugPrint('  - Active: ${proEntitlement.isActive}');
            debugPrint('  - Product ID: ${proEntitlement.productIdentifier}');
            debugPrint('  - Will Renew: ${proEntitlement.willRenew}');
            debugPrint('  - Period Type: ${proEntitlement.periodType}');
            debugPrint('  - Store: ${proEntitlement.store}');
            debugPrint(
              '  - Latest Purchase: ${proEntitlement.latestPurchaseDate}',
            );
            debugPrint('  - Expiration: ${proEntitlement.expirationDate}');
          } else {
            debugPrint('⚠️ Pro Features Entitlement NOT FOUND!');
          }
          // ✅ 立即同步到 Supabase
          final subscriptionProvider = Provider.of<SubscriptionProvider>(
            context,
            listen: false,
          );
          debugPrint('🔄 Syncing subscription state...');
          await subscriptionProvider.loadSubscription();
          debugPrint('✅ Subscription state synced');
          debugPrint('📊 Final State:');
          debugPrint(
            '  - Subscription Status: ${subscriptionProvider.subscription?.status.name}',
          );
          debugPrint('  - Is Pro: ${subscriptionProvider.isPro}');
          debugPrint(
            '  - Tier: ${subscriptionProvider.subscription?.tier?.name}',
          );
          debugPrint('═══════════════════════════════════');

          LoadingOverlay.hide();
          showGlobalSnackBar('Welcome to Pro! 🎉', isError: false);
          if (context.mounted && context.canPop()) context.pop();
        },

        onPurchaseCancelled: () {
          // 用户取消购买
          LoadingOverlay.hide();
          showGlobalSnackBar('Purchase cancelled', isError: true);
        },

        onPurchaseError: (error) {
          // 购买失败
          debugPrint('═══════════════════════════════════');
          debugPrint('❌ Purchase Error');
          debugPrint('═══════════════════════════════════');
          debugPrint('Error Code: ${error.code}');
          debugPrint('Error Message: ${error.message}');
          debugPrint('Underlying Error: ${error.underlyingErrorMessage}');
          debugPrint('═══════════════════════════════════');

          LoadingOverlay.hide();
          showGlobalSnackBar(
            'Purchase failed: ${error.message}',
            isError: true,
          );
        },

        onRestoreError: (error) {
          // 恢复购买失败
          LoadingOverlay.hide();

          debugPrint('❌ Purchase error: ${error.message}');
          debugPrint('   Error code: ${error.code}');
          debugPrint('   Underlying error: ${error.underlyingErrorMessage}');

          showGlobalSnackBar('Restore failed: ${error.message}', isError: true);
        },

        onRestoreCompleted: (customerInfo) async {
          // 恢复购买成功
          debugPrint('✅ Restore completed');
          final subscriptionProvider = Provider.of<SubscriptionProvider>(
            context,
            listen: false,
          );

          await subscriptionProvider.loadSubscription();

          LoadingOverlay.hide();
          if (context.mounted && context.canPop()) context.pop();
          showGlobalSnackBar('Purchases restored');
        },
        onDismiss: () {
          // 用户关闭 Paywall
          LoadingOverlay.hide();
          if (context.mounted && context.canPop()) context.pop();
        },
      ),
    );
  }
}
