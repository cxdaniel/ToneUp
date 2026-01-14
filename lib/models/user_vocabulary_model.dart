import 'package:json_annotation/json_annotation.dart';

part 'user_vocabulary_model.g.dart';

/// 用户生词本模型
/// 对应数据表：user_vocabulary
@JsonSerializable()
class UserVocabularyModel {
  final int id;
  @JsonKey(name: 'user_id')
  final String userId;

  // 词汇信息
  String word; // 词汇
  String? pinyin; // 拼音
  String? definition; // 释义
  @JsonKey(name: 'example_sentence')
  String? exampleSentence; // 例句
  @JsonKey(name: 'example_translation')
  String? exampleTranslation; // 例句翻译

  // 来源追溯
  @JsonKey(name: 'source_type')
  final String sourceType; // 'media' | 'practice' | 'manual'
  @JsonKey(name: 'source_media_id')
  final int? sourceMediaId;
  @JsonKey(name: 'source_practice_id')
  final int? sourcePracticeId;
  @JsonKey(name: 'source_context')
  String? sourceContext; // 原句上下文

  // 复习数据
  @JsonKey(name: 'review_count')
  int reviewCount; // 复习次数
  @JsonKey(name: 'last_reviewed_at')
  DateTime? lastReviewedAt; // 最后复习时间
  @JsonKey(name: 'next_review_at')
  DateTime? nextReviewAt; // 下次复习时间
  @JsonKey(name: 'mastery_level')
  int masteryLevel; // 掌握程度 (0-5)

  // 标记
  @JsonKey(name: 'is_starred')
  bool isStarred; // 重点标记
  String? notes; // 用户笔记

  // 软删除
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  // 元数据
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  UserVocabularyModel({
    required this.id,
    required this.userId,
    required this.word,
    this.pinyin,
    this.definition,
    this.exampleSentence,
    this.exampleTranslation,
    required this.sourceType,
    this.sourceMediaId,
    this.sourcePracticeId,
    this.sourceContext,
    this.reviewCount = 0,
    this.lastReviewedAt,
    this.nextReviewAt,
    this.masteryLevel = 0,
    this.isStarred = false,
    this.notes,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // 计算属性
  bool get isDeleted => deletedAt != null;
  bool get isFromMedia => sourceType == 'media';
  bool get isFromPractice => sourceType == 'practice';
  bool get isManual => sourceType == 'manual';
  bool get needsReview =>
      nextReviewAt != null && nextReviewAt!.isBefore(DateTime.now());

  /// 掌握程度文本
  String get masteryLevelText {
    switch (masteryLevel) {
      case 0:
        return '未学';
      case 1:
        return '认识';
      case 2:
        return '熟悉';
      case 3:
        return '掌握';
      case 4:
        return '熟练';
      case 5:
        return '精通';
      default:
        return '未知';
    }
  }

  /// 来源类型文本
  String get sourceTypeText {
    switch (sourceType) {
      case 'media':
        return '播客学习';
      case 'practice':
        return '练习模块';
      case 'manual':
        return '手动添加';
      default:
        return '未知';
    }
  }

  /// 记录复习（间隔重复算法）
  void recordReview({bool correct = true}) {
    reviewCount++;
    lastReviewedAt = DateTime.now();

    // 简单的间隔重复算法
    if (correct) {
      // 答对了，提升掌握程度
      if (masteryLevel < 5) {
        masteryLevel++;
      }
      // 根据掌握程度计算下次复习时间
      final intervals = [1, 3, 7, 14, 30, 90]; // 天数
      final days = intervals[masteryLevel];
      nextReviewAt = DateTime.now().add(Duration(days: days));
    } else {
      // 答错了，降低掌握程度
      if (masteryLevel > 0) {
        masteryLevel--;
      }
      // 第二天复习
      nextReviewAt = DateTime.now().add(const Duration(days: 1));
    }

    updatedAt = DateTime.now();
  }

  /// 切换重点标记
  void toggleStar() {
    isStarred = !isStarred;
    updatedAt = DateTime.now();
  }

  factory UserVocabularyModel.fromJson(Map<String, dynamic> json) =>
      _$UserVocabularyModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserVocabularyModelToJson(this);
}
