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
      .map((e) => IndicatorCoreDetailModel.fromJson(e as Map<String, dynamic>))
      .toList(),
  consecutiveQualifiedCount: (json['consecutiveQualifiedCount'] as num)
      .toDouble(),
  recentPractice: RecentPracticeModel.fromJson(
    json['recentPractice'] as Map<String, dynamic>,
  ),
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

RecentPracticeModel _$RecentPracticeModelFromJson(Map<String, dynamic> json) =>
    RecentPracticeModel(
      practiceCount7d: (json['practiceCount7d'] as num).toInt(),
      practiceCount30d: (json['practiceCount30d'] as num).toInt(),
      lastPracticeTime: json['lastPracticeTime'] == null
          ? null
          : DateTime.parse(json['lastPracticeTime'] as String),
    );

Map<String, dynamic> _$RecentPracticeModelToJson(
  RecentPracticeModel instance,
) => <String, dynamic>{
  'practiceCount7d': instance.practiceCount7d,
  'practiceCount30d': instance.practiceCount30d,
  'lastPracticeTime': instance.lastPracticeTime?.toIso8601String(),
};

IndicatorCoreDetailModel _$IndicatorCoreDetailModelFromJson(
  Map<String, dynamic> json,
) => IndicatorCoreDetailModel(
  indicatorId: (json['indicatorId'] as num).toInt(),
  indicatorName: json['indicatorName'] as String,
  indicatorWeight: (json['indicatorWeight'] as num).toDouble(),
  minimum: (json['minimum'] as num).toDouble(),
  practiceCount: (json['practiceCount'] as num).toInt(),
  avgScore: (json['avgScore'] as num).toDouble(),
  isQualified: json['isQualified'] as bool,
  practiceGap: (json['practiceGap'] as num).toDouble(),
)..priorityScore = (json['priorityScore'] as num?)?.toDouble();

Map<String, dynamic> _$IndicatorCoreDetailModelToJson(
  IndicatorCoreDetailModel instance,
) => <String, dynamic>{
  'indicatorId': instance.indicatorId,
  'indicatorName': instance.indicatorName,
  'indicatorWeight': instance.indicatorWeight,
  'minimum': instance.minimum,
  'practiceCount': instance.practiceCount,
  'avgScore': instance.avgScore,
  'isQualified': instance.isQualified,
  'practiceGap': instance.practiceGap,
  'priorityScore': instance.priorityScore,
};
