import 'package:json_annotation/json_annotation.dart';
part 'indicator_result_model.g.dart';

@JsonSerializable()
class IndicatorResultModel {
  /// 评分结果
  final double score;

  /// 是否符合升级条件
  final bool isEligibleForUpgrade;

  /// 核心指标覆盖率
  final double coreIndicatorCoverage;

  /// 核心指标详情
  final List<IndicatorCoreDetailModel> coreIndicatorDetails;

  /// 连续合格次数
  final double consecutiveQualifiedCount;

  /// 最近的练习情况
  final RecentPracticeModel recentPractice;

  /// 升级差距
  final double upgradeGap;

  /// 评测信息
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

@JsonSerializable()
class RecentPracticeModel {
  /// 过去7天的练习次数
  final int practiceCount7d;

  /// 过去30天的练习次数
  final int practiceCount30d;

  /// 最近一次练习时间
  final DateTime? lastPracticeTime;

  RecentPracticeModel({
    required this.practiceCount7d,
    required this.practiceCount30d,
    this.lastPracticeTime,
  });

  factory RecentPracticeModel.fromJson(Map<String, dynamic> json) =>
      _$RecentPracticeModelFromJson(json);
  Map<String, dynamic> toJson() => _$RecentPracticeModelToJson(this);
}

@JsonSerializable()
class IndicatorCoreDetailModel {
  /// 指标ID
  final int indicatorId;

  /// 指标名称
  final String indicatorName;

  /// 指标权重
  final double indicatorWeight;

  /// 最低次数要求
  final double minimum;

  /// 练习次数
  final int practiceCount;

  /// 平均得分
  final double avgScore;

  /// 是否合格
  final bool isQualified;

  /// 练习差距
  final double practiceGap;
  double? priorityScore;

  IndicatorCoreDetailModel({
    required this.indicatorId,
    required this.indicatorName,
    required this.indicatorWeight,
    required this.minimum,
    required this.practiceCount,
    required this.avgScore,
    required this.isQualified,
    required this.practiceGap,
  });

  factory IndicatorCoreDetailModel.fromJson(Map<String, dynamic> json) =>
      _$IndicatorCoreDetailModelFromJson(json);
  Map<String, dynamic> toJson() => _$IndicatorCoreDetailModelToJson(this);
}
