// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz_options_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuizOptionsModel _$QuizOptionsModelFromJson(Map<String, dynamic> json) =>
    QuizOptionsModel(
        text: json['text'] as String,
        voice: json['voice'] as String?,
        isCorrect: json['is_correct'] as bool?,
      )
      ..state = $enumDecodeNullable(_$OptionStatusEnumMap, json['state'])
      ..isPlaying = json['isPlaying'] as bool?
      ..isLoading = json['isLoading'] as bool?;

Map<String, dynamic> _$QuizOptionsModelToJson(QuizOptionsModel instance) =>
    <String, dynamic>{
      'text': instance.text,
      'voice': instance.voice,
      'is_correct': instance.isCorrect,
      'state': _$OptionStatusEnumMap[instance.state],
      'isPlaying': instance.isPlaying,
      'isLoading': instance.isLoading,
    };

const _$OptionStatusEnumMap = {
  OptionStatus.normal: 'normal',
  OptionStatus.fail: 'fail',
  OptionStatus.pass: 'pass',
  OptionStatus.select: 'select',
};
