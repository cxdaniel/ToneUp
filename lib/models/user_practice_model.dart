import 'package:json_annotation/json_annotation.dart';

part 'user_practice_model.g.dart';

// 模型类（与表 user_weekly_plans 对应）
@JsonSerializable()
// 标记此类需要自动生成序列化代码
class UserPracticeModel {
  final int id;
  final List<int> instances;
  double score;
  int count;

  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @JsonKey(name: "update_at")
  final DateTime? updateAt;

  UserPracticeModel({
    required this.id,
    required this.instances,
    required this.score,
    required this.count,
    required this.createdAt,
    this.updateAt,
  });

  factory UserPracticeModel.fromJson(Map<String, dynamic> json) =>
      _$UserPracticeModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserPracticeModelToJson(this);
}
