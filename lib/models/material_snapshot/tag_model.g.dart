// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TagModel _$TagModelFromJson(Map<String, dynamic> json) => TagModel(
  id: (json['id'] as num).toInt(),
  tag: json['tag'] as String,
  domain: json['domain'] as String,
  category: json['category'] as String,
);

Map<String, dynamic> _$TagModelToJson(TagModel instance) => <String, dynamic>{
  'id': instance.id,
  'tag': instance.tag,
  'domain': instance.domain,
  'category': instance.category,
};
