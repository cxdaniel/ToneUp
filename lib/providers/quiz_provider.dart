import 'package:flutter/foundation.dart';
import 'package:toneup_app/models/quizzes/quiz_base.dart';

class QuizProvider with ChangeNotifier {
  late QuizBase _quiz;
  dynamic _answer;
  String _feedback = '';

  // Getters
  QuizBase get quiz => _quiz;
  dynamic get answer => _answer;
  QuizState get state => _quiz.state;
  String get feedbackMessage => _feedback;

  /// 初始化题目
  void initQuiz(QuizBase quiz) {
    _quiz = quiz;
    _answer = null;
    _quiz.retryCount = 0;
    _quiz.updateStatus(null);
    _quiz.state = QuizState.initial; // 先进入出题状态
    _feedback = '';
    // 1秒后切换到交互状态（模拟出题动画）
    Future.delayed(const Duration(microseconds: 300), () {
      _quiz.state = QuizState.intouch;
      notifyListeners();
    });
  }

  /// 更新用户答案
  void updateAnswer(dynamic answer) {
    _answer = answer;
    _quiz.state = QuizState.touched;
    _quiz.updateStatus(_answer);
    notifyListeners();
  }

  /// 提交答案
  void submitAnswer() {
    if (_quiz.state != QuizState.touched) return;
    final isCorrect = _quiz.validateAnswer(_answer);
    _quiz.state = isCorrect ? QuizState.pass : QuizState.fail;
    _feedback = _quiz.model.explain!;
    // _feedback = isCorrect ? 'Well done!' : '${_quiz.explain}';
    _quiz.updateStatus(_answer);
    notifyListeners();
  }

  /// 重试当前题（状态重置）
  void retry() {
    _answer = null;
    _quiz.state = QuizState.intouch;
    _feedback = '';
    _quiz.retryCount++;
    _quiz.updateStatus(_answer);
    notifyListeners();
  }
}
