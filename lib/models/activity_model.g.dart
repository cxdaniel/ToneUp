// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityModel _$ActivityModelFromJson(Map<String, dynamic> json) =>
    ActivityModel(
      id: (json['id'] as num).toInt(),
      quizTemplate: $enumDecode(_$QuizTemplateEnumMap, json['quiz_template']),
      activityTitle: json['activity_title'] as String,
      quizType: $enumDecode(_$QuizTypeEnumMap, json['quiz_type']),
      materialType: (json['material_type'] as List<dynamic>)
          .map((e) => $enumDecode(_$MaterialTypeEnumMap, e))
          .toList(),
      timeCost: (json['time_cost'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      indicatorCats: (json['indicator_cats'] as List<dynamic>)
          .map((e) => $enumDecode(_$IndicatorCategoryEnumMap, e))
          .toList(),
    );

Map<String, dynamic> _$ActivityModelToJson(ActivityModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'activity_title': instance.activityTitle,
      'quiz_template': _$QuizTemplateEnumMap[instance.quizTemplate]!,
      'quiz_type': _$QuizTypeEnumMap[instance.quizType]!,
      'material_type': instance.materialType
          .map((e) => _$MaterialTypeEnumMap[e]!)
          .toList(),
      'time_cost': instance.timeCost,
      'created_at': instance.createdAt.toIso8601String(),
      'indicator_cats': instance.indicatorCats
          .map((e) => _$IndicatorCategoryEnumMap[e]!)
          .toList(),
    };

const _$QuizTemplateEnumMap = {
  QuizTemplate.textToText: '看文选文',
  QuizTemplate.textToVoice: '看文选音',
  QuizTemplate.voiceToText: '听音选文',
  QuizTemplate.leftToRight: '左右配对',
  QuizTemplate.multiToMulti: '多项填多空',
  QuizTemplate.orderAndJoin: '连词成句',
  QuizTemplate.recordOfExample: '复述例句',
  QuizTemplate.tracOfExample: '描红写字',
  QuizTemplate.typeOfText: '键盘输入',
};

const _$QuizTypeEnumMap = {
  QuizType.choice: '选择题',
  QuizType.matching: '配对题',
  QuizType.cloze: '选择填空',
  QuizType.sorted: '选词拼句',
  QuizType.recoding: '复述录音',
  QuizType.tracing: '汉字描红',
  QuizType.typing: '文本输入',
};

const _$MaterialTypeEnumMap = {
  MaterialContentType.character: 'character',
  MaterialContentType.word: 'word',
  MaterialContentType.sentence: 'sentence',
  MaterialContentType.dialog: 'dialog',
  MaterialContentType.paragraph: 'paragraph',
  MaterialContentType.syllable: 'syllable',
  MaterialContentType.grammar: 'grammar',
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
