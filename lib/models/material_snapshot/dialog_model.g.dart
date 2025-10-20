// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dialog_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DialogModel _$DialogModelFromJson(Map<String, dynamic> json) => DialogModel(
  chat: (json['chat'] as List<dynamic>)
      .map((e) => ChatModel.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DialogModelToJson(DialogModel instance) =>
    <String, dynamic>{'chat': instance.chat};
