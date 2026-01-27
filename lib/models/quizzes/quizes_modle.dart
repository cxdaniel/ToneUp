import 'package:json_annotation/json_annotation.dart';
import 'package:toneup_app/models/activity_model.dart';
import 'package:toneup_app/models/enumerated_types.dart';
import 'package:toneup_app/models/indicators_model.dart';

part 'quizes_modle.g.dart';

@JsonSerializable()
class QuizesModle {
  final int id;
  @JsonKey(name: "activity_id")
  final int activityId;
  @JsonKey(name: "indicator_id")
  final int indicatorId;
  final int level;
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @JsonKey(name: "topic_tag")
  String? topicTag;
  @JsonKey(name: "culture_tag")
  String? cultureTag;
  String? material;
  @JsonKey(name: "material_type")
  MaterialContentType? materialType;
  /////
  String? stem;
  String? question;
  List<Map<String, dynamic>>? options;
  String? explain;
  String? lang;

  // @JsonKey(name: "material_id")
  // final int? materialId;

  /// 关联属性
  ActivityModel? activity;
  IndicatorsModel? indicator;

  QuizesModle({
    required this.id,
    required this.activityId,
    required this.indicatorId,
    required this.level,
    required this.createdAt,
    this.topicTag,
    this.cultureTag,
    this.material,
    this.materialType,
    this.stem,
    this.question,
    this.options,
    this.explain,
    this.lang,
  });

  // 序列化方法（需运行 build_runner 生成）
  factory QuizesModle.fromJson(Map<String, dynamic> json) =>
      _$QuizesModleFromJson(json);

  Map<String, dynamic> toJson() => _$QuizesModleToJson(this);
}
