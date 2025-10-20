// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indicators_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IndicatorsModel _$IndicatorsModelFromJson(Map<String, dynamic> json) =>
    IndicatorsModel(
      id: (json['id'] as num).toInt(),
      indicator: json['indicator'] as String,
      level: (json['level'] as num).toInt(),
      category: $enumDecode(_$IndicatorCategoryEnumMap, json['category']),
      skillGroup: $enumDecode(_$SkillGroupEnumMap, json['skill_group']),
      weight: (json['weight'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      materialTypes: (json['material_types'] as List<dynamic>)
          .map((e) => $enumDecode(_$MaterialTypeEnumMap, e))
          .toList(),
    );

Map<String, dynamic> _$IndicatorsModelToJson(IndicatorsModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'indicator': instance.indicator,
      'level': instance.level,
      'category': _$IndicatorCategoryEnumMap[instance.category]!,
      'skill_group': _$SkillGroupEnumMap[instance.skillGroup]!,
      'weight': instance.weight,
      'created_at': instance.createdAt.toIso8601String(),
      'material_types': instance.materialTypes
          .map((e) => _$MaterialTypeEnumMap[e]!)
          .toList(),
    };

const _$IndicatorCategoryEnumMap = {
  IndicatorCategory.charsRecognition: '辨认汉字',
  IndicatorCategory.wordRecognition: '辨认词汇',
  IndicatorCategory.grammar: '掌握语法',
  IndicatorCategory.listening: '听懂句子',
  IndicatorCategory.listeningSpeed: '听力速度',
  IndicatorCategory.syllable: '掌握音节',
  IndicatorCategory.expression: '口语表达',
  IndicatorCategory.comprehension: '文本理解',
  IndicatorCategory.readingSpeed: '阅读速度',
  IndicatorCategory.readingSkill: '阅读技能',
  IndicatorCategory.typingSpeed: '抄写速度',
  IndicatorCategory.writing: '汉字书写',
  IndicatorCategory.writingNorms: '书写规范',
  IndicatorCategory.writtenWriting: '书面写作',
  IndicatorCategory.translation: '文本翻译',
};

const _$SkillGroupEnumMap = {
  SkillGroup.recognition: '认',
  SkillGroup.listening: '听',
  SkillGroup.speaking: '说',
  SkillGroup.reading: '读',
  SkillGroup.writing: '写',
  SkillGroup.translation: '译',
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
