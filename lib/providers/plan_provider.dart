import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import '../services/user_plan_service.dart';
import '../models/user_weekly_plan_model.dart';

class PlanProvider extends ChangeNotifier {
  final UserPlanService _planService = UserPlanService();
  UserWeeklyPlanModel? _activePlan; // 当前激活的计划
  List<UserWeeklyPlanModel> _allPlans = []; // 所有计划
  bool _isLoading = false;
  String? _errorMessage;
  String? _loadingMessage;
  Function? _retryFunc;
  String? _retryLabel;

  //  getter 方法（供UI获取状态）
  UserWeeklyPlanModel? get activePlan => _activePlan;
  List<UserWeeklyPlanModel> get allPlans => _allPlans;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get loadingMessage => _loadingMessage;
  Function? get retryFunc => _retryFunc;
  String? get retryLabel => _retryLabel;

  /// 刷新当前激活的计划（供外部调用）
  void refreshPlan() {
    notifyListeners();
  }

  /// 初始化：获取当前激活的计划
  Future<void> initialize() async {
    try {
      _retryFunc = null;
      _isLoading = true;
      _errorMessage = null;
      _loadingMessage = "initializing...";
      notifyListeners(); // 通知UI加载中

      final User? user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      // 并行获取激活计划和所有计划（优化性能）
      _loadingMessage = "Loading Active Plan...";
      notifyListeners(); // 通知UI加载中
      final plan = await _planService.fetchActivePlan(user.id);
      if (plan != null) {
        _activePlan = await _planService.fetchPracticeByPlan(plan);
      }
    } catch (e) {
      _errorMessage = e.toString();
      _retryLabel = 'Retry';
      _retryFunc = initialize;
      if (kDebugMode) print("初始化计划失败：$e");
    } finally {
      _isLoading = false;
      notifyListeners(); // 通知UI更新
    }
  }

  /// 获取所有计划
  Future<void> getAllPlans() async {
    try {
      _retryFunc = null;
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      _loadingMessage = "Loading User's All Plans...";
      notifyListeners(); // 通知UI加载中

      _allPlans = await _planService.fetchPlans(user.id);
      _activePlan = await _planService.fetchPracticeByPlan(
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
  Future<void> createPlan() async {
    try {
      _retryFunc = null;
      _isLoading = true;
      _errorMessage = null;
      _loadingMessage = "Creating a New Plan...";
      notifyListeners(); // 通知UI加载中

      final User? user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      await _planService.updateOldActivePlansToPending(
        userId: user.id,
        plans: _allPlans,
      );
      await _planService.createNewActivePlan(user.id);
      await getAllPlans(); // 创建后刷新列表
    } catch (e) {
      _errorMessage = e.toString();
      _retryLabel = 'Retry';
      _retryFunc = createPlan;
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
      _loadingMessage = "Set Plan to Active";
      notifyListeners();

      final User? user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      await _planService.updateOldActivePlansToPending(
        userId: user.id,
        plans: _allPlans,
      );
      await _planService.markPlanAsActive(userId: user.id, plan: plan);
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
}

double calculatePlanProgress(UserWeeklyPlanModel? plan) {
  if (plan == null) return 0.0;
  final passed = plan.practiceData!.fold<int>(
    0,
    (s, p) => (s + (p.score > 0 ? 1 : 0)),
  );
  return (passed / plan.practiceData!.length).clamp(0.04, 1.0);
}
