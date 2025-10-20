import 'package:json_annotation/json_annotation.dart';
import 'package:toneup_app/models/activity_model.dart';
import 'package:toneup_app/models/user_activity_instances/act_ins_material_model.dart';
part 'user_activity_instances_model.g.dart';

@JsonSerializable()
class UserActivityInstanceModel {
  final int id;
  @JsonKey(name: "activity_id")
  final int activityId; // 关联 activities 表的 id
  @JsonKey(name: "indicator_id")
  final int indicatorId; // 可为空
  @JsonKey(name: "materials")
  final ActInsMaterialModel materials; // jsonb 类型'
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @JsonKey(name: "quiz")
  final Map<String, dynamic>? quiz; // 题目内容（jsonb 类型）
  @JsonKey(name: "material_id")
  final int? materialId;

  /// 关联属性
  ActivityModel? activity;

  /// provider需求
  bool? isCompleted;

  UserActivityInstanceModel({
    required this.id,
    required this.activityId,
    required this.indicatorId,
    required this.materials,
    required this.createdAt,
    this.quiz,
    this.materialId,
    this.activity,
    this.isCompleted = false,
  });

  // 序列化方法（需运行 build_runner 生成）
  factory UserActivityInstanceModel.fromJson(Map<String, dynamic> json) =>
      _$UserActivityInstanceModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserActivityInstanceModelToJson(this);
}
