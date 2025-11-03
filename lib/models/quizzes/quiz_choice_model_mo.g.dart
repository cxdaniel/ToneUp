// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_choice_model_mo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizChoiceModelMO _$QuizChoiceModelMOFromJson(Map<String, dynamic> json) =>
    QuizChoiceModelMO(
      explain: json['explain'] as String,
      question: json['question'] as String,
      material: QuizMaterialModel.fromJson(
        json['material'] as Map<String, dynamic>,
      ),
      options: (json['options'] as List<dynamic>)
          .map((e) => QuizOptionsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QuizChoiceModelMOToJson(QuizChoiceModelMO instance) =>
    <String, dynamic>{
      'explain': instance.explain,
      'question': instance.question,
      'material': instance.material,
      'options': instance.options,
    };
