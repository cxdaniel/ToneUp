import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:toneup_app/models/activity_model.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/indicator_result_model.dart';
import 'package:toneup_app/models/indicators_model.dart';
import 'package:toneup_app/models/profile_model.dart';
import 'package:toneup_app/models/quizzes/quiz_base.dart';
import 'package:toneup_app/models/quizzes/quizes_modle.dart';
import 'package:toneup_app/models/user_practice_model.dart';
import 'package:toneup_app/models/user_score_records_model.dart';
import 'package:toneup_app/models/user_weekly_plan_model.dart';
import 'package:toneup_app/services/config.dart';

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
          .from('active_user_weekly_plans')
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

  /// 查询用户当前的 active 计划（无则返回null）
  /// @param userId：当前用户ID
  /// @return 活跃计划数据（Map）或 null
  Future<UserWeeklyPlanModel?> fetchActivePlan(String userId) async {
    try {
      final data = await _supabase
          .from('active_user_weekly_plans')
          .select() // 按需调整返回字段，如只返回需要的字段：'id, start_date, end_date, status'
          .eq('user_id', userId)
          .or('status.eq.active,status.eq.reactive')
          .order('created_at', ascending: false)
          .limit(1)
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
          .from('active_user_practices')
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

  /// 生成学习计划（带进度回调）
  Stream<Map<String, dynamic>> generatePlanWithProgress({
    required String userId,
    required List<int> inds,
    int dur = 60,
    List<String>? acts,
  }) async* {
    final session = _supabase.auth.currentSession;
    final url = '${SupabaseConfig.url}/functions/v1/create-plan';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${session?.accessToken}',
      'apikey': SupabaseConfig.anonKey,
    };
    final request = http.Request('POST', Uri.parse(url));
    request.headers.addAll(headers);
    request.body = json.encode({
      'user_id': userId,
      'inds': inds,
      'dur': dur,
      'acts': acts,
    });

    final response = await request.send();

    if (response.statusCode != 200) {
      throw Exception('请求失败: ${response.statusCode}');
    }
    String buffer = '';
    // 逐行读取流式响应
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      // 将新数据追加到缓冲区
      buffer += chunk;
      // 按换行符分割，保留最后一个可能不完整的部分
      final lines = buffer.split('\n');
      // 最后一行可能不完整，保留在缓冲区中
      buffer = lines.last;
      // 处理完整的行（除了最后一行）
      for (int i = 0; i < lines.length - 1; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        try {
          final data = json.decode(line) as Map<String, dynamic>;
          yield data;
        } catch (e) {
          if (kDebugMode) {
            debugPrint('解析错误: $e, 原始数据: $line');
          }
        }
      }
    }
    // 处理缓冲区中剩余的数据
    if (buffer.trim().isNotEmpty) {
      try {
        final data = json.decode(buffer.trim()) as Map<String, dynamic>;
        yield data;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('解析最后一条数据错误: $e, 原始数据: $buffer');
        }
      }
    }
  }

  /// 激活某个已存在的计划（将其改为 active，旧 active 改为 pending）
  /// @param userId：当前用户ID
  /// @param targetPlanId：要激活的计划ID（数据库中的 id 字段）
  Future<UserWeeklyPlanModel?> markPlanAsActive({
    required String userId,
    required UserWeeklyPlanModel plan,
  }) async {
    try {
      final result =
          await _supabase.rpc(
                'activate_plan',
                params: {'p_user_id': userId, 'p_plan_id': plan.id},
              )
              as List<dynamic>;
      if (result.isEmpty) {
        if (kDebugMode) {
          debugPrint('⚠️ 未找到计划 ID: ${plan.id} 或更新失败');
        }
        return null;
      }
      final activatedPlan = UserWeeklyPlanModel.fromJson(result.first);
      if (kDebugMode) {
        debugPrint('✅ 已激活计划: ${activatedPlan.id}');
      }
      return activatedPlan;
    } catch (e) {
      if (kDebugMode) {
        debugPrint("❌ 更新计划异常：${e.toString()}");
      }
      throw Exception("更新计划状态失败：${e.toString()}");
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

  /// 按id获取quizes
  Future<List<QuizesModle>> fetchQuizesByIds(List<int> data) async {
    try {
      final response = await _supabase
          .from('active_quizes')
          .select()
          .inFilter('id', data);
      if (response.isEmpty) {
        throw Exception("按id获取quizes-返回数组为空");
      }
      final ret = response.map((e) => (QuizesModle.fromJson(e))).toList();
      return ret;
    } catch (e) {
      throw Exception('按id获取quizes-失败: $e');
    }
  }

  /// 生成练习题内容
  Future<List<QuizesModle>> generateQuizesContent(List<int> data) async {
    try {
      final response = await _supabase.functions.invoke(
        "get_activity_instances",
        body: {"ids": json.encode(data)},
      );
      if (response.status != 200) {
        throw Exception("生成练习题返回活动实例数组-状态码 ${response.status}");
      }
      final actInstances = response.data as List<dynamic>;
      if (actInstances.isEmpty) {
        throw Exception("生成练习题返回活动实例数组-异常:返回数组为空");
      }
      final ret = actInstances.map((e) => (QuizesModle.fromJson(e))).toList();

      return ret;
    } catch (e) {
      throw Exception('生成练习题返回活动实例数组-失败: $e');
    }
  }

  /// 更新关联数据activity到quizes
  Future<void> addActivityToQuizesModel(List<QuizesModle> quizes) async {
    final actIds = quizes.map((a) => a.activityId).toList();
    try {
      final data = await _supabase
          .schema('research_core')
          .from('activities')
          .select()
          .inFilter('id', actIds);

      final activiteis = data.map((e) => ActivityModel.fromJson(e)).toList();

      for (QuizesModle quiz in quizes) {
        quiz.activity = activiteis.firstWhere(
          (act) => act.id == quiz.activityId,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("addActivityToQuizesModel 更新关联数据-异常：${e.toString()}");
      }
      throw Exception("addActivityToQuizesModel 更新关联数据-失败：${e.toString()}");
    }
  }

  /// 更新关联数据indicator到quizes
  Future<void> addIndicatorToQuizesModel(List<QuizesModle> quizes) async {
    final indIds = quizes.map((a) => a.indicatorId).toList();
    try {
      final data = await _supabase
          .schema('research_core')
          .from('indicators')
          .select()
          .inFilter('id', indIds);

      final indicators = data.map((e) => IndicatorsModel.fromJson(e)).toList();

      for (QuizesModle quiz in quizes) {
        quiz.indicator = indicators.firstWhere(
          (ind) => ind.id == quiz.indicatorId,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("addIndicatorToQuizesModel 更新关联数据-异常：${e.toString()}");
      }
      throw Exception("addIndicatorToQuizesModel 更新关联数据-失败：${e.toString()}");
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
      final dataList = await _supabase.rpc<List<Map<String, dynamic>>>(
        'increment_practice_count',
        params: {
          'practice_id': practice.id,
          'new_score': total / quizzes.length,
        },
      );
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
          'indicator_id': quizzes[i].model.indicatorId,
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
          .from('active_profiles')
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
  Future<List<QuizesModle>> fetchEvaluationQuizes(int level) async {
    try {
      final data = await _supabase
          .schema('research_core')
          .rpc<List<Map<String, dynamic>>>(
            'random_evaluation',
            params: {'level_input': level, 'n': 10},
          );
      return data.map((item) => QuizesModle.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint("获取评测题目-异常：${e.toString()}");
      }
      throw Exception("获取评测题目-失败：${e.toString()}");
    }
  }

  /// 获取用户当前级别指标完成情况
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

  /// 计算并获取重点关注指标
  /// @param indicators：用户指标列表
  /// @param quentity：要返回的重点指标数量，默认3个
  /// @return 重点关注指标列表
  Future<List<IndicatorCoreDetailModel>> getFocusedIndicators(
    List<IndicatorCoreDetailModel> indicators, {
    int quentity = 3,
  }) async {
    for (var ind in indicators) {
      final importanceScore = ind.indicatorWeight; // 重要性得分（0-1）
      final gapRatio = ind.minimum + ind.practiceGap == 0
          ? 0
          : ind.practiceGap / (ind.minimum + ind.practiceGap); // 达标差距占比
      final completionRate = ind.minimum == 0
          ? 0
          : ind.practiceCount / ind.minimum; // 完成度
      final insufficientScore = 1 - completionRate; //完成度不足得分
      final priorityScore =
          importanceScore * 0.4 + gapRatio * 0.35 + insufficientScore * 0.25;
      ind.priorityScore = priorityScore;
    }
    indicators.sort((a, b) {
      return b.priorityScore!.compareTo(a.priorityScore!);
    });
    quentity = quentity > indicators.length ? indicators.length : quentity;
    final focusedIndicators = indicators.take(quentity).toList();
    return focusedIndicators;
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
