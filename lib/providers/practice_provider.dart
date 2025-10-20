import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/quizzes/quiz_model.dart';
import 'package:toneup_app/models/quizzes/quiz_choice_model.dart';
import 'package:toneup_app/models/user_activity_instances_model.dart';
import 'package:toneup_app/models/user_practice_model.dart';
import 'package:toneup_app/models/user_weekly_plan_model.dart';
import '../services/user_activity_service.dart';

class PracticeProvider extends ChangeNotifier {
  final UserActivityService _service = UserActivityService();
  List<QuizBase> _quizzes = []; // 所有 Quiz 列表
  int _currentQuizIndex = 0; // 当前 Quiz 索引
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPracticeCompleted = false; // 练习是否完成
  UserPracticeModel? _practiceData;
  // final List<QuizResultModel> _result = [];
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
  Function? retryFunc;
  String? retryLabel;

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

  /// 初始化练习数据（根据 instanceId 加载）
  Future<void> initialize(
    UserPracticeModel data,
    UserWeeklyPlanModel plan,
    String topic,
    String culture,
  ) async {
    _practiceData = data;
    retryFunc = null;
    try {
      final User? user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("用户未登录");

      _isLoading = true;
      _errorMessage = null;
      _currentQuizIndex = 0;
      _isPracticeCompleted = false;
      notifyListeners();

      final ins = await _service.getPracticeData(
        data.instances,
        topic,
        culture,
      );
      _quizzes = _extractQuizzesFromInstances(ins);
      retryFunc = null;
    } catch (e) {
      _errorMessage = e.toString();
      retryLabel = 'Retry';
      retryFunc = () => initialize(data, plan, topic, culture);
      if (kDebugMode) debugPrint('练习初始化失败: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 从 UserActivityInstanceModel 中提取 Quiz
  List<QuizBase> _extractQuizzesFromInstances(
    List<UserActivityInstanceModel> instances,
  ) {
    final List<QuizBase> quizList = [];
    for (var instance in instances) {
      switch (instance.activity!.quizType) {
        case QuizType.choice:
          final quizdata = QuizChoiceModel.fromJson(instance.quiz!);
          final correctOption = quizdata.options.firstWhere(
            (o) => o.isCorrect == true,
            orElse: () => quizdata.options.first,
          );
          quizList.add(
            QuizChoice(
              insid: instance.id,
              actInstance: instance,
              question: quizdata.question,
              options: quizdata.options,
              correctAnswer: correctOption,
              material: quizdata.material,
              explain: quizdata.explain,
            ),
          );
          break;
        default:
          quizList.add(
            QuizDefault(
              insid: instance.id,
              actInstance: instance,
              question: instance.quiz!['question'],
              correctAnswer: null,
            ),
          );
      }
    }
    return quizList;
  }

  /// 标记实例为已完成
  void markQuizResult(QuizBase quiz) {
    quiz.calculateScore();
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
    await _service.saveResultScores(_quizzes, _practiceData!);
    notifyListeners();
  }
}
