// models/material_snapshot/tag_model.dart
import 'package:json_annotation/json_annotation.dart';
part 'quiz_options_model.g.dart';

enum OptionStatus { normal, fail, pass, select }

@JsonSerializable()
class QuizOptionsModel {
  final String text;
  final String voice;
  @JsonKey(name: "is_correct")
  final bool? isCorrect;
  OptionStatus? state;
  bool? isPlaying = false;
  bool? isLoading = false;

  QuizOptionsModel({required this.text, required this.voice, this.isCorrect});

  factory QuizOptionsModel.fromJson(Map<String, dynamic> json) =>
      _$QuizOptionsModelFromJson(json);

  Map<String, dynamic> toJson() => _$QuizOptionsModelToJson(this);
}
