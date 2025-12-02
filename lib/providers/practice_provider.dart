import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/quizzes/quiz_base.dart';
import 'package:toneup_app/models/quizzes/quizes_modle.dart';
import 'package:toneup_app/models/user_practice_model.dart';
import 'package:toneup_app/models/user_weekly_plan_model.dart';
import 'package:toneup_app/providers/plan_provider.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/services/data_service.dart';

class PracticeProvider extends ChangeNotifier {
  List<QuizBase> _quizzes = []; // 所有 Quiz 列表
  int _currentQuizIndex = 0; // 当前 Quiz 索引
  bool _isLoading = false;
  String _errorMessage = '';
  bool _isPracticeCompleted = false; // 练习是否完成
  UserPracticeModel? _practiceData;
  // Getters
  List<QuizBase> get quizzes => _quizzes;
  int get currentQuizIndex => _currentQuizIndex;
  int get totalQuizzes => _quizzes.length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isPracticeCompleted => _isPracticeCompleted;
  QuizBase get currentQuiz => _quizzes[_currentQuizIndex];
  UserPracticeModel? get practiceData => _practiceData;
  int currentTouchedCount = 0; //记录共做了几题，包含错题
  double get progress =>
      totalQuizzes > 0 ? (_currentQuizIndex + 1) / totalQuizzes : 0;
  bool _disposed = false;
  VoidCallback? retryFunc;
  String? retryLabel;
  bool isSaving = false;
  String loadingMessage = '';
  List<String> materials = [];

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // 重写notifyListeners方法
  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  /// 重置练习状态
  void _resetPracticeState() {
    _errorMessage = '';
    _currentQuizIndex = 0;
    _isPracticeCompleted = false;
    currentTouchedCount = 0;
    materials = [];
    _quizzes.clear();
  }

  /// 初始化练习数据（根据 instanceId 加载）
  Future<void> initialize(
    UserPracticeModel practiceData,
    UserWeeklyPlanModel weeklyPlan,
    String topic,
    String culture,
  ) async {
    _resetPracticeState();
    _practiceData = practiceData;
    retryFunc = null;
    try {
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      _isLoading = true;
      notifyListeners();
      List<QuizesModle> quizesData = await DataService().fetchQuizesByIds(
        practiceData.quizes,
      );
      // 提取练习的材料在loading显示
      materials = quizesData
          .where(
            (q) =>
                (q.materialType == MaterialContentType.character ||
                q.materialType == MaterialContentType.word ||
                q.materialType == MaterialContentType.sentence),
          )
          .map((q) => q.material!)
          .toList();
      notifyListeners();

      final isExist = quizesData.fold(true, (a, b) => a && b.question != null);
      if (!isExist) {
        quizesData = await DataService().generateQuizesContent(
          practiceData.quizes,
        );
      }
      await DataService().addActivityToQuizesModel(quizesData);
      _quizzes = QuizBase.getQuizInstanceByType(quizesData);
      retryFunc = null;
    } catch (e) {
      _errorMessage = e.toString();
      retryLabel = 'Retry';
      retryFunc = () => initialize(practiceData, weeklyPlan, topic, culture);
      if (kDebugMode) debugPrint('练习初始化失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 进入下一个 Quiz
  void nextQuiz() {
    if (currentQuiz.state == QuizState.pass) {
      //做对前进一题
      if (_currentQuizIndex < totalQuizzes - 1) {
        _currentQuizIndex++;
      } else {
        //最后一题正确，结束练习
        _isPracticeCompleted = true;
        notifyListeners();
        return;
      }
    } else {
      //做错：错题移至队尾
      final failQuiz = currentQuiz;
      failQuiz.isRenewal = true;
      quizzes.removeAt(_currentQuizIndex);
      quizzes.add(failQuiz);
    }
    // 下一题
    currentTouchedCount++;
    notifyListeners();
  }

  /// 提交练习数据
  Future<void> submitPracticeResult() async {
    isSaving = true;
    retryLabel = '';
    _errorMessage = '';
    retryFunc = null;
    try {
      loadingMessage = 'Saving Practice...';
      notifyListeners();
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      await DataService().saveResultScores(_quizzes, _practiceData!);
      final exp = quizzes.fold<double>(0, (sum, a) {
        return sum +
            a.result.score * a.model.activity!.timeCost!.toDouble() * 0.1;
      });

      loadingMessage = 'Saving EXP...';
      notifyListeners();
      final totalExp = await DataService().saveExp(
        exp,
        userId: user.id,
        title: 'practice:${_practiceData!.id}',
      );
      ProfileProvider().profile!.exp = totalExp.toInt();
      await PlanProvider().updateProgress();
      await ProfileProvider().updateMaterials();
    } catch (e) {
      retryLabel = 'Retry';
      _errorMessage = e.toString();
      retryFunc = submitPracticeResult;
      if (kDebugMode) debugPrint('提交练习数据-失败: $e');
    } finally {
      isSaving = false;
      notifyListeners();
      // 更新用户档案数据
    }
  }
}
