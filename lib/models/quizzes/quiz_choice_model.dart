import 'package:json_annotation/json_annotation.dart';
import 'package:toneup_app/models/quizzes/quiz_material_model.dart';
import 'package:toneup_app/models/quizzes/quiz_options_model.dart';

part 'quiz_choice_model.g.dart';

@JsonSerializable()
class QuizChoiceModel {
  @JsonKey(name: "act_id")
  final int actId;
  final String explain;
  final String question;
  // @JsonKey(name: "quiz_type")
  // final QuizType quizType;
  final QuizMaterialModel material;
  final List<QuizOptionsModel> options;

  // 构造函数：全部必填（示例中无 null）
  QuizChoiceModel({
    required this.actId,
    required this.explain,
    required this.question,
    // required this.quizType,
    required this.material,
    required this.options,
  });

  factory QuizChoiceModel.fromJson(Map<String, dynamic> json) =>
      _$QuizChoiceModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuizChoiceModelToJson(this);
}
