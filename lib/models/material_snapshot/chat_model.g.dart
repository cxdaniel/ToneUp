// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatModel _$ChatModelFromJson(Map<String, dynamic> json) =>
    ChatModel(role: json['role'] as String, text: json['text'] as String);

Map<String, dynamic> _$ChatModelToJson(ChatModel instance) => <String, dynamic>{
  'role': instance.role,
  'text': instance.text,
};
