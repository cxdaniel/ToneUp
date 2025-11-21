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
    Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        if (event == AuthChangeEvent.signedOut) {
          cleanProfile();
        }
      },
      onError: (error) {
        debugPrint('❌ onAuthStateChange error: $error');
      },
    );
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("用户未登录");
    tempProfile = ProfileModel(id: user.id, level: 1);
  }

  final User? user = Supabase.instance.client.auth.currentUser;
  ProfileModel? _profileModel;
  late ProfileModel tempProfile;
  List<UserScoreRecordsModel>? _records;
  bool _disposed = false;
  // getter..
  ProfileModel? get profile => _profileModel;
  List<UserScoreRecordsModel>? get records => _records;
  Uint8List? avatarBytes;

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

  /// 更新头像
  Future<void> updateAvatar(Uint8List data) async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("用户未登录");
    if (_profileModel != null) {
      avatarBytes = data;
      notifyListeners();
      String url = 'avatas/${user.id}/avatar.jpg';
      await DataService().saveImage(url, data);
      _profileModel!.avatar = url;
      if (kDebugMode) print("更新头像-成功：$url");
      saveProfile();
    }
  }

  /// 更新级别
  Future<void> updateLevel(int level) async {
    if (_profileModel != null) {
      _profileModel!.level = level;
      notifyListeners();
      await saveProfile();
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
      _profileModel = await DataService().fetchProfile(user.id);

      if (_profileModel != null && _profileModel!.avatar != null) {
        avatarBytes = await DataService().getImage(_profileModel!.avatar!);
      }
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
        tempProfile.updatedAt = DateTime.now();
        DataService().saveProfile(_profileModel!);
        if (kDebugMode) print("保存个人资料-成功：${_profileModel!.toJson()}");
      }
    } catch (e) {
      if (kDebugMode) print("保存个人资料失败：$e");
    } finally {
      notifyListeners();
    }
  }

  /// 创建个人资料
  Future<void> createProfile() async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("用户未登录");
    try {
      tempProfile.createdAt = DateTime.now();
      DataService().saveProfile(tempProfile);
    } catch (e) {
      if (kDebugMode) print("创建个人资料-失败：$e");
    } finally {
      notifyListeners();
    }
  }
}
