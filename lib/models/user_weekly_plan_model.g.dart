// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_weekly_plan_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserWeeklyPlanModel _$UserWeeklyPlanModelFromJson(Map<String, dynamic> json) =>
    UserWeeklyPlanModel(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      targetIndicators: (json['target_indicators'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      targetActivities: (json['target_activities'] as List<dynamic>?)
          ?.map(
            (e) => (e as List<dynamic>).map((e) => (e as num).toInt()).toList(),
          )
          .toList(),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status:
          $enumDecodeNullable(_$PlanStatusEnumMap, json['status']) ??
          PlanStatus.active,
      createdAt: DateTime.parse(json['created_at'] as String),
      materialSnapshot: MaterialSnapshotModel.fromJson(
        json['material_snapshot'] as Map<String, dynamic>,
      ),
      targetMaterial: (json['target_material'] as num).toInt(),
      topicTitle: json['topic_title'] as String?,
      level: (json['level'] as num).toInt(),
      practices: (json['practices'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      practiceData: (json['practiceData'] as List<dynamic>?)
          ?.map((e) => UserPracticeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserWeeklyPlanModelToJson(
  UserWeeklyPlanModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'start_date': instance.startDate.toIso8601String(),
  'end_date': instance.endDate.toIso8601String(),
  'target_indicators': instance.targetIndicators,
  'target_activities': instance.targetActivities,
  'progress': instance.progress,
  'status': _$PlanStatusEnumMap[instance.status]!,
  'created_at': instance.createdAt.toIso8601String(),
  'material_snapshot': instance.materialSnapshot,
  'target_material': instance.targetMaterial,
  'topic_title': instance.topicTitle,
  'level': instance.level,
  'practices': instance.practices,
  'practiceData': instance.practiceData,
};

const _$PlanStatusEnumMap = {
  PlanStatus.active: 'active',
  PlanStatus.pending: 'pending',
  PlanStatus.done: 'done',
  PlanStatus.reactive: 'reactive',
};
