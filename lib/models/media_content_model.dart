import 'package:json_annotation/json_annotation.dart';
import 'word_timing_model.dart';

part 'media_content_model.g.dart';

/// 媒体内容模型（播客/视频）
/// 对应数据表：media_content
@JsonSerializable()
class MediaContentModel {
  final int id;
  final String title;
  final String? description;
  @JsonKey(name: 'cover_image_url')
  final String? coverImageUrl;

  // 媒体类型
  @JsonKey(name: 'content_type')
  final String contentType; // 'audio' | 'video'
  @JsonKey(name: 'source_type')
  final String sourceType; // 'upload' | 'youtube' | 'bilibili' | 'aigc'

  // 媒体资源
  @JsonKey(name: 'media_url')
  final String mediaUrl;
  @JsonKey(name: 'external_id')
  final String? externalId;
  @JsonKey(name: 'duration_seconds')
  final int? durationSeconds;

  // 学习数据
  @JsonKey(name: 'hsk_level')
  final int? hskLevel;
  @JsonKey(name: 'difficulty_score')
  final double? difficultyScore;
  @JsonKey(name: 'vocabulary_list')
  final List<String>? vocabularyList;

  // 标签（与 user_materials 保持一致）
  @JsonKey(name: 'topic_tag')
  final String? topicTag;
  @JsonKey(name: 'culture_tag')
  final String? cultureTag;

  // 能力指标关联
  @JsonKey(name: 'indicator_cats')
  final List<int>? indicatorCats;

  // 字幕数据
  final TranscriptData? transcript;

  // 字级别时间数据（用于播放器字幕高亮）
  @JsonKey(name: 'word_timings')
  final Map<String, dynamic>? wordTimingsJson;

  // AIGC 处理状态
  @JsonKey(name: 'processing_status')
  final String processingStatus; // 'pending' | 'processing' | 'completed' | 'failed'
  @JsonKey(name: 'processing_error')
  final String? processingError;
  @JsonKey(name: 'processed_at')
  final DateTime? processedAt;

  // 审核状态
  @JsonKey(name: 'review_status')
  final String reviewStatus; // 'pending' | 'approved' | 'rejected'
  @JsonKey(name: 'reviewed_by')
  final String? reviewedBy;
  @JsonKey(name: 'reviewed_at')
  final DateTime? reviewedAt;
  @JsonKey(name: 'rejection_reason')
  final String? rejectionReason;

  // 统计数据
  @JsonKey(name: 'view_count')
  final int viewCount;
  @JsonKey(name: 'like_count')
  final int likeCount;
  @JsonKey(name: 'bookmark_count')
  final int bookmarkCount;

  // 上传者信息
  @JsonKey(name: 'uploaded_by')
  final String? uploadedBy;

  // 软删除
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  // 元数据
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  MediaContentModel({
    required this.id,
    required this.title,
    this.description,
    this.coverImageUrl,
    required this.contentType,
    required this.sourceType,
    required this.mediaUrl,
    this.externalId,
    this.durationSeconds,
    this.hskLevel,
    this.difficultyScore,
    this.vocabularyList,
    this.topicTag,
    this.cultureTag,
    this.indicatorCats,
    this.transcript,
    this.wordTimingsJson,
    this.processingStatus = 'pending',
    this.processingError,
    this.processedAt,
    this.reviewStatus = 'approved',
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.viewCount = 0,
    this.likeCount = 0,
    this.bookmarkCount = 0,
    this.uploadedBy,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // 懒加载解析 word_timings
  WordTimingsData? _wordTimings;
  WordTimingsData? get wordTimings {
    if (_wordTimings == null && wordTimingsJson != null) {
      try {
        _wordTimings = WordTimingsData.fromJson(wordTimingsJson!);
      } catch (e) {
        // 解析失败时返回null
        return null;
      }
    }
    return _wordTimings;
  }

  // 计算属性
  bool get isApproved => reviewStatus == 'approved';
  bool get isDeleted => deletedAt != null;
  bool get isProcessed => processingStatus == 'completed';
  bool get isAudio => contentType == 'audio';
  bool get isVideo => contentType == 'video';

  /// 格式化时长为 MM:SS
  String get formattedDuration {
    if (durationSeconds == null) return '--:--';
    final minutes = durationSeconds! ~/ 60;
    final seconds = durationSeconds! % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory MediaContentModel.fromJson(Map<String, dynamic> json) =>
      _$MediaContentModelFromJson(json);

  Map<String, dynamic> toJson() => _$MediaContentModelToJson(this);
}

/// 字幕数据模型
@JsonSerializable()
class TranscriptData {
  final List<TranscriptSegment> segments;

  TranscriptData({required this.segments});

  factory TranscriptData.fromJson(Map<String, dynamic> json) =>
      _$TranscriptDataFromJson(json);

  Map<String, dynamic> toJson() => _$TranscriptDataToJson(this);
}

/// 字幕片段模型
@JsonSerializable()
class TranscriptSegment {
  final int id;
  final double start; // 开始时间（秒）
  final double end; // 结束时间（秒）
  final String text; // 中文字幕
  final String? pinyin; // 拼音
  final String? translation; // 英文翻译
  final List<String>? keywords; // 关键词

  TranscriptSegment({
    required this.id,
    required this.start,
    required this.end,
    required this.text,
    this.pinyin,
    this.translation,
    this.keywords,
  });

  /// 片段时长（秒）
  double get duration => end - start;

  /// 格式化时间戳为 MM:SS
  String get formattedStart {
    final minutes = start.toInt() ~/ 60;
    final seconds = start.toInt() % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) =>
      _$TranscriptSegmentFromJson(json);

  Map<String, dynamic> toJson() => _$TranscriptSegmentToJson(this);
}
