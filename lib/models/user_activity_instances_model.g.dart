// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_activity_instances_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserActivityInstanceModel _$UserActivityInstanceModelFromJson(
  Map<String, dynamic> json,
) => UserActivityInstanceModel(
  id: (json['id'] as num).toInt(),
  activityId: (json['activity_id'] as num).toInt(),
  indicatorId: (json['indicator_id'] as num).toInt(),
  materials: ActInsMaterialModel.fromJson(
    json['materials'] as Map<String, dynamic>,
  ),
  createdAt: DateTime.parse(json['created_at'] as String),
  quiz: json['quiz'] as Map<String, dynamic>?,
  activity: json['activity'] == null
      ? null
      : ActivityModel.fromJson(json['activity'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserActivityInstanceModelToJson(
  UserActivityInstanceModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'activity_id': instance.activityId,
  'indicator_id': instance.indicatorId,
  'materials': instance.materials,
  'created_at': instance.createdAt.toIso8601String(),
  'quiz': instance.quiz,
  'activity': instance.activity,
};
