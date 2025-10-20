// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_materials_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserMaterialsModel _$UserMaterialsModelFromJson(Map<String, dynamic> json) =>
    UserMaterialsModel(
      id: (json['id'] as num).toInt(),
      userId: json['user_id'] as String,
      level: (json['level'] as num).toInt(),
      topicTag: (json['topic_tag'] as num).toInt(),
      cultureTag: (json['culture_tag'] as num).toInt(),
      charsReview: (json['chars_review'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      wordsReview: (json['words_review'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      topicTitle: json['topic_title'] as String,
      chars: (json['chars'] as List<dynamic>).map((e) => e as String).toList(),
      words: (json['words'] as List<dynamic>).map((e) => e as String).toList(),
      syllables: (json['syllables'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      grammars: (json['grammars'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      sentences: (json['sentences'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      paragraphs: (json['paragraphs'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      dialogs: (json['dialogs'] as List<dynamic>)
          .map((e) => DialogModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$UserMaterialsModelToJson(UserMaterialsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'level': instance.level,
      'topic_tag': instance.topicTag,
      'culture_tag': instance.cultureTag,
      'chars_review': instance.charsReview,
      'words_review': instance.wordsReview,
      'created_at': instance.createdAt.toIso8601String(),
      'topic_title': instance.topicTitle,
      'chars': instance.chars,
      'words': instance.words,
      'syllables': instance.syllables,
      'grammars': instance.grammars,
      'sentences': instance.sentences,
      'paragraphs': instance.paragraphs,
      'dialogs': instance.dialogs,
    };
