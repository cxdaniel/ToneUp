// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) => ProfileModel(
  id: json['id'] as String,
  nickname: json['nickname'] as String?,
  planDurationMinutes: (json['plan_duration_minutes'] as num?)?.toInt(),
  exp: (json['exp'] as num?)?.toInt(),
  streakDays: (json['streak_days'] as num?)?.toInt(),
  level: (json['level'] as num?)?.toInt(),
  plans: (json['plans'] as num?)?.toInt(),
  practices: (json['practices'] as num?)?.toInt(),
  characters: (json['characters'] as num?)?.toInt(),
  words: (json['words'] as num?)?.toInt(),
  sentences: (json['sentences'] as num?)?.toInt(),
  grammars: (json['grammars'] as num?)?.toInt(),
  purpose: $enumDecodeNullable(_$PurposeTypeEnumMap, json['purpose']),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  avatar: json['avatar'] as String?,
  nativeLanguage: json['native_language'] as String? ?? 'en',
);

Map<String, dynamic> _$ProfileModelToJson(ProfileModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nickname': instance.nickname,
      'plan_duration_minutes': instance.planDurationMinutes,
      'exp': instance.exp,
      'streak_days': instance.streakDays,
      'level': instance.level,
      'plans': instance.plans,
      'practices': instance.practices,
      'characters': instance.characters,
      'words': instance.words,
      'sentences': instance.sentences,
      'grammars': instance.grammars,
      'purpose': _$PurposeTypeEnumMap[instance.purpose],
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
      'avatar': instance.avatar,
      'native_language': instance.nativeLanguage,
    };

const _$PurposeTypeEnumMap = {
  PurposeType.interest: 'interest',
  PurposeType.work: 'work',
  PurposeType.travel: 'travel',
  PurposeType.exam: 'exam',
  PurposeType.life: 'life',
};
