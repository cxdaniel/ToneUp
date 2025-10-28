import 'package:json_annotation/json_annotation.dart';
import 'package:toneup_app/models/enumerated_types.dart';
part 'act_ins_material_model.g.dart';

@JsonSerializable()
class ActInsMaterialModel {
  final MaterialContentType type;
  final String content;

  ActInsMaterialModel({required this.type, required this.content});

  factory ActInsMaterialModel.fromJson(Map<String, dynamic> json) =>
      _$ActInsMaterialModelFromJson(json);
  Map<String, dynamic> toJson() => _$ActInsMaterialModelToJson(this);
}
