// models/material_snapshot/tag_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'quiz_material_model.g.dart';

@JsonSerializable()
class QuizMaterialModel {
  final String text;
  final String voice;

  QuizMaterialModel({required this.text, required this.voice});

  factory QuizMaterialModel.fromJson(Map<String, dynamic> json) =>
      _$QuizMaterialModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuizMaterialModelToJson(this);
}
