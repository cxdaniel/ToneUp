// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'act_ins_material_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActInsMaterialModel _$ActInsMaterialModelFromJson(Map<String, dynamic> json) =>
    ActInsMaterialModel(
      type: $enumDecode(_$MaterialTypeEnumMap, json['type']),
      content: json['content'] as String,
    );

Map<String, dynamic> _$ActInsMaterialModelToJson(
  ActInsMaterialModel instance,
) => <String, dynamic>{
  'type': _$MaterialTypeEnumMap[instance.type]!,
  'content': instance.content,
};

const _$MaterialTypeEnumMap = {
  MaterialType.character: 'character',
  MaterialType.word: 'word',
  MaterialType.sentence: 'sentence',
  MaterialType.dialog: 'dialog',
  MaterialType.paragraph: 'paragraph',
  MaterialType.syllable: 'syllable',
  MaterialType.grammar: 'grammar',
};
