// models/material_snapshot/chat_model.dart
import 'package:json_annotation/json_annotation.dart';
part 'chat_model.g.dart';

@JsonSerializable()
class ChatModel {
  // 对应 JSON 中的 "role"（如 "A"、"B"）
  @JsonKey(name: "role")
  final String role;

  // 对应 JSON 中的 "text"（聊天内容）
  @JsonKey(name: "text")
  final String text;

  // 构造函数：必填字段用 required（示例中无 null，按非空设计）
  ChatModel({required this.role, required this.text});

  // 反序列化：JSON → 模型
  factory ChatModel.fromJson(Map<String, dynamic> json) =>
      _$ChatModelFromJson(json);

  // 序列化：模型 → JSON
  Map<String, dynamic> toJson() => _$ChatModelToJson(this);
}
