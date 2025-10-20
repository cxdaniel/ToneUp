import 'package:json_annotation/json_annotation.dart';
import 'package:toneup_app/models/material_snapshot/dialog_model.dart';

part 'user_materials_model.g.dart';

@JsonSerializable()
class UserMaterialsModel {
  final int id;
  @JsonKey(name: "user_id")
  final String userId;
  final int level;
  @JsonKey(name: "topic_tag")
  final int topicTag;
  @JsonKey(name: "culture_tag")
  final int cultureTag;
  @JsonKey(name: "chars_review")
  final List<String> charsReview;
  @JsonKey(name: "words_review")
  final List<String> wordsReview;
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @JsonKey(name: "topic_title")
  final String topicTitle;
  final List<String> chars;
  final List<String> words;
  final List<String> syllables;
  final List<String> grammars;
  final List<String> sentences;
  final List<String> paragraphs;
  final List<DialogModel> dialogs;

  UserMaterialsModel({
    required this.id,
    required this.userId,
    required this.level,
    required this.topicTag,
    required this.cultureTag,
    required this.charsReview,
    required this.wordsReview,
    required this.createdAt,
    required this.topicTitle,
    required this.chars,
    required this.words,
    required this.syllables,
    required this.grammars,
    required this.sentences,
    required this.paragraphs,
    required this.dialogs,
  });

  // 序列化方法
  factory UserMaterialsModel.fromJson(Map<String, dynamic> json) =>
      _$UserMaterialsModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserMaterialsModelToJson(this);
}
