// models/material_snapshot/material_snapshot_model.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:toneup_app/models/material_snapshot/chat_model.dart';

part 'material_snapshot_model.g.dart';

@JsonSerializable()
class MaterialSnapshotModel {
  // 1. 基础字段
  @JsonKey(name: "level")
  final int level; // 级别（如 1）

  @JsonKey(name: "topic_title")
  final String topicTitle; // 主题标题（如 "Greetings and Farewells..."）

  // 2. 字符串数组字段
  @JsonKey(name: "grammars")
  final List<String> grammars; // 语法列表（如 ["问候句型：...", ...]）

  @JsonKey(name: "chars_new")
  final List<String> charsNew; // 新字符列表（如 ["你", "我", ...]）

  @JsonKey(name: "sentences")
  final List<String> sentences; // 句子列表（如 ["你好。", ...]）

  @JsonKey(name: "syllables")
  final List<String> syllables; // 音节列表（如 ["nǐ", "wǒ", ...]）

  @JsonKey(name: "words_new")
  final List<String> wordsNew; // 新单词列表（如 ["你好", "早上好", ...]）

  @JsonKey(name: "paragraphs")
  final List<List<String>> paragraphs; // 段落列表（如 ["早上，小红见到老师...", ...]）

  @JsonKey(name: "chars_review")
  final List<String> charsReview; // 复习字符列表（示例为空数组）

  @JsonKey(name: "words_review")
  final List<String> wordsReview; // 复习单词列表（示例为空数组）

  // 3. 嵌套子模型数组
  @JsonKey(name: "dialogs")
  final List<List<ChatModel>> dialogs; // 对话列表

  // 4. 嵌套子模型（可选字段：假设 culture_tag 可能为 null，设为可空）
  @JsonKey(name: "topic_tag")
  final String topicTag; // 主题标签（必选，示例中有值）

  @JsonKey(name: "culture_tag")
  final String cultureTag; // 文化标签（可选，设为可空）

  // 构造函数：按示例结构定义必填/可选
  MaterialSnapshotModel({
    required this.level,
    required this.topicTitle,
    required this.grammars,
    required this.charsNew,
    required this.sentences,
    required this.syllables,
    required this.wordsNew,
    required this.paragraphs,
    required this.charsReview,
    required this.wordsReview,
    required this.dialogs,
    required this.topicTag,
    required this.cultureTag,
  });

  factory MaterialSnapshotModel.fromJson(Map<String, dynamic> json) =>
      _$MaterialSnapshotModelFromJson(json);

  Map<String, dynamic> toJson() => _$MaterialSnapshotModelToJson(this);
}
