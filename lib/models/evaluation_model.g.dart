// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'evaluation_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EvaluationModel _$EvaluationModelFromJson(Map<String, dynamic> json) =>
    EvaluationModel(
      id: (json['id'] as num).toInt(),
      activityId: (json['activity_id'] as num).toInt(),
      indicatorId: (json['indicator_id'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      level: (json['level'] as num).toInt(),
      quiz: json['quiz'] as Map<String, dynamic>,
      activity: json['activity'] == null
          ? null
          : ActivityModel.fromJson(json['activity'] as Map<String, dynamic>),
      indicator: json['indicator'] == null
          ? null
          : IndicatorsModel.fromJson(json['indicator'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$EvaluationModelToJson(EvaluationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'activity_id': instance.activityId,
      'indicator_id': instance.indicatorId,
      'level': instance.level,
      'created_at': instance.createdAt.toIso8601String(),
      'quiz': instance.quiz,
      'activity': instance.activity,
      'indicator': instance.indicator,
    };
