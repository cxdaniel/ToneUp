import 'dart:math';
import 'package:toneup_app/models/activity_model.dart';
import 'package:toneup_app/models/quizzes/quiz_options_model.dart';
import 'package:toneup_app/models/quizzes/quiz_result_model.dart';

enum QuizState { initial, intouch, touched, fail, pass }

/// Quiz 基类：定义通用属性与方法
abstract class QuizBase {
  final int id;
  final ActivityModel activity;
  final int indicatorId;
  final String question;
  final dynamic correctAnswer; // 正确答案
  late final String? explain;
  QuizResultModel result;
  QuizState state = QuizState.initial;
  int maxRetryTime; // 可重试次数，默认2次, 0为不可重试
  int retryCount = 0; // 已重试次数
  bool isRenewal = false;

  QuizBase({
    required this.id,
    required this.activity,
    required this.indicatorId,
    required this.question,
    required this.correctAnswer,
    this.explain,
    this.maxRetryTime = 2,
  }) : result = QuizResultModel(score: 0);

  void updateStatus(dynamic userAnswer);
  bool validateAnswer(dynamic userAnswer) {
    return (userAnswer == correctAnswer);
  }

  void calculateScore() {
    if (state != QuizState.pass) return;
    // 方法1：基于最大重试次数计算剩余比例，重试越少分越高
    final remainingRetries = max(maxRetryTime - retryCount, 0);
    double score = (remainingRetries + 1) / (maxRetryTime + 1);
    // 方法2：指数衰减，重试次数越多扣分越快，趋近于0但不为0
    // double score = 1.0 / (1 + pow(retryCount, 1.5));
    result.score = isRenewal ? 0 : score;
  }
}

///通用题型
class QuizDefault extends QuizBase {
  QuizDefault({
    required super.id,
    required super.indicatorId,
    required super.activity,
    required super.question,
    required super.correctAnswer,
    super.maxRetryTime = 1,
  });
  @override
  void updateStatus(dynamic userAnswer) {}
}

/// 选择题
class QuizChoice<T> extends QuizBase {
  final List<QuizOptionsModel> options;
  final T material;
  QuizChoice({
    required super.id,
    required super.indicatorId,
    required super.activity,
    required super.question,
    required this.options,
    required this.material,
    required QuizOptionsModel super.correctAnswer,
    super.explain,
    super.maxRetryTime = 1,
  });

  @override
  void updateStatus(dynamic userAnswer) {
    for (var opt in options) {
      opt.state = OptionStatus.normal;
    }
    if (userAnswer == null) {
      return;
    }

    final answer = userAnswer as QuizOptionsModel;
    if (state == QuizState.touched) {
      answer.state = OptionStatus.select;
    } else if (state == QuizState.pass) {
      answer.state = OptionStatus.pass;
    } else if (state == QuizState.fail) {
      answer.state = OptionStatus.fail;
    }
  }
}
