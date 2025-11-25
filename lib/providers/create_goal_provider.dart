import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/indicator_result_model.dart';
import 'package:toneup_app/services/data_service.dart';

class CreateGoalProvider with ChangeNotifier {
  bool isLoading = false;
  bool isCreated = false;
  String? errorMessage;
  String? loadingMessage;
  IndicatorResultModel? indicatorResult;
  List<IndicatorCoreDetailModel>? focusedIndicators;

  Future<void> getResultfromHistory(int level) async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("用户未登录");

    isLoading = true;
    errorMessage = null;
    loadingMessage = 'Analyzing your practice data...';
    notifyListeners();

    try {
      // 调用数据服务创建新目标
      indicatorResult = await DataService().getUserIndicatorResult(
        user.id,
        level,
      );
      if (indicatorResult == null) {
        throw Exception("未能获取指标结果");
      }
      indicatorResult?.coreIndicatorDetails.forEach((ind) {
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
      });
      indicatorResult?.coreIndicatorDetails.sort((a, b) {
        return b.priorityScore!.compareTo(a.priorityScore!);
      });
      focusedIndicators = indicatorResult!.coreIndicatorDetails
          .take(3)
          .toList();
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
    notifyListeners();

    try {
      // 调用数据服务创建新目标
      // await DataService().createNewActivePlan(user.id, level);
      await Future.delayed(Duration(seconds: 12)); // 模拟网络请求延迟
      isCreated = true;
    } catch (e) {
      errorMessage = '创建目标失败: $e';
      rethrow;
    } finally {
      isLoading = false;
      loadingMessage = null;
      notifyListeners();
    }
  }
}
