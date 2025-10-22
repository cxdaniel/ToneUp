import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class ProfileModel {
  final String id;
  String? nickname;
  @JsonKey(name: 'plan_duration_minutes')
  int? planDurationMinutes;
  int? exp;
  @JsonKey(name: "streak_days")
  int? streakDays;
  int? level;
  int? plans;
  int? practices;
  int? characters;
  int? words;
  int? sentences;
  int? grammars;
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @JsonKey(name: "updated_at")
  DateTime? updatedAt;

  ProfileModel({
    required this.id,
    required this.createdAt,
    this.nickname,
    this.planDurationMinutes,
    this.exp,
    this.streakDays,
    this.level,
    this.plans,
    this.practices,
    this.characters,
    this.words,
    this.sentences,
    this.grammars,
    this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);
}
