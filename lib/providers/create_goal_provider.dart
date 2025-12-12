import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/indicator_result_model.dart';
import 'package:toneup_app/models/user_weekly_plan_model.dart';
import 'package:toneup_app/providers/plan_provider.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/services/data_service.dart';

class CreateGoalProvider with ChangeNotifier {
  bool isLoading = false;
  bool isCreated = false;
  bool _disposed = false;
  String? errorMessage;
  String? loadingMessage;
  List<IndicatorCoreDetailModel>? focusedIndicators;
  Map<int, Map<String, dynamic>>? creatingPlanProgress;
  UserWeeklyPlanModel? newPlan;

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

  Future<void> getResultfromHistory(int level) async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("用户未登录");

    isLoading = true;
    errorMessage = null;
    loadingMessage = 'Analyzing your practice data...';
    notifyListeners();

    try {
      // 调用数据服务创建新目标
      final indicatorResult = await DataService().getUserIndicatorResult(
        user.id,
        level,
      );
      focusedIndicators = await DataService().getFocusedIndicators(
        indicatorResult.coreIndicatorDetails,
        quentity: 3,
      );
    } catch (e) {
      errorMessage = '创建目标失败: $e';
      rethrow;
    } finally {
      isLoading = false;
      loadingMessage = null;
      notifyListeners();
    }
  }

  Future<void> createGoal(int level) async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("用户未登录");

    isLoading = true;
    errorMessage = null;
    loadingMessage = 'Creating your personalized goal...';
    isLoading = true;
    isCreated = false;
    creatingPlanProgress = {};
    notifyListeners();

    try {
      await for (final message in DataService().generatePlanWithProgress(
        userId: user.id,
        inds: focusedIndicators!.map((e) => e.indicatorId).toList(),
      )) {
        final type = message['type'] as String;
        if (type == 'progress') {
          creatingPlanProgress![message['step'] as int] = message;
          loadingMessage = message['message'] as String;
        } else if (type == 'complete') {
          newPlan = UserWeeklyPlanModel.fromJson(message['result']);
          if (newPlan == null) {
            throw Exception('创建目标-异常！！！未收到新计划数据');
          }
          debugPrint('计划创建完成，激活新计划');
          await PlanProvider().activatePlan(newPlan!);
          await ProfileProvider().updatePlanCount();
          isLoading = false;
          isCreated = true;
          loadingMessage = '计划生成完成！';
          debugPrint('新计划已激活: ${newPlan!.id}');
        } else if (type == 'error') {
          // 显示错误提示
          isLoading = false;
          loadingMessage = null;
          errorMessage = '错误: ${message['error']}';
        }
        notifyListeners();
      }

      isCreated = true;
    } catch (e) {
      errorMessage = '创建目标-失败: $e';
      rethrow;
    } finally {
      isLoading = false;
      loadingMessage = null;
      notifyListeners();
    }
  }
}
