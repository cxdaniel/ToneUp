import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/user_practice_model.dart';
import 'package:toneup_app/models/user_weekly_plan_model.dart';

/// 用户学习计划服务类：封装所有计划相关的业务逻辑（查询、创建、激活等）
class UserPlanService {
  // 单例模式：确保全局只有一个服务实例
  static final UserPlanService _instance = UserPlanService._internal();
  factory UserPlanService() => _instance;
  UserPlanService._internal();

  // 初始化Supabase客户端（复用全局实例）
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 查询用户所有plans
  /// @param userId：当前用户ID（从Auth获取）
  Future<List<UserWeeklyPlanModel>> fetchPlans(String userId) async {
    try {
      final data = await _supabase
          .from('user_weekly_plans')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true); // 按创建时间从旧到新排序

      final plans = data.map((e) => UserWeeklyPlanModel.fromJson(e)).toList();
      return plans;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("fetchPlans 查询所有计划异常：${e.toString()}");
      }
      throw Exception("fetchPlans 查询所有计划失败：${e.toString()}");
    }
  }

  /// 将用户所有旧的 active 计划改为 pending
  /// @param userId：当前用户ID（从Auth获取）
  Future<void> updateOldActivePlansToPending({
    required String userId,
    required List<UserWeeklyPlanModel> plans,
  }) async {
    try {
      final toPending = plans
          .where((plan) => plan.status == PlanStatus.active)
          .map((p) {
            return p.id;
          })
          .toList();
      if (toPending.isNotEmpty) {
        await _supabase
            .from('user_weekly_plans')
            .update({'status': PlanStatus.pending.name})
            .eq('user_id', userId)
            .inFilter('id', toPending);
      }
      final toDone = plans
          .where((plan) => plan.status == PlanStatus.reactive)
          .map((p) {
            return p.id;
          })
          .toList();

      if (toDone.isNotEmpty) {
        await _supabase
            .from('user_weekly_plans')
            .update({'status': PlanStatus.done.name})
            .eq('user_id', userId)
            .inFilter('id', toDone);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("更新旧计划异常：${e.toString()}");
      }
      rethrow;
    }
  }

  /// 查询用户当前的 active 计划（无则返回null）
  /// @param userId：当前用户ID
  /// @return 活跃计划数据（Map）或 null
  Future<UserWeeklyPlanModel?> fetchActivePlan(String userId) async {
    try {
      final data = await _supabase
          .from('user_weekly_plans')
          .select() // 按需调整返回字段，如只返回需要的字段：'id, start_date, end_date, status'
          .eq('user_id', userId)
          .or('status.eq.active,status.eq.reactive')
          .order('created_at', ascending: false)
          // .limit(1)
          .maybeSingle();

      final plan = (data != null) ? UserWeeklyPlanModel.fromJson(data) : null;

      return plan;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("查询活跃计划异常：${e.toString()}");
      }
      throw Exception("查询活跃计划失败：${e.toString()}");
    }
  }

  /// 根据计划查询对应的练习数据，并附加到计划对象中
  /// @param plan：用户计划对象（包含 practices 字段）
  /// @return 附加了 practiceData 的计划对象
  Future<UserWeeklyPlanModel?> fetchPracticeByPlan(
    UserWeeklyPlanModel? plan,
  ) async {
    if (plan == null) return null;
    //获取计划下的practice数据
    try {
      final prctData = await _supabase
          .from('user_practices')
          .select()
          .inFilter('id', plan.practices);

      // 重新排序：确保顺序与 plan.practices 一致
      final sortedPrctData = plan.practices
          .map((id) => prctData.firstWhere((p) => p['id'] == id))
          .toList();

      plan.practiceData = sortedPrctData
          .map((e) => UserPracticeModel.fromJson(e))
          .toList();

      return plan;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("查询计划对应练习异常：${e.toString()}");
      }
      throw Exception("查询计划对应练习失败：${e.toString()}");
    }
  }

  /// 创建新的 active 计划（通过Edge Function，同时将旧active改为pending）
  /// @param userId：当前用户ID
  /// @return 新创建的计划数据（包含id、status等）
  Future<UserWeeklyPlanModel> createNewActivePlan(String userId) async {
    try {
      // await updateOldActivePlansToPending(userId);
      final createResponse = await _supabase.functions.invoke(
        "get-focus-indicators",
        body: {"user_id": userId},
      );

      if (createResponse.status != 200) {
        throw Exception("创建计划失败：状态码 ${createResponse.status}");
      }

      final responseList = createResponse.data as List<dynamic>;
      if (responseList.isEmpty) {
        throw Exception("创建计划失败：返回数组为空");
      }
      // 取数组中的第一个元素作为计划数据
      final newPlanData = responseList.first as Map<String, dynamic>;
      return UserWeeklyPlanModel.fromJson(newPlanData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("创建新计划异常：${e.toString()}");
      }
      rethrow;
    }
  }

  /// 激活某个已存在的计划（将其改为 active，旧 active 改为 pending）
  /// @param userId：当前用户ID
  /// @param targetPlanId：要激活的计划ID（数据库中的 id 字段）
  Future<void> markPlanAsActive({
    required String userId,
    required UserWeeklyPlanModel plan,
  }) async {
    try {
      // 先将旧的活跃计划改为pending
      // await updateOldActivePlansToPending(userId);
      if (plan.status == PlanStatus.active ||
          plan.status == PlanStatus.reactive) {
        return;
      } else if (plan.status == PlanStatus.pending) {
        final resP = await _supabase
            .from('user_weekly_plans')
            .update({'status': PlanStatus.active.name})
            // .eq('user_id', userId)
            .eq('id', plan.id)
            .select()
            .maybeSingle();

        if (kDebugMode) {
          debugPrint('激活计划成功: $resP');
        }
      } else if (plan.status == PlanStatus.done) {
        final resD = await _supabase
            .from('user_weekly_plans')
            .update({'status': PlanStatus.reactive.name})
            // .eq('user_id', userId)
            .eq('id', plan.id)
            .select()
            .maybeSingle();
        if (kDebugMode) {
          debugPrint('激活计划成功: $resD');
        }
      }

      return;
    } catch (e) {
      debugPrint("激活计划异常：$e");
      rethrow;
    }
  }

  /// 标记计划为已完成（status → done）
  /// @param userId：当前用户ID
  /// @param planId：要标记完成的计划ID
  Future<void> markPlanAsDone({
    required String userId,
    required int planId,
  }) async {
    try {
      await _supabase
          .from('user_weekly_plans')
          .update({'status': PlanStatus.done.name})
          // .eq('user_id', userId)
          .eq('id', planId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("标记计划完成异常：${e.toString()}");
      }
      rethrow;
    }
  }

  /// 更新计划的进度数据
  Future<void> updatePlanProgress({
    required int planId,
    required double progress,
  }) async {
    try {
      await _supabase
          .from('user_weekly_plans')
          .update({'progress': progress})
          .eq('id', planId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("更新计划的进度异常：${e.toString()}");
      }
      rethrow;
    }
  }
}
