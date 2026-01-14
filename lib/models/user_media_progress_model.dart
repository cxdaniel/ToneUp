import 'package:json_annotation/json_annotation.dart';

part 'user_media_progress_model.g.dart';

/// 用户媒体学习进度模型
/// 对应数据表：user_media_progress
@JsonSerializable()
class UserMediaProgressModel {
  final int id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'media_id')
  final int mediaId;

  // 播放进度
  @JsonKey(name: 'playback_position')
  double playbackPosition; // 当前播放位置（秒）
  bool completed; // 是否完成
  @JsonKey(name: 'completion_rate')
  double completionRate; // 完成率 (0-1)

  // 学习统计
  @JsonKey(name: 'play_count')
  int playCount; // 播放次数
  @JsonKey(name: 'total_watch_time')
  double totalWatchTime; // 累计观看时长（秒）
  @JsonKey(name: 'last_played_at')
  DateTime? lastPlayedAt;

  // 跟读练习数据
  @JsonKey(name: 'shadowing_attempts')
  int shadowingAttempts; // 跟读次数
  @JsonKey(name: 'shadowing_scores')
  List<double>? shadowingScores; // 每次跟读得分数组
  @JsonKey(name: 'average_shadowing_score')
  double? averageShadowingScore; // 平均跟读得分

  // 收藏状态
  @JsonKey(name: 'is_bookmarked')
  bool isBookmarked;
  @JsonKey(name: 'bookmarked_at')
  DateTime? bookmarkedAt;

  // 软删除
  @JsonKey(name: 'deleted_at')
  final DateTime? deletedAt;

  // 元数据
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;

  UserMediaProgressModel({
    required this.id,
    required this.userId,
    required this.mediaId,
    this.playbackPosition = 0,
    this.completed = false,
    this.completionRate = 0,
    this.playCount = 0,
    this.totalWatchTime = 0,
    this.lastPlayedAt,
    this.shadowingAttempts = 0,
    this.shadowingScores,
    this.averageShadowingScore,
    this.isBookmarked = false,
    this.bookmarkedAt,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // 计算属性
  bool get isDeleted => deletedAt != null;
  bool get isInProgress => playbackPosition > 0 && !completed;
  bool get hasProgress => playbackPosition > 0;

  /// 完成百分比（0-100）
  int get completionPercentage => (completionRate * 100).toInt();

  /// 格式化播放位置为 MM:SS
  String get formattedPosition {
    final minutes = playbackPosition.toInt() ~/ 60;
    final seconds = playbackPosition.toInt() % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// 格式化总观看时长
  String get formattedTotalWatchTime {
    final minutes = totalWatchTime.toInt() ~/ 60;
    final seconds = totalWatchTime.toInt() % 60;
    return '$minutes分$seconds秒';
  }

  /// 更新播放进度
  void updateProgress(double position, double totalDuration) {
    playbackPosition = position;
    completionRate = totalDuration > 0 ? position / totalDuration : 0;
    completed = completionRate >= 0.95; // 播放到95%即视为完成
    playCount++;
    lastPlayedAt = DateTime.now();
    updatedAt = DateTime.now();
  }

  /// 添加跟读得分
  void addShadowingScore(double score) {
    shadowingScores ??= [];
    shadowingScores!.add(score);
    shadowingAttempts = shadowingScores!.length;

    // 计算平均分
    if (shadowingScores!.isNotEmpty) {
      averageShadowingScore =
          shadowingScores!.reduce((a, b) => a + b) / shadowingScores!.length;
    }
    updatedAt = DateTime.now();
  }

  /// 切换收藏状态
  void toggleBookmark() {
    isBookmarked = !isBookmarked;
    bookmarkedAt = isBookmarked ? DateTime.now() : null;
    updatedAt = DateTime.now();
  }

  factory UserMediaProgressModel.fromJson(Map<String, dynamic> json) =>
      _$UserMediaProgressModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserMediaProgressModelToJson(this);
}
