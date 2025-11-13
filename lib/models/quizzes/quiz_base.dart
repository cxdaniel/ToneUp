import 'dart:math';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/quizzes/quiz_options_model.dart';
import 'package:toneup_app/models/quizzes/quiz_result_model.dart';
import 'package:toneup_app/models/quizzes/quizes_modle.dart';

enum QuizState { initial, intouch, touched, fail, pass }

/// Quiz 基类：定义通用属性与方法
abstract class QuizBase {
  final QuizesModle model;
  dynamic correctAnswer;
  QuizResultModel result;
  QuizState state = QuizState.initial;
  int maxRetryTime = 1; // 可重试次数，默认2次, 0为不可重试
  int retryCount = 0; // 已重试次数
  bool isRenewal = false;

  QuizBase({
    required this.model,
    this.correctAnswer = '',
    this.maxRetryTime = 2,
  }) : result = QuizResultModel(
         score: 0,
         category: model.materialType,
         item: model.material,
       );

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

  /// 以数据类别获取Quiz实例:
  /// 按[quizes]数据中的[activity.quizType]获取对应的[QuizBase]实例
  static List<QuizBase> getQuizInstanceByType(
    List<QuizesModle> quizes, {
    maxRetryTime,
  }) {
    final List<QuizBase> quizList = [];
    for (var quiz in quizes) {
      switch (quiz.activity!.quizType) {
        case QuizType.choice:
          quizList.add(QuizChoice(model: quiz));
          break;
        default:
          quizList.add(QuizDefault(model: quiz));
      }
    }
    return quizList;
  }
}

///通用题型
class QuizDefault extends QuizBase {
  QuizDefault({required super.model});
  @override
  void updateStatus(dynamic userAnswer) {}
}

/// 选择题
class QuizChoice extends QuizBase {
  final List<QuizOptionsModel> options;
  final String material;
  QuizChoice({required super.model, super.maxRetryTime = 1})
    : options = (model.options as List)
          .map((o) => QuizOptionsModel.fromJson(o))
          .toList(),
      material = model.stem as String {
    super.correctAnswer = options.firstWhere(
      (o) => o.isCorrect == true,
      orElse: () => options.first,
    );
  }

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
