import 'package:json_annotation/json_annotation.dart';
import 'package:toneup_app/models/quizzes/quiz_material_model.dart';
import 'package:toneup_app/models/quizzes/quiz_options_model.dart';

part 'quiz_choice_model_mo.g.dart';

@JsonSerializable()
class QuizChoiceModelMO {
  // @JsonKey(name: "act_id")
  // final int actId;
  final String explain;
  final String question;
  final QuizMaterialModel material;
  final List<QuizOptionsModel> options;

  // 构造函数
  QuizChoiceModelMO({
    // required this.actId,
    required this.explain,
    required this.question,
    // required this.quizType,
    required this.material,
    required this.options,
  });

  factory QuizChoiceModelMO.fromJson(Map<String, dynamic> json) =>
      _$QuizChoiceModelMOFromJson(json);

  Map<String, dynamic> toJson() => _$QuizChoiceModelMOToJson(this);
}
