import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/quizzes/quiz_model.dart';
import 'package:toneup_app/models/quizzes/quiz_choice_model_mo.dart';
import 'package:toneup_app/models/quizzes/quiz_result_model.dart';
import 'package:toneup_app/models/user_activity_instances/act_ins_material_model.dart';
import 'package:toneup_app/models/user_activity_instances_model.dart';
import 'package:toneup_app/models/user_practice_model.dart';
import 'package:toneup_app/models/user_weekly_plan_model.dart';
import 'package:toneup_app/providers/plan_provider.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/services/data_service.dart';

class PracticeProvider extends ChangeNotifier {
  List<QuizBase> _quizzes = []; // 所有 Quiz 列表
  int _currentQuizIndex = 0; // 当前 Quiz 索引
  bool _isLoading = false;
  String? _errorMessage;
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
  List<ActInsMaterialModel> materials = [];

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
    _errorMessage = null;
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

      List<UserActivityInstanceModel> instances = await DataService()
          .getPracticeInstances(practiceData.instances);

      // 提取练习的材料在loading显示
      final actMaterials = instances.map((ins) => ins.materials).toList();
      materials.addAll(
        Set<ActInsMaterialModel>.from(
          actMaterials.where(
            (m) =>
                (m.type == MaterialContentType.character ||
                m.type == MaterialContentType.word ||
                m.type == MaterialContentType.sentence),
          ),
        ),
      );
      notifyListeners();

      final quizexist = instances.fold(true, (a, b) => a && b.quiz != null);
      if (!quizexist) {
        instances = await DataService().generatePracticeQuiz(
          practiceData.instances,
          topic,
          culture,
        );
      }
      final insWithAct = await DataService().addActivityToInstances(instances);
      _quizzes = _extractQuizzesbyType(insWithAct);
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

  /// 从 按类别提取 Quiz
  List<QuizBase> _extractQuizzesbyType(
    List<UserActivityInstanceModel> instances,
  ) {
    final List<QuizBase> quizList = [];
    for (var instance in instances) {
      switch (instance.activity!.quizType) {
        case QuizType.choice:
          final quizdata = QuizChoiceModelMO.fromJson(instance.quiz!);
          final correctOption = quizdata.options.firstWhere(
            (o) => o.isCorrect == true,
            orElse: () => quizdata.options.first,
          );
          quizList.add(
            QuizChoice(
                id: instance.id,
                indicatorId: instance.indicatorId,
                activity: instance.activity!,
                question: quizdata.question,
                options: quizdata.options,
                correctAnswer: correctOption,
                material: quizdata.material,
                explain: quizdata.explain,
              )
              ..result = QuizResultModel(
                score: 0,
                category: instance.materials.type,
                item: instance.materials.content,
              ),
          );
          break;
        default:
          quizList.add(
            QuizDefault(
                id: instance.id,
                indicatorId: instance.indicatorId,
                activity: instance.activity!,
                question: instance.quiz!['question'],
                correctAnswer: null,
              )
              ..result = QuizResultModel(
                score: 0,
                category: instance.materials.type,
                item: instance.materials.content,
              ),
          );
      }
    }
    return quizList;
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
    await DataService().saveResultScores(_quizzes, _practiceData!);
    notifyListeners();
    // 更新用户档案数据
    PlanProvider().updateProgress();
    ProfileProvider().updateMaterials();
  }
}
