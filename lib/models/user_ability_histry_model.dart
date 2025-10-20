import 'package:json_annotation/json_annotation.dart';

part 'user_ability_histry_model.g.dart';

@JsonSerializable()
class UserAbilityHistryModel {
  final int id;
  @JsonKey(name: "user_id")
  final String userId;
  @JsonKey(name: "indicator_id")
  final int indicatorId;
  final double score;
  @JsonKey(name: "created_at")
  final DateTime createdAt;

  UserAbilityHistryModel({
    required this.id,
    required this.userId,
    required this.indicatorId,
    required this.score,
    required this.createdAt,
  });

  // 序列化方法
  factory UserAbilityHistryModel.fromJson(Map<String, dynamic> json) =>
      _$UserAbilityHistryModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserAbilityHistryModelToJson(this);
}
