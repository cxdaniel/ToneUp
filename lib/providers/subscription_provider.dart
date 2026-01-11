import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/subscription_model.dart';
import 'package:toneup_app/providers/plan_provider.dart';
import 'package:toneup_app/services/config.dart';
import 'package:toneup_app/services/revenue_cat_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  static final SubscriptionProvider _instance =
      SubscriptionProvider._internal();
  factory SubscriptionProvider() => _instance;
  SubscriptionProvider._internal();

  final _supabase = Supabase.instance.client;
  final int _totalGoals = 2;

  SubscriptionModel? subscription;
  Offerings? _offerings;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  StreamSubscription<AuthState>? _authSubscription;
  int currentMonthGoalLeft = 0;

  // Getters
  Offerings? get offerings => _offerings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isPro =>
      subscription?.isPro ?? false || RevenueCatConfig.isBetaFreeTrial;
  bool get isFree => subscription?.isFree ?? true;
  bool get isTrialing => subscription?.isTrialing ?? false;

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  Future<void> onUserSign(bool isSignIn) async {
    if (isSignIn) {
      final user = _supabase.auth.currentUser;
      await RevenueCatService().login(user!.id);
      await loadUserSubdata();
    } else {
      subscription = null;
      await RevenueCatService().logout();
    }
    notifyListeners();
  }

  /// 初始化
  Future<void> initialize() async {
    try {
      await RevenueCatService().initialize();
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await RevenueCatService().login(user.id);
        await loadUserSubdata();
        await loadOfferings();
        final createdGoals = await getCurrentMonthGoalsCount();
        currentMonthGoalLeft = (_totalGoals - createdGoals).clamp(
          0,
          _totalGoals,
        );
      }
    } catch (e) {
      debugPrint('❌ SubscriptionProvider 初始化失败: $e');
    } finally {
      notifyListeners();
    }
  }

  /// 获取当前月创建的目标数量
  Future<int> getCurrentMonthGoalsCount() async {
    if (PlanProvider().allPlans.isEmpty) {
      await PlanProvider().getAllPlans();
    }
    final plans = PlanProvider().allPlans;
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);

    return plans.where((plan) {
      final planMonth = DateTime(plan.createdAt.year, plan.createdAt.month);
      return planMonth == currentMonth;
    }).length;
  }

  /// 测试 RevenueCat 配置
  Future<void> testRevenueCatConfig() async {
    try {
      if (kDebugMode) {
        debugPrint('🔍 测试 RevenueCat 配置...');
        debugPrint('📦 API Key: ${RevenueCatConfig.apiKeyIOS}');
      }

      // 1. 获取 Offerings
      final offerings = await Purchases.getOfferings();

      if (kDebugMode) {
        debugPrint('✅ Offerings 加载成功');
        debugPrint('📋 所有 Offerings: ${offerings.all.keys.toList()}');
        debugPrint(
          '📋 当前 Offering: ${offerings.current?.identifier ?? "null"}',
        );
      }

      // 2. 检查产品
      if (offerings.current != null) {
        final packages = offerings.current!.availablePackages;

        if (kDebugMode) {
          debugPrint('📦 可用产品数量: ${packages.length}');

          for (var package in packages) {
            final product = package.storeProduct;
            debugPrint('');
            debugPrint('📦 Package: ${package.identifier}');
            debugPrint('   Product ID: ${product.identifier}');
            debugPrint('   显示名称: ${product.title}');
            debugPrint('   价格: ${product.priceString}');
            debugPrint('   周期: ${product.subscriptionPeriod}');

            // ✅ 检查免费试用
            if (product.introductoryPrice != null) {
              final intro = product.introductoryPrice!;
              debugPrint('   ✅ 免费试用:');
              debugPrint('      价格: ${intro.priceString}');
              debugPrint('      时长: ${intro.period}');
              debugPrint('      周期数: ${intro.cycles}');
            } else {
              debugPrint('   ⚠️ 没有免费试用');
            }
          }
        }

        // 3. 验证配置完整性
        if (packages.length != 2) {
          debugPrint('⚠️ 警告: 应该有 2 个产品，实际有 ${packages.length} 个');
        }

        final hasMonthly = packages.any(
          (p) => p.storeProduct.identifier == 'toneup_monthly_sub',
        );
        final hasAnnual = packages.any(
          (p) => p.storeProduct.identifier == 'toneup_annually_sub',
        );

        if (!hasMonthly) {
          debugPrint('❌ 缺少月订阅产品');
        }
        if (!hasAnnual) {
          debugPrint('❌ 缺少年订阅产品');
        }

        if (hasMonthly && hasAnnual && packages.length == 2) {
          debugPrint('');
          debugPrint('🎉 RevenueCat 配置完全正确！');
        }
      } else {
        debugPrint('❌ 当前 Offering 为空');
        debugPrint('💡 请检查 RevenueCat Dashboard 的 Offerings 配置');
      }
    } catch (e) {
      debugPrint('❌ 测试失败: $e');
    }
  }

  /// 从 Supabase 加载订阅信息
  Future<void> loadUserSubdata() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 先从 Supabase 获取
      final data = await _supabase
          .from('subscriptions')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (data != null) {
        subscription = SubscriptionModel.fromJson(data);
      } else {
        // 如果数据库没有记录，创建一个免费账户记录
        await _createFreeSubscription(user.id);
      }

      // 同时从 RevenueCat 同步最新状态
      await _syncFromRevenueCat();
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('❌ 加载订阅信息失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 创建免费订阅记录
  Future<void> _createFreeSubscription(String userId) async {
    try {
      final data = await _supabase
          .from('subscriptions')
          .insert({'user_id': userId, 'status': 'free'})
          .select()
          .single();

      subscription = SubscriptionModel.fromJson(data);
    } catch (e) {
      debugPrint('❌ 创建免费订阅记录失败: $e');
    }
  }

  /// 从 RevenueCat 同步状态
  Future<void> _syncFromRevenueCat() async {
    if (kIsWeb) return;

    try {
      final customerInfo = await RevenueCatService().getCustomerInfo();
      // 同步到 Supabase
      if (customerInfo == null) return;
      await RevenueCatService().syncSubscriptionToSupabase(customerInfo);
      // 重新从数据库加载
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase
            .from('subscriptions')
            .select()
            .eq('user_id', user.id)
            .single();
        subscription = SubscriptionModel.fromJson(data);
        debugPrint('✅ 同步后的订阅状态:');
        debugPrint('   Status: ${subscription!.status.name}');
        debugPrint('   Is Pro: ${subscription!.isPro}');
        debugPrint('   Tier: ${subscription!.tier?.name}');
        debugPrint('   ----------------------------------');
        debugPrint('   Subscription sta: ${subscription!.subscriptionStartAt}');
        debugPrint('   Subscription end: ${subscription!.subscriptionEndAt}');
        debugPrint(
          '   Trial: ${subscription!.trialStartAt} -> ${subscription!.trialEndAt}',
        );
      }
    } catch (e) {
      debugPrint('❌ 从 RevenueCat 同步失败: $e');
    }
  }

  /// 加载可用产品
  Future<void> loadOfferings() async {
    try {
      _offerings = await RevenueCatService().getOfferings();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ 加载产品失败: $e');
    }
  }

  /// 购买订阅
  Future<bool> purchase(Package package) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final customerInfo = await RevenueCatService().purchasePackage(package);
      if (customerInfo != null) {
        await loadUserSubdata(); // 重新加载订阅状态
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = '购买失败: $e';
      debugPrint('❌ 购买失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 恢复购买
  Future<bool> restorePurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await RevenueCatService().restorePurchases();
      await loadUserSubdata();
      return true;
    } catch (e) {
      _errorMessage = '恢复购买失败: $e';
      debugPrint('❌ 恢复购买失败: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
