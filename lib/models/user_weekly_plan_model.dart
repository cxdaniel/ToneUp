import 'package:json_annotation/json_annotation.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/user_practice_model.dart';
import 'material_snapshot/material_snapshot_model.dart';

// 这行是自动生成的代码文件（运行 build_runner 后会出现），必须加
part 'user_weekly_plan_model.g.dart';

// 模型类（与表 user_weekly_plans 对应）
@JsonSerializable() // 标记此类需要自动生成序列化代码
class UserWeeklyPlanModel {
  final int id;
  @JsonKey(name: "user_id")
  final String userId;
  @JsonKey(name: "start_date")
  final DateTime startDate;
  @JsonKey(name: "end_date")
  final DateTime endDate;
  @JsonKey(name: "target_indicators")
  final List<int> targetIndicators;
  @JsonKey(name: "progress")
  final double? progress;
  @JsonKey(name: "status")
  PlanStatus status;
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @JsonKey(name: "material_snapshot")
  final MaterialSnapshotModel materialSnapshot;
  @JsonKey(name: "target_material")
  final int targetMaterial;
  @JsonKey(name: "topic_title")
  final String? topicTitle;
  @JsonKey(name: "level")
  final int level;
  final List<int> practices;
  List<UserPracticeModel>? practiceData;
  // @JsonKey(name: "target_activities")
  // final List<List<int>>? targetActivities;

  // 构造函数（必填，且参数名要和字段名一致）
  UserWeeklyPlanModel({
    required this.id,
    required this.userId,
    required this.startDate, // 表中 not null，模型用 required 强制非空
    required this.endDate,
    required this.targetIndicators,
    this.progress = 0.0, // 表中默认 0，模型给默认值
    this.status = PlanStatus.active, // 表中默认 'active'，模型给默认值
    required this.createdAt,
    required this.materialSnapshot,
    required this.targetMaterial,
    this.topicTitle,
    required this.level,
    required this.practices,
    this.practiceData,
  });

  // 1. 从 JSON 转模型（反序列化）：自动生成的方法
  factory UserWeeklyPlanModel.fromJson(Map<String, dynamic> json) =>
      _$UserWeeklyPlanModelFromJson(json);

  // 2. 从模型转 JSON（序列化）：自动生成的方法
  Map<String, dynamic> toJson() => _$UserWeeklyPlanModelToJson(this);
}
