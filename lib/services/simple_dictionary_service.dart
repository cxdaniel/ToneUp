import 'package:flutter/foundation.dart';
import 'package:pinyin/pinyin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/word_detail_model.dart';
import 'package:toneup_app/services/dictionary_cache_service.dart';
import 'package:toneup_app/services/lru_cache.dart';
import 'package:toneup_app/services/utils.dart';

/// 四级词典服务（扣子AI工作流版 - 优化架构）
/// L1: LRU内存缓存 (200词上限，Web/移动端通用)
/// L2: SQLite本地缓存 (移动端持久化，Web端IndexedDB)
/// L3: Supabase云端数据库 + Edge Function (查询不到时自动调用Coze工作流并保存)
/// L4: 拼音降级 (最终兜底)
///
/// 架构优化：Edge Function内部集成Coze调用和数据保存，客户端只需查询L3
class SimpleDictionaryService {
  static final SimpleDictionaryService _instance =
      SimpleDictionaryService._internal();
  factory SimpleDictionaryService() => _instance;
  SimpleDictionaryService._internal();

  // L1: LRU内存缓存 (限制200词，约100KB内存)
  final _memoryCache = LRUCache<String, WordDetailModel>(maxSize: 200);

  // L2: SQLite缓存服务
  final _sqliteCache = DictionaryCacheService();

  /// 查询词语详情（四级查询）
  /// [word] - 要查询的汉字或外语词语
  /// [language] - 目标语言代码 (en, zh, ja, ko等)
  /// [contextTranslation] - 上下文翻译（备选）
  Future<WordDetailModel> getWordDetail({
    required String word,
    required String language,
    String? contextTranslation,
  }) async {
    final cacheKey = '${word}_$language';

    // ===== L1: LRU内存缓存 =====
    final cachedInMemory = _memoryCache.get(cacheKey);
    if (cachedInMemory != null) {
      debugPrint('✅ L1命中 (LRU内存): $word ($language)');
      return cachedInMemory;
    }

    // ===== L2: SQLite本地缓存 =====
    final cachedWord = await _sqliteCache.getWord(word, language);
    if (cachedWord != null) {
      debugPrint('✅ L2命中 (SQLite): $word ($language)');
      _memoryCache.put(cacheKey, cachedWord);
      return cachedWord;
    }

    // ===== L3: Supabase + Edge Function (自动调用Coze并保存) =====
    final supabaseWord = await _queryOrGenerateFromSupabase(
      word,
      language,
      contextTranslation,
    );
    if (supabaseWord != null) {
      debugPrint('✅ L3命中 (Supabase/Coze): $word ($language)');
      // 保存到L2缓存
      await _sqliteCache.saveWord(supabaseWord, language);
      _memoryCache.put(cacheKey, supabaseWord);
      return supabaseWord;
    }

    // ===== L4: 最终降级 - 仅返回拼音 =====
    debugPrint('⚠️ 所有查询失败，返回基础信息: $word');
    final fallbackWord = WordDetailModel(
      word: word,
      pinyin: AppUtils.isChinese(word)
          ? PinyinHelper.getPinyin(word, format: PinyinFormat.WITH_TONE_MARK)
          : '',
      summary: contextTranslation ?? '(暂无释义)',
      entries: [],
    );

    // L4降级也缓存到L1（避免重复计算拼音）
    _memoryCache.put(cacheKey, fallbackWord);
    return fallbackWord;
  }

  /// 从Supabase查询或通过Edge Function生成词条
  /// Edge Function会自动调用Coze工作流并保存到数据库
  Future<WordDetailModel?> _queryOrGenerateFromSupabase(
    String word,
    String language,
    String? contextTranslation,
  ) async {
    try {
      // 1. 先查询数据库是否已有
      final response = await Supabase.instance.client
          .from('dictionary')
          .select('word, hsk_level, translations')
          .eq('word', word)
          .maybeSingle();

      if (response != null) {
        final translations = response['translations'] as Map<String, dynamic>?;
        if (translations != null && translations.containsKey(language)) {
          final langData = translations[language] as Map<String, dynamic>;

          // 解析entries
          final entriesData = langData['entries'] as List?;
          final entries =
              entriesData
                  ?.map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];

          // 从第一个entry中提取拼音（Coze返回的pinyin在entry中）
          String pinyin = '';
          if (entries.isNotEmpty && entries[0].pinyin.isNotEmpty) {
            pinyin = entries[0].pinyin;
          } else {
            // 兜底方案：使用pinyin库生成
            pinyin = PinyinHelper.getPinyin(
              word,
              format: PinyinFormat.WITH_TONE_MARK,
            );
          }

          debugPrint('📖 从数据库查到: $word ($language)');
          return WordDetailModel(
            word: response['word'] as String,
            pinyin: pinyin,
            summary: langData['summary'] as String?,
            entries: entries,
            hskLevel: response['hsk_level'] as int?,
          );
        }
      }

      // 2. 数据库没有，调用Edge Function（自动调用Coze并保存）
      debugPrint('🚀 调用Edge Function生成: $word → $language');
      final functionResponse = await Supabase.instance.client.functions.invoke(
        'translate-word',
        body: {
          'word': word,
          'lang': language, // 注意：参数名是 lang 不是 target_language
        },
      );

      if (functionResponse.data == null) {
        debugPrint('❌ Edge Function返回空数据');
        return null;
      }

      final data = functionResponse.data as Map<String, dynamic>;

      // 解析Edge Function返回的词条
      final entriesData = data['entries'] as List?;
      final entries =
          entriesData
              ?.map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      final wordDetail = WordDetailModel(
        word: word,
        pinyin: data['pinyin'] as String? ?? '',
        summary: data['summary'] as String?,
        entries: entries,
        hskLevel: data['hsk_level'] as int?,
      );

      // 补充拼音（如果Edge Function未生成）
      if (wordDetail.pinyin.isEmpty && AppUtils.isChinese(word)) {
        return WordDetailModel(
          word: wordDetail.word,
          pinyin: PinyinHelper.getPinyin(
            word,
            format: PinyinFormat.WITH_TONE_MARK,
          ),
          summary: wordDetail.summary,
          entries: wordDetail.entries,
          hskLevel: wordDetail.hskLevel,
        );
      }

      return wordDetail;
    } catch (e) {
      debugPrint('❌ L3查询/生成失败: $e');
      return null;
    }
  }

  /// 清空LRU内存缓存
  void clearMemoryCache() {
    _memoryCache.clear();
    debugPrint('✅ LRU内存缓存已清空');
  }

  /// 清空所有缓存（用于测试API）
  /// [clearSupabase] - 是否同时清空Supabase云端缓存（默认false）
  Future<void> clearAllCache({bool clearSupabase = false}) async {
    // 清空L1 LRU内存缓存
    _memoryCache.clear();
    debugPrint('✅ L1缓存已清空 (LRU内存)');

    // 清空L2 SQLite缓存
    await _sqliteCache.clearAllCache();
    debugPrint('✅ L2缓存已清空 (SQLite)');

    // 可选：清空L3 Supabase缓存
    if (clearSupabase) {
      try {
        await Supabase.instance.client
            .from('dictionary')
            .delete()
            .neq('word', '');
        debugPrint('✅ L3缓存已清空 (Supabase)');
      } catch (e) {
        debugPrint('❌ Supabase缓存清理失败: $e');
      }
    }

    debugPrint('🎯 所有本地缓存已清空，下次查询将使用扣子AI词典工作流');
  }

  /// 获取缓存统计
  Future<Map<String, dynamic>> getCacheStats() async {
    final sqliteStats = await _sqliteCache.getCacheStats();
    return {'lru': _memoryCache.getStats(), 'sqlite': sqliteStats};
  }

  /// 测试Edge Function词典是否正常工作
  /// [testWord] - 测试词语（默认"你好"）
  /// [language] - 测试语言（默认"en"）
  /// 返回测试结果和查询来源
  Future<Map<String, dynamic>> testApiDictionary({
    String testWord = '你好',
    String language = 'en',
  }) async {
    debugPrint('\n🧪 ===== 开始Edge Function词典测试 =====');
    debugPrint('测试词语: $testWord → $language');

    // 清空缓存确保查询Edge Function
    await clearAllCache();
    debugPrint('✅ 已清空所有缓存');

    try {
      // 直接调用Edge Function测试
      final result = await getWordDetail(word: testWord, language: language);

      debugPrint('✅ 测试成功!');
      debugPrint('📖 词语: ${result.word}');
      debugPrint('📌 拼音: ${result.pinyin}');
      debugPrint('📝 释义: ${result.summary}');
      debugPrint('📚 词条数: ${result.entries.length}');
      if (result.hskLevel != null) {
        debugPrint('🎓 HSK等级: ${result.hskLevel}');
      }

      return {
        'success': true,
        'word': result.word,
        'pinyin': result.pinyin,
        'summary': result.summary,
        'entries': result.entries.map((e) => e.toJson()).toList(),
        'entries_count': result.entries.length,
        'hsk_level': result.hskLevel,
      };
    } catch (e) {
      debugPrint('❌ 测试失败: $e');
      return {
        'success': false,
        'error': e.toString(),
        'suggestion': '请检查Edge Function "translate-word" 是否已部署并配置正确',
      };
    }
  }
}
