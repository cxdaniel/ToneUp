import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/activity_model.dart';
import 'package:toneup_app/models/quizzes/quiz_model.dart';
import 'package:toneup_app/models/user_activity_instances_model.dart';
import 'package:toneup_app/models/user_practice_model.dart';

class UserActivityService {
  // 单例模式：确保全局只有一个服务实例
  static final UserActivityService _instance = UserActivityService._internal();
  factory UserActivityService() => _instance;
  UserActivityService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

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
      final acts = await _supabase
          .from('user_activity_instances')
          .select()
          .inFilter('id', data);

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

  /// 获取每个练习实例对应的活动库数据activity
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
        debugPrint("fetchPlans 查询所有计划异常：${e.toString()}");
      }
      throw Exception("fetchPlans 查询所有计划失败：${e.toString()}");
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
          'practice_id': practice.id, // int 即可
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
      final records = quizzes
          .map(
            (q) => ({
              'category': q.result.category.name,
              'item': q.result.item,
              'score': q.result.score,
              'user_id': user!.id,
            }),
          )
          .toList();
      if (user == null) throw Exception("用户未登录");
      final recordData = await _supabase
          .from('user_score_records')
          .insert(records)
          .select();

      /// 保存到 user_ability_history 表（供能力趋势图使用）
      List abilityData = [];
      for (var i = 0; i < quizzes.length; i++) {
        abilityData.add({
          'user_id': user.id,
          'indicator_id': quizzes[i].actInstance.indicatorId,
          'score': quizzes[i].result.score,
        });
      }
      final userAbilityData = await _supabase
          .from('user_ability_history')
          .insert(abilityData)
          .select();

      /// 循环更新 user_activity_instances 的score
      /// TODO: 减少多余数据交互，去掉练习实例的score保存
      // for (var i = 0; i < quizzes.length; i++) {
      //   final res = await _supabase
      //       .from('user_activity_instances')
      //       .update({
      //         'score': quizzes[i].result.score,
      //         'update_at': DateTime.now().toIso8601String(),
      //       })
      //       .eq('id', quizzes[i].actInstance.id)
      //       .select();
      //   if (kDebugMode) {
      //     debugPrint(
      //       'user_activity_instances保存成功:${quizzes[i].actInstance.id}>>>$res',
      //     );
      //   }
      // }
      if (kDebugMode) {
        debugPrint('user_score_records 保存练习数据成功: $recordData');
        debugPrint('user_ability_history 用户能力保存成功: $userAbilityData');
      }
    } catch (e) {
      throw Exception("saveResultScores 保存练习数据失败：${e.toString()}");
    }
  }
}
