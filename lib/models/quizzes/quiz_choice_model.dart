import 'package:json_annotation/json_annotation.dart';
import 'package:toneup_app/models/quizzes/quiz_options_model.dart';

part 'quiz_choice_model.g.dart';

@JsonSerializable()
class QuizChoiceModel {
  final String question;
  final String material;
  final List<QuizOptionsModel> options;
  final String explain;

  // 构造函数
  QuizChoiceModel({
    required this.material,
    required this.question,
    required this.options,
    required this.explain,
  });

  factory QuizChoiceModel.fromJson(Map<String, dynamic> json) =>
      _$QuizChoiceModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuizChoiceModelToJson(this);
}
