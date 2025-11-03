import 'package:json_annotation/json_annotation.dart';
import 'package:toneup_app/models/activity_model.dart';
import 'package:toneup_app/models/indicators_model.dart';

part 'evaluation_model.g.dart';

@JsonSerializable()
class EvaluationModel {
  final int id;
  @JsonKey(name: "activity_id")
  final int activityId; // 关联 activities 表的 id
  @JsonKey(name: "indicator_id")
  final int indicatorId; // 关联 indicator 表的 id
  final int level;
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @JsonKey(name: "quiz")
  final Map<String, dynamic> quiz; // 题目内容（jsonb 类型）

  /// 关联属性
  ActivityModel? activity;
  IndicatorsModel? indicator;

  EvaluationModel({
    required this.id,
    required this.activityId,
    required this.indicatorId,
    required this.createdAt,
    required this.level,
    required this.quiz,
    this.activity,
    this.indicator,
  });

  // 序列化方法（需运行 build_runner 生成）
  factory EvaluationModel.fromJson(Map<String, dynamic> json) =>
      _$EvaluationModelFromJson(json);

  Map<String, dynamic> toJson() => _$EvaluationModelToJson(this);
}
