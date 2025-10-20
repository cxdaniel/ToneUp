// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_ability_histry_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserAbilityHistryModel _$UserAbilityHistryModelFromJson(
  Map<String, dynamic> json,
) => UserAbilityHistryModel(
  id: (json['id'] as num).toInt(),
  userId: json['user_id'] as String,
  indicatorId: (json['indicator_id'] as num).toInt(),
  score: (json['score'] as num).toDouble(),
  createdAt: DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$UserAbilityHistryModelToJson(
  UserAbilityHistryModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'indicator_id': instance.indicatorId,
  'score': instance.score,
  'created_at': instance.createdAt.toIso8601String(),
};
