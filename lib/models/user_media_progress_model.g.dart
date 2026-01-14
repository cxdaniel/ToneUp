// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_media_progress_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserMediaProgressModel _$UserMediaProgressModelFromJson(
  Map<String, dynamic> json,
) => UserMediaProgressModel(
  id: (json['id'] as num).toInt(),
  userId: json['user_id'] as String,
  mediaId: (json['media_id'] as num).toInt(),
  playbackPosition: (json['playback_position'] as num?)?.toDouble() ?? 0,
  completed: json['completed'] as bool? ?? false,
  completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0,
  playCount: (json['play_count'] as num?)?.toInt() ?? 0,
  totalWatchTime: (json['total_watch_time'] as num?)?.toDouble() ?? 0,
  lastPlayedAt: json['last_played_at'] == null
      ? null
      : DateTime.parse(json['last_played_at'] as String),
  shadowingAttempts: (json['shadowing_attempts'] as num?)?.toInt() ?? 0,
  shadowingScores: (json['shadowing_scores'] as List<dynamic>?)
      ?.map((e) => (e as num).toDouble())
      .toList(),
  averageShadowingScore: (json['average_shadowing_score'] as num?)?.toDouble(),
  isBookmarked: json['is_bookmarked'] as bool? ?? false,
  bookmarkedAt: json['bookmarked_at'] == null
      ? null
      : DateTime.parse(json['bookmarked_at'] as String),
  deletedAt: json['deleted_at'] == null
      ? null
      : DateTime.parse(json['deleted_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$UserMediaProgressModelToJson(
  UserMediaProgressModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'user_id': instance.userId,
  'media_id': instance.mediaId,
  'playback_position': instance.playbackPosition,
  'completed': instance.completed,
  'completion_rate': instance.completionRate,
  'play_count': instance.playCount,
  'total_watch_time': instance.totalWatchTime,
  'last_played_at': instance.lastPlayedAt?.toIso8601String(),
  'shadowing_attempts': instance.shadowingAttempts,
  'shadowing_scores': instance.shadowingScores,
  'average_shadowing_score': instance.averageShadowingScore,
  'is_bookmarked': instance.isBookmarked,
  'bookmarked_at': instance.bookmarkedAt?.toIso8601String(),
  'deleted_at': instance.deletedAt?.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt.toIso8601String(),
};
