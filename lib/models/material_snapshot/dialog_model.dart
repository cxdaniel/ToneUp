// models/material_snapshot/dialog_model.dart
import 'package:json_annotation/json_annotation.dart';
import 'chat_model.dart'; // 导入内层 ChatModel

part 'dialog_model.g.dart';

@JsonSerializable()
class DialogModel {
  // 对应 JSON 中的 "chat"（嵌套 ChatModel 数组）
  @JsonKey(name: "chat")
  final List<ChatModel> chat;

  // 构造函数：chat 为必填数组（示例中无空）
  DialogModel({required this.chat});

  factory DialogModel.fromJson(Map<String, dynamic> json) =>
      _$DialogModelFromJson(json);

  Map<String, dynamic> toJson() => _$DialogModelToJson(this);
}
