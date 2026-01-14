import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/user_media_progress_model.dart';
import 'package:flutter/foundation.dart';

/// 用户媒体学习进度服务类
/// 负责播放进度、跟读练习、收藏等操作
class MediaProgressService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================================
  // 查询操作
  // ============================================================================

  /// 获取用户对特定媒体的学习进度
  Future<UserMediaProgressModel?> getProgress(int mediaId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('user_media_progress')
          .select()
          .eq('user_id', userId)
          .eq('media_id', mediaId)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) return null;
      return UserMediaProgressModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ MediaProgressService.getProgress 失败: $e');
      rethrow;
    }
  }

  /// 获取用户所有学习进度（最近播放）
  Future<List<UserMediaProgressModel>> getRecentProgress({
    int limit = 20,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_media_progress')
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('last_played_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => UserMediaProgressModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ MediaProgressService.getRecentProgress 失败: $e');
      rethrow;
    }
  }

  /// 获取用户收藏的播客
  Future<List<UserMediaProgressModel>> getBookmarkedMedia() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_media_progress')
          .select()
          .eq('user_id', userId)
          .eq('is_bookmarked', true)
          .isFilter('deleted_at', null)
          .order('bookmarked_at', ascending: false);

      return (response as List)
          .map((json) => UserMediaProgressModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ MediaProgressService.getBookmarkedMedia 失败: $e');
      rethrow;
    }
  }

  /// 获取用户未完成的播客
  Future<List<UserMediaProgressModel>> getInProgressMedia() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_media_progress')
          .select()
          .eq('user_id', userId)
          .eq('completed', false)
          .gt('playback_position', 0)
          .isFilter('deleted_at', null)
          .order('last_played_at', ascending: false);

      return (response as List)
          .map((json) => UserMediaProgressModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ MediaProgressService.getInProgressMedia 失败: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 创建/更新操作
  // ============================================================================

  /// 更新播放进度
  Future<UserMediaProgressModel> updateProgress({
    required int mediaId,
    required double position,
    required double totalDuration,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      // 计算完成率
      final completionRate = totalDuration > 0 ? position / totalDuration : 0;
      final isCompleted = completionRate >= 0.95;

      // 查找现有进度记录
      final existing = await getProgress(mediaId);

      if (existing != null) {
        // 更新现有记录
        final updatedData = {
          'playback_position': position,
          'completion_rate': completionRate,
          'completed': isCompleted,
          'play_count': existing.playCount + 1,
          'total_watch_time': existing.totalWatchTime + 1, // 简化处理，每次 +1 秒
          'last_played_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        final response = await _supabase
            .from('user_media_progress')
            .update(updatedData)
            .eq('id', existing.id)
            .select()
            .single();

        debugPrint('✅ 播放进度已更新: $mediaId');
        return UserMediaProgressModel.fromJson(response);
      } else {
        // 创建新记录
        final newData = {
          'user_id': userId,
          'media_id': mediaId,
          'playback_position': position,
          'completion_rate': completionRate,
          'completed': isCompleted,
          'play_count': 1,
          'total_watch_time': 1,
          'last_played_at': DateTime.now().toIso8601String(),
        };

        final response = await _supabase
            .from('user_media_progress')
            .insert(newData)
            .select()
            .single();

        debugPrint('✅ 播放进度已创建: $mediaId');
        return UserMediaProgressModel.fromJson(response);
      }
    } catch (e) {
      debugPrint('❌ MediaProgressService.updateProgress 失败: $e');
      rethrow;
    }
  }

  /// 添加跟读得分
  Future<void> addShadowingScore(int mediaId, double score) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final existing = await getProgress(mediaId);
      if (existing == null) {
        throw Exception('进度记录不存在');
      }

      final scores = existing.shadowingScores ?? [];
      scores.add(score);

      final averageScore = scores.reduce((a, b) => a + b) / scores.length;

      await _supabase
          .from('user_media_progress')
          .update({
            'shadowing_scores': scores,
            'shadowing_attempts': scores.length,
            'average_shadowing_score': averageScore,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', existing.id);

      debugPrint('✅ 跟读得分已添加: $mediaId, 得分: $score');
    } catch (e) {
      debugPrint('❌ MediaProgressService.addShadowingScore 失败: $e');
      rethrow;
    }
  }

  /// 切换收藏状态
  Future<bool> toggleBookmark(int mediaId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final existing = await getProgress(mediaId);

      if (existing != null) {
        // 更新现有记录
        final newBookmarkState = !existing.isBookmarked;

        await _supabase
            .from('user_media_progress')
            .update({
              'is_bookmarked': newBookmarkState,
              'bookmarked_at': newBookmarkState
                  ? DateTime.now().toIso8601String()
                  : null,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing.id);

        debugPrint('✅ 收藏状态已更新: $mediaId -> $newBookmarkState');
        return newBookmarkState;
      } else {
        // 创建新记录（直接收藏）
        await _supabase.from('user_media_progress').insert({
          'user_id': userId,
          'media_id': mediaId,
          'is_bookmarked': true,
          'bookmarked_at': DateTime.now().toIso8601String(),
        });

        debugPrint('✅ 已收藏: $mediaId');
        return true;
      }
    } catch (e) {
      debugPrint('❌ MediaProgressService.toggleBookmark 失败: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 删除操作
  // ============================================================================

  /// 删除进度记录（软删除）
  Future<void> deleteProgress(int progressId) async {
    try {
      await _supabase
          .from('user_media_progress')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', progressId);

      debugPrint('✅ 进度记录已删除: $progressId');
    } catch (e) {
      debugPrint('❌ MediaProgressService.deleteProgress 失败: $e');
      rethrow;
    }
  }
}
