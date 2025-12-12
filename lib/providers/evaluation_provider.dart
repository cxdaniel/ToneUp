import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/quizzes/quiz_base.dart';
import 'package:toneup_app/models/user_weekly_plan_model.dart';
import 'package:toneup_app/providers/plan_provider.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/services/data_service.dart';

class EvaluationProvider extends ChangeNotifier {
  List<QuizBase> _quizzes = []; // 所有 Quiz 列表
  int _currentQuizIndex = 0; // 当前 Quiz 索引
  bool isLoading = false;
  bool isCreating = false;
  String? errorMessage;
  String? loadingMessage;
  bool _isPracticeCompleted = false; // 练习是否完成
  // Getters
  List<QuizBase> get quizzes => _quizzes;
  int get currentQuizIndex => _currentQuizIndex;
  int get totalQuizzes => _quizzes.length;
  bool get isPracticeCompleted => _isPracticeCompleted;
  QuizBase get currentQuiz => _quizzes[_currentQuizIndex];
  int currentTouchedCount = 0; //记录共做了几题，包含错题
  double get progress =>
      totalQuizzes > 0 ? (_currentQuizIndex + 1) / totalQuizzes : 0;
  VoidCallback? retryFunc;
  String? retryLabel;
  bool _disposed = false;
  double get score {
    final totalScore = quizzes.fold<double>(
      0,
      (sum, quiz) => sum + quiz.result.score * quiz.model.indicator!.weight,
    );
    final totalWeight = quizzes.fold<double>(
      0,
      (sum, quiz) => sum + quiz.model.indicator!.weight,
    );
    return totalScore / totalWeight;
  }

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

  /// 初始化评测数据
  Future<void> initialize(int level) async {
    retryFunc = null;
    try {
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      isLoading = true;
      errorMessage = null;
      loadingMessage = 'Loading evaluation data...';
      notifyListeners();

      final quizesData = await DataService().fetchEvaluationQuizes(level);
      await DataService().addActivityToQuizesModel(quizesData);
      await DataService().addIndicatorToQuizesModel(quizesData);
      _quizzes = QuizBase.getQuizInstanceByType(quizesData);
      for (var quiz in _quizzes) {
        // 测试时可重试次数为0
        quiz.maxRetryTime = 0;
      }
      retryFunc = null;
    } catch (e) {
      errorMessage = e.toString();
      retryLabel = 'Retry';
      retryFunc = () => initialize(level);
      if (kDebugMode) debugPrint('测评初始化失败: $e');
    } finally {
      isLoading = false;
      loadingMessage = null;
      notifyListeners();
    }
  }

  /// 进入下一个 Quiz
  void nextQuiz() {
    // if (currentQuiz.state == QuizState.pass) {
    //做对前进一题
    if (_currentQuizIndex < totalQuizzes - 1) {
      _currentQuizIndex++;
    } else {
      //最后一题正确，结束练习
      _isPracticeCompleted = true;
      notifyListeners();
      return;
    }
    currentTouchedCount++;
    notifyListeners();
  }

  ///  创建用户资料和计划
  Future<void> createProfileAndGoal(int level) async {
    final User? user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("用户未登录");

    isLoading = false;
    retryFunc = null;
    errorMessage = null;
    isCreating = true;
    loadingMessage = 'Creating your personalized goal...';
    notifyListeners();
    try {
      await ProfileProvider().createProfile();
      final indicatorResult = await DataService().getUserIndicatorResult(
        user.id,
        level,
      );
      final focusedIndicators = await DataService().getFocusedIndicators(
        indicatorResult.coreIndicatorDetails,
        quentity: 3,
      );

      await for (final message in DataService().generatePlanWithProgress(
        userId: user.id,
        inds: focusedIndicators.map((e) => e.indicatorId).toList(),
      )) {
        final type = message['type'] as String;
        if (type == 'progress') {
          loadingMessage = message['message'] as String;
        } else if (type == 'complete') {
          final newPlan = UserWeeklyPlanModel.fromJson(message['result']);
          debugPrint('计划创建完成，激活新计划');
          await PlanProvider().activatePlan(newPlan);
          await ProfileProvider().updatePlanCount();
          isCreating = false;
          loadingMessage = '计划生成完成！';
          debugPrint('新计划已激活: ${newPlan.id}');
        } else if (type == 'error') {
          // 显示错误提示
          isCreating = false;
          loadingMessage = null;
          errorMessage = '错误: ${message['error']}';
        }
        notifyListeners();
      }
      isCreating = false;
    } catch (e) {
      errorMessage = e.toString();
      retryLabel = 'Retry';
      retryFunc = () => createProfileAndGoal(level);
      if (kDebugMode) debugPrint("创建用户资料和计划-失败：$e");
      rethrow;
    } finally {
      isCreating = false;
      loadingMessage = null;
      notifyListeners();
    }
  }
}
