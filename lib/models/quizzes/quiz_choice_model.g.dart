// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_choice_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizChoiceModel _$QuizChoiceModelFromJson(Map<String, dynamic> json) =>
    QuizChoiceModel(
      actId: (json['act_id'] as num).toInt(),
      explain: json['explain'] as String,
      question: json['question'] as String,
      material: QuizMaterialModel.fromJson(
        json['material'] as Map<String, dynamic>,
      ),
      options: (json['options'] as List<dynamic>)
          .map((e) => QuizOptionsModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$QuizChoiceModelToJson(QuizChoiceModel instance) =>
    <String, dynamic>{
      'act_id': instance.actId,
      'explain': instance.explain,
      'question': instance.question,
      'material': instance.material,
      'options': instance.options,
    };
