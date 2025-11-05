// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'material_snapshot_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaterialSnapshotModel _$MaterialSnapshotModelFromJson(
  Map<String, dynamic> json,
) => MaterialSnapshotModel(
  level: (json['level'] as num).toInt(),
  topicTitle: json['topic_title'] as String,
  grammars: (json['grammars'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  charsNew: (json['chars_new'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  sentences: (json['sentences'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  syllables: (json['syllables'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  wordsNew: (json['words_new'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  paragraphs: (json['paragraphs'] as List<dynamic>)
      .map((e) => (e as List<dynamic>).map((e) => e as String).toList())
      .toList(),
  charsReview: (json['chars_review'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  wordsReview: (json['words_review'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  dialogs: (json['dialogs'] as List<dynamic>)
      .map(
        (e) => (e as List<dynamic>)
            .map((e) => ChatModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      )
      .toList(),
  topicTag: json['topic_tag'] as String,
  cultureTag: json['culture_tag'] as String,
);

Map<String, dynamic> _$MaterialSnapshotModelToJson(
  MaterialSnapshotModel instance,
) => <String, dynamic>{
  'level': instance.level,
  'topic_title': instance.topicTitle,
  'grammars': instance.grammars,
  'chars_new': instance.charsNew,
  'sentences': instance.sentences,
  'syllables': instance.syllables,
  'words_new': instance.wordsNew,
  'paragraphs': instance.paragraphs,
  'chars_review': instance.charsReview,
  'words_review': instance.wordsReview,
  'dialogs': instance.dialogs,
  'topic_tag': instance.topicTag,
  'culture_tag': instance.cultureTag,
};
