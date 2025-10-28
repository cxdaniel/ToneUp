// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_score_records_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserScoreRecordsModel _$UserScoreRecordsModelFromJson(
  Map<String, dynamic> json,
) => UserScoreRecordsModel(
  category: $enumDecode(_$MaterialContentTypeEnumMap, json['category']),
  item: json['item'] as String,
  id: (json['id'] as num?)?.toInt(),
  userId: json['user_id'] as String?,
  score: (json['score'] as num?)?.toDouble(),
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$UserScoreRecordsModelToJson(
  UserScoreRecordsModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'score': instance.score,
  'created_at': instance.createdAt?.toIso8601String(),
  'item': instance.item,
  'category': _$MaterialContentTypeEnumMap[instance.category]!,
};

const _$MaterialContentTypeEnumMap = {
  MaterialContentType.character: 'character',
  MaterialContentType.word: 'word',
  MaterialContentType.sentence: 'sentence',
  MaterialContentType.dialog: 'dialog',
  MaterialContentType.paragraph: 'paragraph',
  MaterialContentType.syllable: 'syllable',
  MaterialContentType.grammar: 'grammar',
};
