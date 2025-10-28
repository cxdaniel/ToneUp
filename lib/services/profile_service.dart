import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/profile_model.dart';
import 'package:toneup_app/models/user_score_records_model.dart';

class ProfileService {
  static final ProfileService _instance = ProfileService._internal();
  factory ProfileService() => _instance;
  ProfileService._internal();
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 获取用户资料
  Future<ProfileModel?> fetchProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
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
}
