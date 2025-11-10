import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:toneup_app/models/activity_model.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/evaluation_model.dart';
import 'package:toneup_app/models/indicator_result_model.dart';
import 'package:toneup_app/models/indicators_model.dart';
import 'package:toneup_app/models/profile_model.dart';
import 'package:toneup_app/models/quizzes/quiz_model.dart';
import 'package:toneup_app/models/user_activity_instances_model.dart';
import 'package:toneup_app/models/user_practice_model.dart';
import 'package:toneup_app/models/user_score_records_model.dart';
import 'package:toneup_app/models/user_weekly_plan_model.dart';

/// 用户学习计划服务类：封装所有计划相关的业务逻辑（查询、创建、激活等）
class DataService {
  // 单例模式：确保全局只有一个服务实例
  static final DataService _instance = DataService._internal();
  factory DataService() => _instance;
  DataService._internal();

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
  Future<UserWeeklyPlanModel> createNewActivePlan(
    String userId,
    int level,
  ) async {
    try {
      // await updateOldActivePlansToPending(userId);
      final createResponse = await _supabase.functions.invoke(
        "get-focus-indicators",
        body: {"user_id": userId, "level": level},
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

  /// 获取practice下的所有练习实例instance
  Future<List<UserActivityInstanceModel>> getPracticeInstances(
    List<int> data,
  ) async {
    try {
      final response = await _supabase
          .from('user_activity_instances')
          .select()
          .inFilter('id', data);
      if (response.isEmpty) {
        throw Exception("查询活动库实例异常：返回数组为空");
      }
      final ret = response
          .map((e) => (UserActivityInstanceModel.fromJson(e)))
          .toList();
      return ret;
    } catch (e) {
      throw Exception('查询活动库实例失败: $e');
    }
  }

  /// 生成练习题返回活动实例数组
  Future<List<UserActivityInstanceModel>> generatePracticeQuiz(
    List<int> data,
    String topic,
    String culture,
  ) async {
    try {
      final response = await _supabase.functions.invoke(
        "get_activity_instances",
        body: {
          "act_ins": json.encode(data),
          "topic_tag": topic,
          "culture_tag": culture,
        },
      );
      if (response.status != 200) {
        throw Exception("查询活动库实例：状态码 ${response.status}");
      }
      final actInstances = response.data as List<dynamic>;
      if (actInstances.isEmpty) {
        throw Exception("查询活动库实例异常：返回数组为空");
      }
      final ret = actInstances
          .map((e) => (UserActivityInstanceModel.fromJson(e)))
          .toList();

      return ret;
    } catch (e) {
      throw Exception('查询活动库实例失败: $e');
    }
  }

  /// 更新关联数据activity到活动实例instance
  Future<List<UserActivityInstanceModel>> addActivityToInstances(
    List<UserActivityInstanceModel> datas,
  ) async {
    final actIds = datas.map((a) => a.activityId).toList();
    try {
      final data = await _supabase
          .schema('research_core')
          .from('activities')
          .select()
          .inFilter('id', actIds);

      final activiteis = data.map((e) => ActivityModel.fromJson(e)).toList();

      for (UserActivityInstanceModel instance in datas) {
        instance.activity = activiteis.firstWhere(
          (act) => act.id == instance.activityId,
        );
      }
      return datas;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("addActivityToInstances 更新关联数据-异常：${e.toString()}");
      }
      throw Exception("addActivityToInstances 更新关联数据-失败：${e.toString()}");
    }
  }

  /// 保存练习分数，更新4个数据表：
  /// user_practicers, user_score_records,
  /// user_ability_history,user_activity_instances
  Future<void> saveResultScores(
    List<QuizBase> quizzes,
    UserPracticeModel practice,
  ) async {
    try {
      /// 计算总分和总题数，更新 user_practicers 表（用户当前练习分数）
      final total = quizzes.fold<double>(0, (sum, a) => sum + a.result.score);
      final pData = await _supabase.rpc(
        'increment_practice_count',
        params: {
          'practice_id': practice.id,
          'new_score': total / quizzes.length,
        },
      );
      final dataList = pData as List;
      if (dataList.isEmpty) throw Exception("未返回更新后的记录");
      final update = UserPracticeModel.fromJson(dataList.first);
      practice.count = update.count;
      practice.score = update.score;

      /// 保存每题的得分到 user_score_records 表（供用户材料分数查询）
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("用户未登录");
      final records = quizzes
          .map(
            (q) => ({
              'category': q.result.category!.name,
              'item': q.result.item,
              'score': q.result.score,
              'user_id': user.id,
            }),
          )
          .toList();
      final recordData = await _supabase
          .from('user_score_records')
          .insert(records)
          .select();

      /// 保存到 user_ability_history 表（供能力趋势图使用）
      List abilityData = [];
      for (var i = 0; i < quizzes.length; i++) {
        abilityData.add({
          'user_id': user.id,
          'indicator_id': quizzes[i].indicatorId,
          'score': quizzes[i].result.score,
        });
      }
      final userAbilityData = await _supabase
          .from('user_ability_history')
          .insert(abilityData)
          .select();

      if (kDebugMode) {
        debugPrint('user_score_records 保存练习数据成功: $recordData');
        debugPrint('user_ability_history 用户能力保存成功: $userAbilityData');
      }
    } catch (e) {
      throw Exception("saveResultScores 保存练习数据失败：${e.toString()}");
    }
  }

  /// 获取用户资料
  Future<ProfileModel?> fetchProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      debugPrint('fetchProfile::${json.encode(data)}');
      return data != null ? ProfileModel.fromJson(data) : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("查询用户资料异常：${e.toString()}");
      }
      throw Exception("fetchProfile 获取用户资料失败：${e.toString()}");
    }
  }

  /// 获取学习材料档案
  Future<List<UserScoreRecordsModel>> fetchUserScoreRecord(
    String userId,
  ) async {
    try {
      final data = await _supabase
          .from('user_score_records')
          .select('item,created_at,category,score')
          .eq('user_id', userId)
          .gt('score', 0)
          .inFilter('category', [
            MaterialContentType.character.name,
            MaterialContentType.word.name,
            MaterialContentType.sentence.name,
          ]);

      final records = data
          .map((e) => UserScoreRecordsModel.fromJson(e))
          .toList();
      return records;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("获取学习材料档案-异常：${e.toString()}");
      }
      throw Exception("fetchUserScoreRecord 获取学习材料档案-失败：${e.toString()}");
    }
  }

  /// 保存用户资料
  /// @profile ProfileModel
  Future<ProfileModel?> saveProfile(ProfileModel profile) async {
    try {
      final saveData = profile.toJson();
      final data = await _supabase
          .from('profiles')
          .upsert(
            saveData,
            // 基于id字段进行冲突判断（id是唯一约束字段）
            onConflict: 'id',
            // 遇到重复时不忽略，而是执行更新操作
            ignoreDuplicates: false,
          )
          .select()
          .maybeSingle();
      return data != null ? ProfileModel.fromJson(data) : null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("保存用户资料异常：${e.toString()}");
      }
      throw Exception("saveProfile 保存用户资料失败：${e.toString()}");
    }
  }

  /// 获取评测题目
  Future<List<EvaluationModel>> fetchEvaluations(int level) async {
    try {
      final data = await _supabase
          .schema('research_core')
          .from('evaluation')
          .select()
          .eq('level', level)
          .limit(10);
      // .inFilter('id', actIds);
      return data.map((item) => EvaluationModel.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("获取评测题目-异常：${e.toString()}");
      }
      throw Exception("获取评测题目-失败：${e.toString()}");
    }
  }

  /// 更新关联数据activity到测试数据Evaluation
  Future<List<EvaluationModel>> addActivityToEvaluation(
    List<EvaluationModel> datas,
  ) async {
    final actIds = datas.map((a) => a.activityId).toList();
    try {
      final data = await _supabase
          .schema('research_core')
          .from('activities')
          .select()
          .inFilter('id', actIds);

      final activiteis = data.map((e) => ActivityModel.fromJson(e)).toList();

      for (EvaluationModel evl in datas) {
        evl.activity = activiteis.firstWhere((act) => act.id == evl.activityId);
      }
      return datas;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("addActivityToEvaluation 更新关联数据-异常：${e.toString()}");
      }
      throw Exception("addActivityToEvaluation 更新关联数据-失败：${e.toString()}");
    }
  }

  /// 更新关联数据indicator到测试数据Evaluation
  Future<List<EvaluationModel>> addIndicatorToEvaluation(
    List<EvaluationModel> datas,
  ) async {
    final indIds = datas.map((a) => a.indicatorId).toList();
    try {
      final data = await _supabase
          .schema('research_core')
          .from('indicators')
          .select()
          .inFilter('id', indIds);

      final indicators = data.map((e) => IndicatorsModel.fromJson(e)).toList();

      for (EvaluationModel evl in datas) {
        evl.indicator = indicators.firstWhere(
          (ind) => ind.id == evl.indicatorId,
        );
      }
      return datas;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("addIndicatorToEvaluation 更新关联数据-异常：${e.toString()}");
      }
      throw Exception("addIndicatorToEvaluation 更新关联数据-失败：${e.toString()}");
    }
  }

  /// 获取用户当前级别指标完成情况(是否可升级)
  Future<IndicatorResultModel> getUserIndicatorResult(
    String userId,
    int level,
  ) async {
    try {
      final res = await _supabase.functions.invoke(
        "check_for_upgrade",
        body: {"user_id": userId, "level": level},
      );
      if (res.status != 200) {
        throw Exception("获取用户当前级别指标完成情况失败：状态码 ${res.status}");
      }
      return IndicatorResultModel.fromJson(res.data);
    } catch (e) {
      if (kDebugMode) {
        debugPrint("获取用户当前级别指标完成情况-异常：${e.toString()}");
      }
      throw Exception("获取用户当前级别指标完成情况-失败：${e.toString()}");
    }
  }

  /// 保存用户头像
  Future<void> saveImage(String url, Uint8List data) async {
    try {
      await _supabase.storage
          .from('images')
          .uploadBinary(url, data, fileOptions: FileOptions(upsert: true));
    } catch (e) {
      if (kDebugMode) {
        debugPrint("保存用户头像-异常：${e.toString()}");
      }
      throw Exception("保存用户头像-失败：${e.toString()}");
    }
  }

  /// 获取图片资源
  Future<Uint8List> getImage(String url) async {
    try {
      final data = await _supabase.storage.from('images').download(url);
      return data;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("获取图片资源-异常：${e.toString()}");
      }
      throw Exception("获取图片资源-失败：${e.toString()}");
    }
  }

  /// 更新经验值
  Future<double> saveExp(
    double exp, {
    required String userId,
    required String title,
  }) async {
    try {
      final saveData = {
        'user_id': userId,
        'category': 'exp',
        'event_title': title,
        'event_detail': exp,
        'created_at': DateTime.now().toIso8601String(),
      };
      await _supabase.from('user_event_records').insert(saveData);
      final data = await _supabase
          .from('user_event_records')
          .select()
          .eq('user_id', userId)
          .eq('category', 'exp');
      final totalExp = data.fold(
        0.0,
        (sum, item) => sum + item['event_detail'],
      );
      return totalExp;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("保存用户资料异常：${e.toString()}");
      }
      throw Exception("saveProfile 保存用户资料失败：${e.toString()}");
    }
  }
}
