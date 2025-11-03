import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/profile_model.dart';
import 'package:toneup_app/models/user_score_records_model.dart';
import 'package:toneup_app/providers/plan_provider.dart';
import 'package:toneup_app/services/data_service.dart';

class ProfileProvider extends ChangeNotifier {
  // 单例
  static final ProfileProvider _instance = ProfileProvider._internal();
  factory ProfileProvider() => _instance;

  ProfileProvider._internal() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedOut) {
        cleanProfile();
      }
    });
  }

  ProfileModel? _profileModel;
  List<UserScoreRecordsModel>? _records;
  // getter..
  ProfileModel? get profile => _profileModel;
  List<UserScoreRecordsModel>? get records => _records;

  /// 清除个人资料
  void cleanProfile() {
    _profileModel = null;
  }

  /// 更新计划数
  Future<void> updatePlan() async {
    if (_profileModel != null) {
      _profileModel!.plans = PlanProvider().allPlans.length;
      final totalPractice = PlanProvider().allPlans.fold(
        0,
        (sum, plan) => sum + plan.practices.length,
      );
      _profileModel!.practices = totalPractice;
      notifyListeners();
      await saveProfile();
    }
  }

  /// 更新级别
  Future<void> updateLevel(int level) async {
    if (_profileModel != null) {
      _profileModel!.level = level;
      notifyListeners();
    }
  }

  /// 更新学习材料档案
  Future<void> updateMaterials() async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("用户未登录");
    try {
      final data = await DataService().fetchUserScoreRecord(user.id);
      final uniqueMap = <String, UserScoreRecordsModel>{};
      for (var record in data) {
        uniqueMap[record.item] = record;
      }
      _records = uniqueMap.values.toList();

      if (_profileModel != null) {
        _profileModel!.characters = _records!
            .where((item) => item.category == MaterialContentType.character)
            .length;
        _profileModel!.words = _records!
            .where((item) => item.category == MaterialContentType.word)
            .length;
        _profileModel!.sentences = _records!
            .where((item) => item.category == MaterialContentType.sentence)
            .length;
      }
      await saveProfile();
    } catch (e) {
      if (kDebugMode) print("更新学习材料档案-失败：$e");
    } finally {
      notifyListeners();
    }
  }

  /// 获取个人资料
  Future<ProfileModel?> fetchProfile() async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("用户未登录");
    try {
      final data = await DataService().fetchProfile(user.id);
      _profileModel = data;
    } catch (e) {
      if (kDebugMode) print("获取个人资料-失败：$e");
    } finally {
      notifyListeners();
    }
    return _profileModel;
  }

  /// 保存个人资料
  Future<void> saveProfile() async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("用户未登录");
    try {
      if (_profileModel != null) {
        DataService().saveProfile(_profileModel!);
      }
    } catch (e) {
      if (kDebugMode) print("保存个人资料失败：$e");
    } finally {
      notifyListeners();
    }
  }
}
