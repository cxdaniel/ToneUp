import 'package:json_annotation/json_annotation.dart';
import 'package:toneup_app/models/enumerated_types.dart';

part 'indicators_model.g.dart';

@JsonSerializable()
class IndicatorsModel {
  final int id;
  final String indicator;
  final int level;
  final IndicatorCategory category;
  @JsonKey(name: "skill_group")
  final SkillGroup skillGroup;
  final double weight;
  @JsonKey(name: "created_at")
  final DateTime createdAt;
  @JsonKey(name: "material_types")
  final List<MaterialContentType> materialTypes;

  IndicatorsModel({
    required this.id,
    required this.indicator,
    required this.level,
    required this.category,
    required this.skillGroup,
    required this.weight,
    required this.createdAt,
    required this.materialTypes,
  });

  // 序列化方法
  factory IndicatorsModel.fromJson(Map<String, dynamic> json) =>
      _$IndicatorsModelFromJson(json);
  Map<String, dynamic> toJson() => _$IndicatorsModelToJson(this);
}
