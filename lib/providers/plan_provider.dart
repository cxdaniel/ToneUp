import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/indicator_result_model.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/services/data_service.dart';
import '../models/user_weekly_plan_model.dart';

class PlanProvider extends ChangeNotifier {
  UserWeeklyPlanModel? _activePlan; // 当前激活的计划
  List<UserWeeklyPlanModel> _allPlans = []; // 所有计划
  bool _isLoading = true;
  String? _errorMessage;
  String? _loadingMessage;
  VoidCallback? _retryFunc;
  String? _retryLabel;
  bool _disposed = false;
  IndicatorResultModel? indicatorResult;

  //  getter 方法（供UI获取状态）
  UserWeeklyPlanModel? get activePlan => _activePlan;
  List<UserWeeklyPlanModel> get allPlans => _allPlans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get loadingMessage => _loadingMessage;
  VoidCallback? get retryFunc => _retryFunc;
  String? get retryLabel => _retryLabel;
  bool showUpgrade = false;

  // 单例
  static final PlanProvider _instance = PlanProvider._internal();
  factory PlanProvider() => _instance;
  PlanProvider._internal() {
    debugPrint('PlanProvider 构造函数执行');
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        // 登出事件触发时执行清理操作
        cleanAllPlans();
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  /// 用户退出登录初始当前数据
  void cleanAllPlans() {
    _activePlan = null;
    _allPlans = [];
  }

  /// 刷新当前激活的计划（供外部调用）
  void refreshPlan() {
    notifyListeners();
  }

  Future<void> checkForUpgrade() async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("用户未登录");
    final res = await DataService().getUserIndicatorResult(
      user.id,
      _activePlan!.level,
    );
    showUpgrade = res.isEligibleForUpgrade;
    indicatorResult = res;
    debugPrint('checkForUpgrade>> ${res.toJson()}');
    notifyListeners();
  }

  /// 初始化：获取当前激活的计划
  Future<void> initialize() async {
    try {
      _retryFunc = null;
      _isLoading = true;
      _errorMessage = null;
      _loadingMessage = "initializing...";
      notifyListeners();

      final User? user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      // 获取激活计划和所有计划
      _loadingMessage = "Fetch Active Goal...";
      notifyListeners();
      final plan = await DataService().fetchActivePlan(user.id);
      if (plan != null) {
        _loadingMessage = "Setup Practices...";
        notifyListeners();
        _activePlan = await DataService().fetchPracticeByPlan(plan);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _retryLabel = 'Retry';
      _retryFunc = initialize;
      if (kDebugMode) print("初始化计划失败：$e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取所有计划
  Future<void> getAllPlans() async {
    try {
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      _retryFunc = null;
      _isLoading = true;
      _errorMessage = null;
      _loadingMessage = "Loading All Goals...";
      notifyListeners();
      _allPlans = await DataService().fetchPlans(user.id);
      //TODO：这里可以优化去掉在获取allplan的时候指定激活计划
      _loadingMessage = "Fetch Active Goal...";
      notifyListeners();
      _activePlan = await DataService().fetchPracticeByPlan(
        allPlans
            .where(
              (plan) =>
                  plan.status == PlanStatus.active ||
                  plan.status == PlanStatus.reactive,
            )
            .firstOrNull,
      );
    } catch (e) {
      _errorMessage = e.toString();
      _retryLabel = 'Retry';
      _retryFunc = getAllPlans;
      if (kDebugMode) print("计划读取失败：$e");
    } finally {
      _isLoading = false;
      notifyListeners(); // 通知UI更新
    }
  }

  /// 创建计划
  Future<void> createPlan({int level = 1}) async {
    try {
      _retryFunc = null;
      _isLoading = true;
      _errorMessage = null;
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      _loadingMessage = "Creating a New Goal...";
      notifyListeners();
      await DataService().updateOldActivePlansToPending(
        userId: user.id,
        plans: _allPlans,
      );
      await DataService().createNewActivePlan(user.id, level);
      _loadingMessage = "Updating All Goals...";
      notifyListeners();
      await getAllPlans();
      //更新profile
      ProfileProvider().updatePlan();
    } catch (e) {
      _errorMessage = e.toString();
      _retryLabel = 'Retry';
      _retryFunc = () => createPlan(level: level);
      if (kDebugMode) debugPrint("创建计划失败：$e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 切换激活计划（核心方法）
  Future<void> activatePlan(UserWeeklyPlanModel plan) async {
    try {
      _retryFunc = null;
      _isLoading = true;
      _errorMessage = null;

      _loadingMessage = "Marking to Active";
      notifyListeners();
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      await DataService().updateOldActivePlansToPending(
        userId: user.id,
        plans: _allPlans,
      );
      await DataService().markPlanAsActive(userId: user.id, plan: plan);

      _loadingMessage = "Updating All Goals...";
      notifyListeners();
      await getAllPlans();
    } catch (e) {
      _retryLabel = 'Retry';
      _retryFunc = () => activatePlan(plan);
      _errorMessage = e.toString();
      if (kDebugMode) print("激活计划失败：$e");
    } finally {
      _isLoading = false;
      notifyListeners(); // 通知UI状态已更新
    }
  }

  /// 完成当前计划
  Future<void> completeActivePlan() async {
    // 前端改状态，只有在切换计划时，才保存数据库
    _activePlan!.status = PlanStatus.reactive;
  }

  /// 从所有计划中按级别和月份分组（供PlanPage使用）
  Map<int, Map<String, List<UserWeeklyPlanModel>>> groupPlansByLevelAndMonth() {
    final levelMap = <int, Map<String, List<UserWeeklyPlanModel>>>{};

    for (final plan in _allPlans) {
      final int level = plan.level;
      // 生成月份标识（如 "2025-08"）
      final String monthKey =
          "${plan.createdAt.year}-"
          "${plan.createdAt.month.toString().padLeft(2, '0')}";

      // 初始化级别分组
      if (!levelMap.containsKey(level)) {
        levelMap[level] = {};
      }
      // 初始化月份分组
      if (!levelMap[level]!.containsKey(monthKey)) {
        levelMap[level]![monthKey] = [];
      }
      // 添加计划到分组
      levelMap[level]![monthKey]!.add(plan);
    }

    return levelMap;
  }

  /// 更新计划进度
  Future<void> updateProgress() async {
    if (_activePlan == null) return;
    DataService().updatePlanProgress(
      planId: _activePlan!.id,
      progress: calculatePlanProgress(_activePlan),
    );
  }
}

double calculatePlanProgress(UserWeeklyPlanModel? plan) {
  if (plan == null || plan.practiceData == null) return 0.0;
  final passed = plan.practiceData!.fold<int>(
    0,
    (s, p) => (s + (p.score > 0 ? 1 : 0)),
  );
  return (passed / plan.practiceData!.length).clamp(0.04, 1.0);
}
