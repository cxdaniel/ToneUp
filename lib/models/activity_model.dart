import 'package:json_annotation/json_annotation.dart';
import 'package:toneup_app/models/enumerated_types.dart';

part 'activity_model.g.dart';

@JsonSerializable()
class ActivityModel {
  final int id;
  @JsonKey(name: "activity_title")
  final String activityTitle; // 题目类别
  @JsonKey(name: "quiz_template")
  final QuizTemplate quizTemplate; // 练习模板
  @JsonKey(name: "quiz_type")
  final QuizType quizType; // 题型
  @JsonKey(name: "material_type")
  final List<MaterialType> materialType; // 素材类型数组
  @JsonKey(name: "time_cost")
  final int? timeCost; // 耗时（默认30）
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @JsonKey(name: "indicator_cats")
  final List<IndicatorCategory> indicatorCats; // 指标类别数组

  ActivityModel({
    required this.id,
    required this.quizTemplate,
    required this.activityTitle,
    required this.quizType,
    required this.materialType,
    this.timeCost,
    required this.createdAt,
    required this.indicatorCats,
  });

  // 序列化方法
  factory ActivityModel.fromJson(Map<String, dynamic> json) =>
      _$ActivityModelFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityModelToJson(this);
}
