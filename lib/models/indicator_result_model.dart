import 'package:json_annotation/json_annotation.dart';

part 'indicator_result_model.g.dart';

@JsonSerializable()
class IndicatorResultModel {
  final double score;
  final bool isEligibleForUpgrade;
  final double coreIndicatorCoverage;
  final List<Map<String, dynamic>> coreIndicatorDetails;
  final double consecutiveQualifiedCount;
  final Map<String, dynamic> recentPractice;
  final double upgradeGap;
  final String message;

  IndicatorResultModel({
    required this.score,
    required this.isEligibleForUpgrade,
    required this.coreIndicatorCoverage,
    required this.coreIndicatorDetails,
    required this.consecutiveQualifiedCount,
    required this.recentPractice,
    required this.upgradeGap,
    required this.message,
  });

  factory IndicatorResultModel.fromJson(Map<String, dynamic> json) =>
      _$IndicatorResultModelFromJson(json);
  Map<String, dynamic> toJson() => _$IndicatorResultModelToJson(this);
}
