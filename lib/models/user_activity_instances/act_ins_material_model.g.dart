// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'act_ins_material_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActInsMaterialModel _$ActInsMaterialModelFromJson(Map<String, dynamic> json) =>
    ActInsMaterialModel(
      type: $enumDecode(_$MaterialContentTypeEnumMap, json['type']),
      content: json['content'] as String,
    );

Map<String, dynamic> _$ActInsMaterialModelToJson(
  ActInsMaterialModel instance,
) => <String, dynamic>{
  'type': _$MaterialContentTypeEnumMap[instance.type]!,
  'content': instance.content,
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
