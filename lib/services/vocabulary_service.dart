import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/user_vocabulary_model.dart';
import 'package:flutter/foundation.dart';

/// 用户生词本服务类
/// 负责生词的添加、查询、复习等操作
class VocabularyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================================
  // 查询操作
  // ============================================================================

  /// 获取用户所有生词
  Future<List<UserVocabularyModel>> getAllVocabulary() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_vocabulary')
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserVocabularyModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ VocabularyService.getAllVocabulary 失败: $e');
      rethrow;
    }
  }

  /// 获取待复习的生词
  Future<List<UserVocabularyModel>> getDueForReview() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final now = DateTime.now().toIso8601String();
      final response = await _supabase
          .from('user_vocabulary')
          .select()
          .eq('user_id', userId)
          .isFilter('deleted_at', null)
          .lte('next_review_at', now)
          .order('next_review_at', ascending: true);

      return (response as List)
          .map((json) => UserVocabularyModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ VocabularyService.getDueForReview 失败: $e');
      rethrow;
    }
  }

  /// 获取重点标记的生词
  Future<List<UserVocabularyModel>> getStarredVocabulary() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_vocabulary')
          .select()
          .eq('user_id', userId)
          .eq('is_starred', true)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserVocabularyModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ VocabularyService.getStarredVocabulary 失败: $e');
      rethrow;
    }
  }

  /// 根据来源类型获取生词
  Future<List<UserVocabularyModel>> getVocabularyBySource(
    String sourceType,
  ) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_vocabulary')
          .select()
          .eq('user_id', userId)
          .eq('source_type', sourceType)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserVocabularyModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ VocabularyService.getVocabularyBySource 失败: $e');
      rethrow;
    }
  }

  /// 从特定播客添加的生词
  Future<List<UserVocabularyModel>> getVocabularyFromMedia(int mediaId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return [];

      final response = await _supabase
          .from('user_vocabulary')
          .select()
          .eq('user_id', userId)
          .eq('source_type', 'media')
          .eq('source_media_id', mediaId)
          .isFilter('deleted_at', null)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => UserVocabularyModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('❌ VocabularyService.getVocabularyFromMedia 失败: $e');
      rethrow;
    }
  }

  /// 检查词汇是否已存在
  Future<UserVocabularyModel?> checkWordExists(String word) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabase
          .from('user_vocabulary')
          .select()
          .eq('user_id', userId)
          .eq('word', word)
          .isFilter('deleted_at', null)
          .maybeSingle();

      if (response == null) return null;
      return UserVocabularyModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ VocabularyService.checkWordExists 失败: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 创建/添加操作
  // ============================================================================

  /// 添加生词到生词本
  Future<UserVocabularyModel> addVocabulary({
    required String word,
    String? pinyin,
    String? definition,
    String? exampleSentence,
    String? exampleTranslation,
    required String sourceType, // 'media' | 'practice' | 'manual'
    int? sourceMediaId,
    int? sourcePracticeId,
    String? sourceContext,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      // 检查是否已存在
      final existing = await checkWordExists(word);
      if (existing != null) {
        debugPrint('⚠️ 词汇已存在: $word');
        return existing;
      }

      final data = {
        'user_id': userId,
        'word': word,
        'pinyin': pinyin,
        'definition': definition,
        'example_sentence': exampleSentence,
        'example_translation': exampleTranslation,
        'source_type': sourceType,
        'source_media_id': sourceMediaId,
        'source_practice_id': sourcePracticeId,
        'source_context': sourceContext,
        'next_review_at': DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String(),
      };

      final response = await _supabase
          .from('user_vocabulary')
          .insert(data)
          .select()
          .single();

      debugPrint('✅ 生词已添加: $word');
      return UserVocabularyModel.fromJson(response);
    } catch (e) {
      debugPrint('❌ VocabularyService.addVocabulary 失败: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 更新操作
  // ============================================================================

  /// 记录复习（更新掌握程度和下次复习时间）
  Future<void> recordReview(int vocabularyId, {required bool correct}) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      // 获取当前记录
      final response = await _supabase
          .from('user_vocabulary')
          .select()
          .eq('id', vocabularyId)
          .eq('user_id', userId)
          .single();

      final vocab = UserVocabularyModel.fromJson(response);

      // 调用模型的复习方法
      vocab.recordReview(correct: correct);

      // 更新数据库
      await _supabase
          .from('user_vocabulary')
          .update({
            'review_count': vocab.reviewCount,
            'last_reviewed_at': vocab.lastReviewedAt?.toIso8601String(),
            'next_review_at': vocab.nextReviewAt?.toIso8601String(),
            'mastery_level': vocab.masteryLevel,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vocabularyId);

      debugPrint('✅ 复习记录已更新: $vocabularyId, 正确: $correct');
    } catch (e) {
      debugPrint('❌ VocabularyService.recordReview 失败: $e');
      rethrow;
    }
  }

  /// 切换重点标记
  Future<bool> toggleStar(int vocabularyId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('用户未登录');
      }

      // 获取当前状态
      final response = await _supabase
          .from('user_vocabulary')
          .select()
          .eq('id', vocabularyId)
          .eq('user_id', userId)
          .single();

      final isStarred = response['is_starred'] as bool;
      final newState = !isStarred;

      await _supabase
          .from('user_vocabulary')
          .update({
            'is_starred': newState,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vocabularyId);

      debugPrint('✅ 重点标记已更新: $vocabularyId -> $newState');
      return newState;
    } catch (e) {
      debugPrint('❌ VocabularyService.toggleStar 失败: $e');
      rethrow;
    }
  }

  /// 更新笔记
  Future<void> updateNotes(int vocabularyId, String notes) async {
    try {
      await _supabase
          .from('user_vocabulary')
          .update({
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vocabularyId);

      debugPrint('✅ 笔记已更新: $vocabularyId');
    } catch (e) {
      debugPrint('❌ VocabularyService.updateNotes 失败: $e');
      rethrow;
    }
  }

  // ============================================================================
  // 删除操作
  // ============================================================================

  /// 删除生词（软删除）
  Future<void> deleteVocabulary(int vocabularyId) async {
    try {
      await _supabase
          .from('user_vocabulary')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .eq('id', vocabularyId);

      debugPrint('✅ 生词已删除: $vocabularyId');
    } catch (e) {
      debugPrint('❌ VocabularyService.deleteVocabulary 失败: $e');
      rethrow;
    }
  }

  /// 批量删除生词
  Future<void> batchDeleteVocabulary(List<int> vocabularyIds) async {
    try {
      await _supabase
          .from('user_vocabulary')
          .update({'deleted_at': DateTime.now().toIso8601String()})
          .inFilter('id', vocabularyIds);

      debugPrint('✅ 批量删除生词成功: ${vocabularyIds.length} 个');
    } catch (e) {
      debugPrint('❌ VocabularyService.batchDeleteVocabulary 失败: $e');
      rethrow;
    }
  }
}
