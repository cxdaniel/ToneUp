// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_vocabulary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserVocabularyModel _$UserVocabularyModelFromJson(Map<String, dynamic> json) =>
    UserVocabularyModel(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] as String,
      word: json['word'] as String,
      pinyin: json['pinyin'] as String?,
      definition: json['definition'] as String?,
      exampleSentence: json['example_sentence'] as String?,
      exampleTranslation: json['example_translation'] as String?,
      sourceType: json['source_type'] as String,
      sourceMediaId: (json['source_media_id'] as num?)?.toInt(),
      sourcePracticeId: (json['source_practice_id'] as num?)?.toInt(),
      sourceContext: json['source_context'] as String?,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      lastReviewedAt: json['last_reviewed_at'] == null
          ? null
          : DateTime.parse(json['last_reviewed_at'] as String),
      nextReviewAt: json['next_review_at'] == null
          ? null
          : DateTime.parse(json['next_review_at'] as String),
      masteryLevel: (json['mastery_level'] as num?)?.toInt() ?? 0,
      isStarred: json['is_starred'] as bool? ?? false,
      notes: json['notes'] as String?,
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserVocabularyModelToJson(
  UserVocabularyModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'word': instance.word,
  'pinyin': instance.pinyin,
  'definition': instance.definition,
  'example_sentence': instance.exampleSentence,
  'example_translation': instance.exampleTranslation,
  'source_type': instance.sourceType,
  'source_media_id': instance.sourceMediaId,
  'source_practice_id': instance.sourcePracticeId,
  'source_context': instance.sourceContext,
  'review_count': instance.reviewCount,
  'last_reviewed_at': instance.lastReviewedAt?.toIso8601String(),
  'next_review_at': instance.nextReviewAt?.toIso8601String(),
  'mastery_level': instance.masteryLevel,
  'is_starred': instance.isStarred,
  'notes': instance.notes,
  'deleted_at': instance.deletedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
