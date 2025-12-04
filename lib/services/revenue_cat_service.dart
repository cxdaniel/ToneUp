// lib/services/revenue_cat_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/services/config.dart';

class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal() {
    initialize();
  }
  final _supabase = Supabase.instance.client;
  bool _isInitialized = false;

  /// 初始化 RevenueCat
  Future<void> initialize() async {
    if (_isInitialized) return;

    String apiKey;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      apiKey = RevenueCatConfig.apiKeyIOS;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      apiKey = RevenueCatConfig.apiKeyAndroid;
    } else {
      throw UnsupportedError('Platform not supported');
    }

    try {
      final configuration = PurchasesConfiguration(apiKey);

      // 如果用户已登录，设置用户ID
      final user = _supabase.auth.currentUser;
      if (user != null) {
        configuration.appUserID = user.id;
      }

      await Purchases.configure(configuration);

      // 设置调试模式
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      }

      // ✅ 测试：获取客户信息（不涉及产品）
      try {
        final customerInfo = await Purchases.getCustomerInfo();
        debugPrint(
          '✅ Customer Info retrieved: ${customerInfo.originalAppUserId}',
        );
      } catch (e) {
        debugPrint('❌ Failed to get customer info: $e');
      }

      _isInitialized = true;
      debugPrint('✅ RevenueCat initialized successfully');

      _isInitialized = true;
      debugPrint('✅ RevenueCat 初始化成功');
    } catch (e) {
      debugPrint('❌ RevenueCat 初始化失败: $e');
      rethrow;
    }
  }

  /// 登录后设置用户ID
  Future<void> login(String userId) async {
    try {
      await Purchases.logIn(userId);
      debugPrint('✅ RevenueCat 用户登录: $userId');
    } catch (e) {
      debugPrint('❌ RevenueCat 用户登录失败: $e');
      rethrow;
    }
  }

  /// 登出
  Future<void> logout() async {
    try {
      await Purchases.logOut();
      debugPrint('✅ RevenueCat 用户登出');
    } catch (e) {
      debugPrint('❌ RevenueCat 用户登出失败: $e');
    }
  }

  /// 获取可用的订阅产品
  Future<Offerings?> getOfferings() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        debugPrint('⚠️ 没有可用的订阅产品');
        return null;
      }
      return offerings;
    } catch (e) {
      debugPrint('❌ 获取订阅产品失败: $e');
      rethrow;
    }
  }

  /// 购买产品
  Future<CustomerInfo?> purchasePackage(Package package) async {
    try {
      final purchaseResult = await Purchases.purchase(
        PurchaseParams.package(package),
      );
      debugPrint('✅ 购买成功: ${package.identifier}');

      final customerInfo = purchaseResult.customerInfo;

      // 同步到 Supabase
      await syncSubscriptionToSupabase(customerInfo);
      return customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('⚠️ 用户取消购买');
        return null;
      } else {
        debugPrint('❌ 购买失败: $e');
        rethrow;
      }
    }
  }

  /// 恢复购买
  Future<CustomerInfo> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      debugPrint('✅ 恢复购买成功');

      // 同步到 Supabase
      await syncSubscriptionToSupabase(customerInfo);

      return customerInfo;
    } catch (e) {
      debugPrint('❌ 恢复购买失败: $e');
      rethrow;
    }
  }

  /// 检查用户是否是 Pro
  Future<bool> isPro() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlement =
          customerInfo.entitlements.all[RevenueCatConfig.entitlementId];
      return entitlement?.isActive == true;
    } catch (e) {
      debugPrint('❌ 检查订阅状态失败: $e');
      return false;
    }
  }

  /// 获取当前订阅信息
  Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  /// 同步订阅状态到 Supabase
  Future<void> syncSubscriptionToSupabase(CustomerInfo customerInfo) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ 用户未登录，无法同步订阅');
        return;
      }

      final entitlement =
          customerInfo.entitlements.all[RevenueCatConfig.entitlementId];
      final isActive = entitlement?.isActive == true;

      debugPrint('🔄 同步订阅到 Supabase');

      // ✅ 完整的数据准备
      final subscriptionData = {
        'user_id': user.id,
        'revenue_cat_customer_id': customerInfo.originalAppUserId,
        'revenue_cat_entitlement_id': isActive
            ? RevenueCatConfig.entitlementId
            : null,
        'status': _getSubscriptionStatus(entitlement),
        'tier': _getSubscriptionTier(entitlement),

        // ✅ 试用期信息
        'trial_start_at': _getTrialStartDate(entitlement),
        'trial_end_at': _getTrialEndDate(entitlement),

        // ✅ 订阅时间
        'subscription_start_at': entitlement?.latestPurchaseDate,
        'subscription_end_at': entitlement?.expirationDate,

        // ✅ 取消时间
        'cancelled_at': _getCancelledDate(entitlement),

        'platform': _getPlatform(entitlement),
        'product_id': entitlement?.productIdentifier,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // debugPrint('📝 准备写入数据: $subscriptionData');

      // Upsert 到数据库
      await _supabase
          .from('subscriptions')
          .upsert(subscriptionData, onConflict: 'user_id');

      debugPrint('✅ 订阅状态已同步到 Supabase');
    } catch (e, stackTrace) {
      debugPrint('❌ 同步订阅状态失败: $e');
      debugPrint('Stack trace: $stackTrace');
      // 不要 rethrow，让购买流程继续
    }
  }

  /// 获取订阅状态
  String _getSubscriptionStatus(EntitlementInfo? entitlement) {
    if (entitlement == null || !entitlement.isActive) return 'free';
    // 检查是否在试用期
    if (entitlement.periodType == PeriodType.trial) return 'trial';
    // 检查是否已取消但仍在有效期内
    if (!entitlement.willRenew && entitlement.isActive) return 'cancelled';
    return 'active';
  }

  /// 获取订阅等级
  String? _getSubscriptionTier(EntitlementInfo? entitlement) {
    if (entitlement == null) return null;

    final productId = entitlement.productIdentifier.toLowerCase();
    if (productId.contains('monthly')) return 'monthly';
    if (productId.contains('yearly') || productId.contains('annual')) {
      return 'yearly';
    }
    if (productId.contains('lifetime')) return 'lifetime';

    return null;
  }

  // 获取试用开始时间
  String? _getTrialStartDate(EntitlementInfo? entitlement) {
    if (entitlement == null) return null;

    // 如果是试用期，使用 originalPurchaseDate
    if (entitlement.periodType == PeriodType.trial) {
      return entitlement.originalPurchaseDate;
    }

    return null;
  }

  // 获取试用结束时间
  String? _getTrialEndDate(EntitlementInfo? entitlement) {
    if (entitlement == null) return null;

    // 如果是试用期，使用 expirationDate
    if (entitlement.periodType == PeriodType.trial) {
      return entitlement.expirationDate;
    }

    return null;
  }

  String? _getPlatform(EntitlementInfo? entitlement) {
    if (entitlement == null) return null;

    if (entitlement.store == Store.appStore) return 'ios';
    if (entitlement.store == Store.playStore) return 'android';
    if (entitlement.store == Store.stripe) return 'web';

    return null;
  }

  // 获取取消时间
  String? _getCancelledDate(EntitlementInfo? entitlement) {
    if (entitlement == null) return null;

    // 如果订阅不会续订但仍然活跃，说明已被取消
    if (!entitlement.willRenew && entitlement.isActive) {
      // RevenueCat 没有提供确切的取消时间，使用当前时间作为标记
      return DateTime.now().toIso8601String();
    }

    // 如果已过期且不续订，使用过期时间
    if (!entitlement.willRenew && !entitlement.isActive) {
      return entitlement.expirationDate;
    }

    return null;
  }
}
