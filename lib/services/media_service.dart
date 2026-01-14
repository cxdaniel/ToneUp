import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/media_content_model.dart';
import 'package:flutter/foundation.dart';

/// 媒体内容服务类
/// 负责播客/视频内容的 CRUD 操作
class MediaService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================================
  // 查询操作
  // ============================================================================

  /// 获取已审核通过的媒体列表
  /// [hskLevel] - 筛选 HSK 等级
  /// [topicTag] - 筛选话题标签
  /// [cultureTag] - 筛选文化标签
  /// [limit] - 返回数量限制
  /// [offset] - 偏移量（分页）
  Future<List<MediaContentModel>> getApprovedMedia({
    int? hskLevel,
    String? topicTag,
    String? cultureTag,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // 构建过滤查询
      var query = _supabase
          .from('media_content')
          .select()
          .eq('review_status', 'approved')
          .isFilter('deleted_at', null);

      // 添加筛选条件
      if (hskLevel != null) {
        query = query.eq('hsk_level', hskLevel);
      }
      if (topicTag != null) {
        query = query.eq('topic_tag', topicTag);
      }
      if (cultureTag != null) {
        query = query.eq('culture_tag', cultureTag);
      }

      // 执行排序和分页（不再赋值给 query）
      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => MediaContentModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ MediaService.getApprovedMedia 失败: $e');
      rethrow;
    }
  }

  /// 根据能力指标推荐媒体内容
  /// [indicatorIds] - 用户目标能力指标 ID 数组
  Future<List<MediaContentModel>> getRecommendedMedia({
    required List<int> indicatorIds,
    int? hskLevel,
    int limit = 10,
  }) async {
    try {
      // 构建过滤查询
      var query = _supabase
          .from('media_content')
          .select()
          .eq('review_status', 'approved')
          .isFilter('deleted_at', null)
          .overlaps('indicator_cats', indicatorIds); // 数组重叠查询

      if (hskLevel != null) {
        query = query.eq('hsk_level', hskLevel);
      }

      // 执行排序和限制（不再赋值给 query）
      final response = await query
          .order('view_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => MediaContentModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ MediaService.getRecommendedMedia 失败: $e');
      rethrow;
    }
  }

  /// 获取单个媒体内容详情
  Future<MediaContentModel?> getMediaById(int id) async {
    try {
      final response = await _supabase
          .from('media_content')
          .select()
          .eq('id', id)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) return null;
      return MediaContentModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ MediaService.getMediaById 失败: $e');
      rethrow;
    }
  }

  /// 搜索媒体内容（标题、描述）
  Future<List<MediaContentModel>> searchMedia(
    String keyword, {
    int limit = 20,
  }) async {
    try {
      final response = await _supabase
          .from('media_content')
          .select()
          .or('title.ilike.%$keyword%,description.ilike.%$keyword%')
          .eq('review_status', 'approved')
          .isFilter('deleted_at', null)
          .order('view_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => MediaContentModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ MediaService.searchMedia 失败: $e');
      rethrow;
    }
  }

  /// 获取热门播客（按观看次数排序）
  Future<List<MediaContentModel>> getPopularMedia({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('media_content')
          .select()
          .eq('review_status', 'approved')
          .isFilter('deleted_at', null)
          .order('view_count', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => MediaContentModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ MediaService.getPopularMedia 失败: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 创建/上传操作
  // ============================================================================

  /// 创建新的媒体内容
  Future<MediaContentModel> createMedia({
    required String title,
    String? description,
    required String contentType,
    required String sourceType,
    required String mediaUrl,
    String? externalId,
    int? durationSeconds,
    int? hskLevel,
    String? topicTag,
    String? cultureTag,
    List<int>? indicatorCats,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      final data = {
        'title': title,
        'description': description,
        'content_type': contentType,
        'source_type': sourceType,
        'media_url': mediaUrl,
        'external_id': externalId,
        'duration_seconds': durationSeconds,
        'hsk_level': hskLevel,
        'topic_tag': topicTag,
        'culture_tag': cultureTag,
        'indicator_cats': indicatorCats,
        'uploaded_by': userId,
        'processing_status': 'pending',
        'review_status': 'pending', // UGC 内容需要审核
      };

      final response = await _supabase
          .from('media_content')
          .insert(data)
          .select()
          .single();

      debugPrint('✅ 媒体内容创建成功: ${response['id']}');
      return MediaContentModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ MediaService.createMedia 失败: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 更新操作
  // ============================================================================

  /// 更新媒体内容的字幕数据
  Future<void> updateTranscript(int mediaId, TranscriptData transcript) async {
    try {
      await _supabase
          .from('media_content')
          .update({
            'transcript': transcript.toJson(),
            'processing_status': 'completed',
            'processed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', mediaId);

      debugPrint('✅ 字幕更新成功: $mediaId');
    } catch (e) {
      debugPrint('❌ MediaService.updateTranscript 失败: $e');
      rethrow;
    }
  }

  /// 增加观看次数
  Future<void> incrementViewCount(int mediaId) async {
    try {
      await _supabase.rpc(
        'increment_media_view_count',
        params: {'media_uuid': mediaId},
      );
      debugPrint('✅ 观看次数 +1: $mediaId');
    } catch (e) {
      debugPrint('❌ MediaService.incrementViewCount 失败: $e');
      // 不抛出异常，统计失败不影响主流程
    }
  }

  /// 增加点赞次数
  Future<void> incrementLikeCount(int mediaId) async {
    try {
      await _supabase.rpc(
        'increment_media_like_count',
        params: {'media_uuid': mediaId},
      );
      debugPrint('✅ 点赞次数 +1: $mediaId');
    } catch (e) {
      debugPrint('❌ MediaService.incrementLikeCount 失败: $e');
    }
  }

  /// 更新收藏次数（+1 或 -1）
  Future<void> updateBookmarkCount(int mediaId, bool isBookmarked) async {
    try {
      final increment = isBookmarked ? 1 : -1;
      await _supabase.rpc(
        'increment_media_bookmark_count',
        params: {'media_uuid': mediaId, 'increment_value': increment},
      );
      debugPrint('✅ 收藏次数更新: $mediaId');
    } catch (e) {
      debugPrint('❌ MediaService.updateBookmarkCount 失败: $e');
    }
  }

  // ============================================================================
  // 删除操作
  // ============================================================================

  /// 软删除媒体内容
  Future<void> deleteMedia(int mediaId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      // 检查权限：只能删除自己上传的内容
      final media = await getMediaById(mediaId);
      if (media?.uploadedBy != userId) {
        throw Exception('无权限删除此内容');
      }

      await _supabase
          .from('media_content')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', mediaId);

      debugPrint('✅ 媒体内容已删除: $mediaId');
    } catch (e) {
      debugPrint('❌ MediaService.deleteMedia 失败: $e');
      rethrow;
    }
  }
}
