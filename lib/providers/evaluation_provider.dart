import 'package:flutter/foundation.dart';
import 'package:jieba_flutter/conversion/common_conversion_definition.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/evaluation_model.dart';
import 'package:toneup_app/models/quizzes/quiz_choice_model.dart';
import 'package:toneup_app/models/quizzes/quiz_model.dart';
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
  Map<QuizBase, EvaluationModel> evaluationQuizMap = {};
  double get score {
    final totalScore = quizzes.fold<double>(
      0,
      (sum, quiz) =>
          sum +
          quiz.result.score * evaluationQuizMap.get(quiz)!.indicator!.weight,
    );
    final totalWeight = quizzes.fold<double>(
      0,
      (sum, quiz) => sum + evaluationQuizMap.get(quiz)!.indicator!.weight,
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

      final evaluations = await DataService().fetchEvaluations(level);
      final withActivity = await DataService().addActivityToEvaluation(
        evaluations,
      );
      final withIndicator = await DataService().addIndicatorToEvaluation(
        withActivity,
      );
      _quizzes = _extractQuizzesbyType(withIndicator);
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

  /// 从 按类别提取Quiz
  List<QuizBase> _extractQuizzesbyType(List<EvaluationModel> evaluations) {
    final List<QuizBase> quizList = [];
    for (var evl in evaluations) {
      QuizBase quiz;
      switch (evl.activity!.quizType) {
        case QuizType.choice:
          final quizdata = QuizChoiceModel.fromJson(evl.quiz);
          final correctOption = quizdata.options.firstWhere(
            (o) => o.isCorrect == true,
            orElse: () => quizdata.options.first,
          );
          quiz = QuizChoice(
            id: evl.id,
            activity: evl.activity!,
            indicatorId: evl.indicatorId,
            question: quizdata.question,
            options: quizdata.options,
            correctAnswer: correctOption,
            material: quizdata.material,
            explain: quizdata.explain,
            maxRetryTime: 0,
          );
          break;
        default:
          quiz = QuizDefault(
            id: evl.id,
            activity: evl.activity!,
            indicatorId: evl.indicatorId,
            question: evl.quiz['question'],
            correctAnswer: null,
            maxRetryTime: 0,
          );
      }
      evaluationQuizMap.put(quiz, evl);
      quizList.add(quiz);
    }
    return quizList;
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
