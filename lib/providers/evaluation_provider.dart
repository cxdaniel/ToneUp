import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/quizzes/quiz_base.dart';
import 'package:toneup_app/services/data_service.dart';

class EvaluationProvider extends ChangeNotifier {
  List<QuizBase> _quizzes = []; // 所有 Quiz 列表
  int _currentQuizIndex = 0; // 当前 Quiz 索引
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPracticeCompleted = false; // 练习是否完成
  // Getters
  List<QuizBase> get quizzes => _quizzes;
  int get currentQuizIndex => _currentQuizIndex;
  int get totalQuizzes => _quizzes.length;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
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

      _isLoading = true;
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
      _errorMessage = e.toString();
      retryLabel = 'Retry';
      retryFunc = () => initialize(level);
      if (kDebugMode) debugPrint('测评初始化失败: $e');
    } finally {
      _isLoading = false;
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
    // } else {
    //   //做错：错题移至队尾
    //   final failQuiz = currentQuiz;
    //   failQuiz.isRenewal = true;
    //   quizzes.removeAt(_currentQuizIndex);
    //   quizzes.add(failQuiz);
    // }
    // 下一题
    currentTouchedCount++;
    notifyListeners();
  }
}
