import 'package:json_annotation/json_annotation.dart';
import 'package:toneup_app/models/enumerated_types.dart';
part 'user_score_records_model.g.dart';

@JsonSerializable()
class UserScoreRecordsModel {
  int? id;
  @JsonKey(name: 'user_id')
  final String? userId;
  final double? score;
  @JsonKey(name: "created_at")
  final DateTime? createdAt;
  final String item;
  final MaterialType category;

  UserScoreRecordsModel({
    required this.category,
    required this.item,
    this.id,
    this.userId,
    this.score,
    this.createdAt,
  });

  factory UserScoreRecordsModel.fromJson(Map<String, dynamic> json) =>
      _$UserScoreRecordsModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserScoreRecordsModelToJson(this);
}
