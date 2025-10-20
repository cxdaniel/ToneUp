// models/material_snapshot/tag_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'tag_model.g.dart';

@JsonSerializable()
class TagModel {
  // 对应 JSON 中的 "id"（标签ID，如 1、59）
  @JsonKey(name: "id")
  final int id;

  // 对应 JSON 中的 "tag"（标签名称，如 "问候与告别"）
  @JsonKey(name: "tag")
  final String tag;

  // 对应 JSON 中的 "domain"（标签领域，如 "topic"、"culture"）
  @JsonKey(name: "domain")
  final String domain;

  // 对应 JSON 中的 "category"（标签分类，如 "日常生活"）
  @JsonKey(name: "category")
  final String category;

  // 构造函数：全部必填（示例中无 null）
  TagModel({
    required this.id,
    required this.tag,
    required this.domain,
    required this.category,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) =>
      _$TagModelFromJson(json);

  Map<String, dynamic> toJson() => _$TagModelToJson(this);
}
