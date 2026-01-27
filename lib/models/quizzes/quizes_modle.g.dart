// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quizes_modle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizesModle _$QuizesModleFromJson(Map<String, dynamic> json) =>
    QuizesModle(
        id: (json['id'] as num).toInt(),
        activityId: (json['activity_id'] as num).toInt(),
        indicatorId: (json['indicator_id'] as num).toInt(),
        level: (json['level'] as num).toInt(),
        createdAt: DateTime.parse(json['created_at'] as String),
        topicTag: json['topic_tag'] as String?,
        cultureTag: json['culture_tag'] as String?,
        material: json['material'] as String?,
        materialType: $enumDecodeNullable(
          _$MaterialContentTypeEnumMap,
          json['material_type'],
        ),
        stem: json['stem'] as String?,
        question: json['question'] as String?,
        options: (json['options'] as List<dynamic>?)
            ?.map((e) => e as Map<String, dynamic>)
            .toList(),
        explain: json['explain'] as String?,
        lang: json['lang'] as String?,
      )
      ..activity = json['activity'] == null
          ? null
          : ActivityModel.fromJson(json['activity'] as Map<String, dynamic>)
      ..indicator = json['indicator'] == null
          ? null
          : IndicatorsModel.fromJson(json['indicator'] as Map<String, dynamic>);

Map<String, dynamic> _$QuizesModleToJson(QuizesModle instance) =>
    <String, dynamic>{
      'id': instance.id,
      'activity_id': instance.activityId,
      'indicator_id': instance.indicatorId,
      'level': instance.level,
      'created_at': instance.createdAt.toIso8601String(),
      'topic_tag': instance.topicTag,
      'culture_tag': instance.cultureTag,
      'material': instance.material,
      'material_type': _$MaterialContentTypeEnumMap[instance.materialType],
      'stem': instance.stem,
      'question': instance.question,
      'options': instance.options,
      'explain': instance.explain,
      'lang': instance.lang,
      'activity': instance.activity,
      'indicator': instance.indicator,
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
