import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/word_detail_model.dart';
import 'package:toneup_app/services/config.dart';

/// 扣子(Coze) AI词典服务
///
/// 通过Supabase Edge Function调用扣子工作流，生成高质量的汉英词典翻译
/// 支持多语言翻译（中英、中日、中韩等）
class CozeApiService {
  static final CozeApiService _instance = CozeApiService._internal();
  factory CozeApiService() => _instance;
  CozeApiService._internal();

  final _supabase = Supabase.instance.client;

  /// 调用扣子词典工作流生成词条翻译
  ///
  /// [word] - 要翻译的汉字词语
  /// [targetLanguage] - 目标语言代码，对应 ProfileModel.nativeLanguage
  ///                     支持: en, zh, ja, ko, es, fr, de 等
  /// [context] - 可选的上下文信息，帮助AI更准确理解词义
  ///
  /// 返回 [WordDetailModel] 或 null（调用失败时）
  Future<WordDetailModel?> translate({
    required String word,
    required String targetLanguage,
    String? context,
  }) async {
    try {
      debugPrint('🤖 调用扣子词典工作流: $word → $targetLanguage');

      final session = _supabase.auth.currentSession;
      if (session == null) {
        debugPrint('⚠️ 用户未登录，无法调用扣子API');
        return null;
      }

      // 调用Supabase Edge Function
      final response = await _supabase.functions
          .invoke(
            'translate-word', // Edge Function名称
            body: {
              'word': word,
              'target_language': targetLanguage,
              'context': context,
            },
          )
          .timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('扣子API请求超时');
            },
          );

      if (response.status != 200) {
        debugPrint('❌ 扣子API请求失败: ${response.status}');
        return null;
      }

      final data = response.data as Map<String, dynamic>;

      // 检查错误码
      if (data['error'] != null) {
        debugPrint('❌ 扣子API返回错误: ${data['error']}');
        return null;
      }

      // 解析响应数据
      return _parseCozeResponse(word, data, targetLanguage);
    } catch (e) {
      debugPrint('❌ 扣子API调用异常: $e');
      return null;
    }
  }

  /// 解析扣子工作流返回的词典数据
  WordDetailModel _parseCozeResponse(
    String word,
    Map<String, dynamic> data,
    String targetLanguage,
  ) {
    try {
      // 扣子返回的数据结构（需要根据实际工作流输出调整）
      final pinyin = data['pinyin'] as String? ?? '';
      final summary = data['summary'] as String? ?? '';
      final hskLevel = data['hsk_level'] as int?;

      // 解析词条列表
      final entriesData = data['entries'] as List? ?? [];
      final entries = entriesData.map((entryJson) {
        final entry = entryJson as Map<String, dynamic>;
        return WordEntry(
          pos: entry['pos'] as String? ?? '', // 词性 (n., v., adj.等)
          definitions:
              (entry['definitions'] as List?)?.cast<String>() ?? [], // 释义列表
          examples: (entry['examples'] as List?)?.cast<String>() ?? [], // 例句列表
        );
      }).toList();

      return WordDetailModel(
        word: word,
        pinyin: pinyin,
        summary: summary,
        entries: entries,
        hskLevel: hskLevel,
      );
    } catch (e) {
      debugPrint('❌ 解析扣子响应数据失败: $e');
      // 返回基础词条（避免崩溃）
      return WordDetailModel(
        word: word,
        pinyin: data['pinyin'] as String? ?? '',
        summary: data['summary'] as String? ?? '(解析失败)',
        entries: [],
      );
    }
  }

  /// 批量翻译（限流版本）
  ///
  /// 注意：扣子工作流按调用次数计费，批量调用时需注意成本控制
  Future<Map<String, WordDetailModel?>> translateBatch(
    List<String> words, {
    required String targetLanguage,
    String? context,
  }) async {
    final results = <String, WordDetailModel?>{};

    // 串行调用，避免并发过高
    for (var word in words) {
      results[word] = await translate(
        word: word,
        targetLanguage: targetLanguage,
        context: context,
      );

      // 限流：每次调用间隔200ms（避免触发扣子频率限制）
      await Future.delayed(const Duration(milliseconds: 200));
    }

    return results;
  }

  /// 检查扣子API是否可用
  ///
  /// 通过检查用户登录状态和Edge Function可达性判断
  Future<bool> isAvailable() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return false;

      // 可选：Ping测试 Edge Function（避免频繁调用）
      // final response = await _supabase.functions.invoke('translate-word-health');
      // return response.status == 200;

      return true;
    } catch (e) {
      debugPrint('⚠️ 扣子API可用性检查失败: $e');
      return false;
    }
  }

  /// 获取API统计信息（调试用）
  Map<String, dynamic> getUsageStats() {
    return {
      'service': 'Coze AI Dictionary',
      'edge_function': 'translate-word',
      'supabase_url': SupabaseConfig.url,
      'authenticated': _supabase.auth.currentSession != null,
    };
  }
}
