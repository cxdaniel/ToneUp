// lib/providers/subscription_provider.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/subscription_model.dart';
import 'package:toneup_app/providers/plan_provider.dart';
import 'package:toneup_app/services/revenue_cat_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  static final SubscriptionProvider _instance =
      SubscriptionProvider._internal();
  factory SubscriptionProvider() => _instance;
  SubscriptionProvider._internal() {
    _setupAuthListener();
  }

  final _supabase = Supabase.instance.client;
  final _revenueCat = RevenueCatService();
  final int _totalGoals = 2;

  SubscriptionModel? _subscription;
  Offerings? _offerings;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  StreamSubscription<AuthState>? _authSubscription;
  int currentMonthGoalLeft = 0;

  // Getters
  SubscriptionModel? get subscription => _subscription;
  Offerings? get offerings => _offerings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isPro => _subscription?.isPro ?? false;
  bool get isFree => _subscription?.isFree ?? true;
  bool get isTrialing => _subscription?.isTrialing ?? false;

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

  /// 设置认证监听
  void _setupAuthListener() {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;
      debugPrint('🔔 SubscriptionProvider 收到 auth event: $event');

      if (event == AuthChangeEvent.signedIn) {
        // 用户登录后，初始化 RevenueCat 并加载订阅
        final user = data.session?.user;
        if (user != null) {
          await _revenueCat.login(user.id);
          await loadSubscription();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        // 用户登出，清空订阅数据
        _subscription = null;
        await _revenueCat.logout();
        notifyListeners();
      }
    });
  }

  /// 初始化
  Future<void> initialize() async {
    try {
      await _revenueCat.initialize();
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _revenueCat.login(user.id);
        await loadSubscription();
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

  /// 从 Supabase 加载订阅信息
  Future<void> loadSubscription() async {
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
        _subscription = SubscriptionModel.fromJson(data);
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

      _subscription = SubscriptionModel.fromJson(data);
    } catch (e) {
      debugPrint('❌ 创建免费订阅记录失败: $e');
    }
  }

  /// 从 RevenueCat 同步状态
  Future<void> _syncFromRevenueCat() async {
    try {
      final customerInfo = await _revenueCat.getCustomerInfo();

      await _revenueCat.syncSubscriptionToSupabase(customerInfo);

      // 重新从数据库加载
      final user = _supabase.auth.currentUser;
      if (user != null) {
        final data = await _supabase
            .from('subscriptions')
            .select()
            .eq('user_id', user.id)
            .single();
        _subscription = SubscriptionModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('❌ 从 RevenueCat 同步失败: $e');
    }
  }

  /// 加载可用产品
  Future<void> loadOfferings() async {
    try {
      _offerings = await _revenueCat.getOfferings();
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
      final customerInfo = await _revenueCat.purchasePackage(package);
      if (customerInfo != null) {
        await loadSubscription(); // 重新加载订阅状态
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
      await _revenueCat.restorePurchases();
      await loadSubscription();
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
