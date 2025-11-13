// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_practice_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserPracticeModel _$UserPracticeModelFromJson(Map<String, dynamic> json) =>
    UserPracticeModel(
      id: (json['id'] as num).toInt(),
      status: (json['status'] as num).toInt(),
      quizes: (json['quizes'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      score: (json['score'] as num).toDouble(),
      count: (json['count'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updateAt: json['update_at'] == null
          ? null
          : DateTime.parse(json['update_at'] as String),
    );

Map<String, dynamic> _$UserPracticeModelToJson(UserPracticeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'quizes': instance.quizes,
      'status': instance.status,
      'score': instance.score,
      'count': instance.count,
      'created_at': instance.createdAt.toIso8601String(),
      'update_at': instance.updateAt?.toIso8601String(),
    };
