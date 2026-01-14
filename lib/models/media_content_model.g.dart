// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_content_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MediaContentModel _$MediaContentModelFromJson(Map<String, dynamic> json) =>
    MediaContentModel(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      coverImageUrl: json['cover_image_url'] as String?,
      contentType: json['content_type'] as String,
      sourceType: json['source_type'] as String,
      mediaUrl: json['media_url'] as String,
      externalId: json['external_id'] as String?,
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      hskLevel: (json['hsk_level'] as num?)?.toInt(),
      difficultyScore: (json['difficulty_score'] as num?)?.toDouble(),
      vocabularyList: (json['vocabulary_list'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      topicTag: json['topic_tag'] as String?,
      cultureTag: json['culture_tag'] as String?,
      indicatorCats: (json['indicator_cats'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
      transcript: json['transcript'] == null
          ? null
          : TranscriptData.fromJson(json['transcript'] as Map<String, dynamic>),
      wordTimingsJson: json['word_timings'] as Map<String, dynamic>?,
      processingStatus: json['processing_status'] as String? ?? 'pending',
      processingError: json['processing_error'] as String?,
      processedAt: json['processed_at'] == null
          ? null
          : DateTime.parse(json['processed_at'] as String),
      reviewStatus: json['review_status'] as String? ?? 'approved',
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] == null
          ? null
          : DateTime.parse(json['reviewed_at'] as String),
      rejectionReason: json['rejection_reason'] as String?,
      viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      bookmarkCount: (json['bookmark_count'] as num?)?.toInt() ?? 0,
      uploadedBy: json['uploaded_by'] as String?,
      deletedAt: json['deleted_at'] == null
          ? null
          : DateTime.parse(json['deleted_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$MediaContentModelToJson(MediaContentModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'cover_image_url': instance.coverImageUrl,
      'content_type': instance.contentType,
      'source_type': instance.sourceType,
      'media_url': instance.mediaUrl,
      'external_id': instance.externalId,
      'duration_seconds': instance.durationSeconds,
      'hsk_level': instance.hskLevel,
      'difficulty_score': instance.difficultyScore,
      'vocabulary_list': instance.vocabularyList,
      'topic_tag': instance.topicTag,
      'culture_tag': instance.cultureTag,
      'indicator_cats': instance.indicatorCats,
      'transcript': instance.transcript,
      'word_timings': instance.wordTimingsJson,
      'processing_status': instance.processingStatus,
      'processing_error': instance.processingError,
      'processed_at': instance.processedAt?.toIso8601String(),
      'review_status': instance.reviewStatus,
      'reviewed_by': instance.reviewedBy,
      'reviewed_at': instance.reviewedAt?.toIso8601String(),
      'rejection_reason': instance.rejectionReason,
      'view_count': instance.viewCount,
      'like_count': instance.likeCount,
      'bookmark_count': instance.bookmarkCount,
      'uploaded_by': instance.uploadedBy,
      'deleted_at': instance.deletedAt?.toIso8601String(),
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

TranscriptData _$TranscriptDataFromJson(Map<String, dynamic> json) =>
    TranscriptData(
      segments: (json['segments'] as List<dynamic>)
          .map((e) => TranscriptSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TranscriptDataToJson(TranscriptData instance) =>
    <String, dynamic>{'segments': instance.segments};

TranscriptSegment _$TranscriptSegmentFromJson(Map<String, dynamic> json) =>
    TranscriptSegment(
      id: (json['id'] as num).toInt(),
      start: (json['start'] as num).toDouble(),
      end: (json['end'] as num).toDouble(),
      text: json['text'] as String,
      pinyin: json['pinyin'] as String?,
      translation: json['translation'] as String?,
      keywords: (json['keywords'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$TranscriptSegmentToJson(TranscriptSegment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'start': instance.start,
      'end': instance.end,
      'text': instance.text,
      'pinyin': instance.pinyin,
      'translation': instance.translation,
      'keywords': instance.keywords,
    };
