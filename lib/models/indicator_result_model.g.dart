// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indicator_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IndicatorResultModel _$IndicatorResultModelFromJson(
  Map<String, dynamic> json,
) => IndicatorResultModel(
  score: (json['score'] as num).toDouble(),
  isEligibleForUpgrade: json['isEligibleForUpgrade'] as bool,
  coreIndicatorCoverage: (json['coreIndicatorCoverage'] as num).toDouble(),
  coreIndicatorDetails: (json['coreIndicatorDetails'] as List<dynamic>)
      .map((e) => e as Map<String, dynamic>)
      .toList(),
  consecutiveQualifiedCount: (json['consecutiveQualifiedCount'] as num)
      .toDouble(),
  recentPractice: json['recentPractice'] as Map<String, dynamic>,
  upgradeGap: (json['upgradeGap'] as num).toDouble(),
  message: json['message'] as String,
);

Map<String, dynamic> _$IndicatorResultModelToJson(
  IndicatorResultModel instance,
) => <String, dynamic>{
  'score': instance.score,
  'isEligibleForUpgrade': instance.isEligibleForUpgrade,
  'coreIndicatorCoverage': instance.coreIndicatorCoverage,
  'coreIndicatorDetails': instance.coreIndicatorDetails,
  'consecutiveQualifiedCount': instance.consecutiveQualifiedCount,
  'recentPractice': instance.recentPractice,
  'upgradeGap': instance.upgradeGap,
  'message': instance.message,
};
