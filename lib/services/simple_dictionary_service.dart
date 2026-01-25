import 'package:flutter/foundation.dart';
import 'package:pinyin/pinyin.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:toneup_app/models/word_detail_model.dart';
import 'package:toneup_app/services/dictionary_cache_service.dart';
import 'package:toneup_app/services/lru_cache.dart';
import 'package:toneup_app/services/baidu_dict_service.dart';
import 'package:toneup_app/services/utils.dart';

/// 五级词典服务（百度词典版API）
/// L1: LRU内存缓存 (200词上限，Web/移动端通用)
/// L2: SQLite本地缓存 (移动端持久化，Web端IndexedDB)
/// L3: Supabase云端数据库 (跨设备同步)
/// L4: 百度词典版API (仅中英互查，其他语种降级)
/// L5: 拼音降级 (最终兜底)
class SimpleDictionaryService {
  static final SimpleDictionaryService _instance =
      SimpleDictionaryService._internal();
  factory SimpleDictionaryService() => _instance;
  SimpleDictionaryService._internal();

  // L1: LRU内存缓存 (限制200词，约100KB内存)
  final _memoryCache = LRUCache<String, WordDetailModel>(maxSize: 200);

  // L2: SQLite缓存服务
  final _sqliteCache = DictionaryCacheService();

  // L4: 百度词典版API服务 (仅中英互查)
  final _baiduDict = BaiduDictService();

  /// 查询词语详情（五级查询）
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

    // ===== L3: Supabase数据库查询 =====
    final supabaseWord = await _queryFromSupabase(word, language);
    if (supabaseWord != null) {
      debugPrint('✅ L3命中 (Supabase): $word ($language)');
      // 保存到L2缓存
      await _sqliteCache.saveWord(supabaseWord, language);
      _memoryCache.put(cacheKey, supabaseWord);
      return supabaseWord;
    }

    // ===== L4: 百度词典版API查询 (仅中英互查) =====
    if (_baiduDict.isConfigured && _isSupportedByBaiduDict(language)) {
      WordDetailModel? apiWord;

      // 带重试的API调用 (处理QPS限流)
      for (var retry = 0; retry < 3; retry++) {
        if (retry > 0) {
          debugPrint('⏳ 第${retry + 1}次重试 (等待${200 * retry}ms)...');
          await Future.delayed(Duration(milliseconds: 200 * retry));
        }

        apiWord = await _baiduDict.translate(
          word: word,
          from: 'zh',
          to: language,
        );

        if (apiWord != null) break; // 成功则退出重试
      }

      if (apiWord != null) {
        debugPrint('✅ L4命中 (百度API): $word');

        // 补充拼音（API可能没有）
        if (apiWord.pinyin.isEmpty && AppUtils.isChinese(word)) {
          final wordWithPinyin = WordDetailModel(
            word: apiWord.word,
            pinyin: PinyinHelper.getPinyin(
              word,
              format: PinyinFormat.WITH_TONE_MARK,
            ),
            summary: apiWord.summary,
            entries: apiWord.entries,
            hskLevel: apiWord.hskLevel,
          );

          // 保存到L3、L2缓存
          await _saveToSupabase(wordWithPinyin, language);
          await _sqliteCache.saveWord(wordWithPinyin, language);
          _memoryCache.put(cacheKey, wordWithPinyin);
          return wordWithPinyin;
        }

        // 保存到L3、L2缓存
        await _saveToSupabase(apiWord, language);
        await _sqliteCache.saveWord(apiWord, language);
        _memoryCache.put(cacheKey, apiWord);
        return apiWord;
      }
    } else {
      if (!_baiduDict.isConfigured) {
        debugPrint('⚠️ 百度API未配置，跳过L4查询');
      } else {
        debugPrint('⚠️ 百度词典版仅支持中英互查，语种 $language 不支持，跳过L4');
      }
    }

    // ===== L5: 最终降级 - 仅返回拼音 =====
    debugPrint('⚠️ 所有查询失败，返回基础信息: $word');
    final fallbackWord = WordDetailModel(
      word: word,
      pinyin: AppUtils.isChinese(word)
          ? PinyinHelper.getPinyin(word, format: PinyinFormat.WITH_TONE_MARK)
          : '',
      summary: contextTranslation ?? '(暂无释义)',
      entries: [],
    );

    // L5降级也缓存到L1（避免重复计算拼音）
    _memoryCache.put(cacheKey, fallbackWord);
    return fallbackWord;
  }

  /// 检查语言是否被百度词典版支持 (仅中英互查)
  bool _isSupportedByBaiduDict(String language) {
    return language == 'en' || language == 'zh';
  }

  /// 从Supabase查询词条
  Future<WordDetailModel?> _queryFromSupabase(
    String word,
    String language,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from('dictionary')
          .select('word, pinyin, hsk_level, translations')
          .eq('word', word)
          .maybeSingle();

      if (response == null) return null;

      final translations = response['translations'] as Map<String, dynamic>?;
      if (translations == null || !translations.containsKey(language)) {
        return null;
      }

      final langData = translations[language] as Map<String, dynamic>;

      // 解析entries
      final entriesData = langData['entries'] as List?;
      final entries =
          entriesData
              ?.map((e) => WordEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];

      return WordDetailModel(
        word: response['word'] as String,
        pinyin: response['pinyin'] as String,
        summary: langData['summary'] as String?,
        entries: entries,
        hskLevel: response['hsk_level'] as int?,
      );
    } catch (e) {
      debugPrint('❌ Supabase查询失败: $e');
      return null;
    }
  }

  /// 保存词条到Supabase
  Future<void> _saveToSupabase(WordDetailModel word, String language) async {
    try {
      // 构建translations JSON
      final translationData = {
        language: {
          'summary': word.summary,
          'entries': word.entries.map((e) => e.toJson()).toList(),
        },
      };

      await Supabase.instance.client.from('dictionary').upsert({
        'word': word.word,
        'pinyin': word.pinyin,
        'hsk_level': word.hskLevel,
        'translations': translationData,
        'source': 'mdx',
      });

      debugPrint('✅ 词条已保存到Supabase: ${word.word}');
    } catch (e) {
      debugPrint('❌ 保存到Supabase失败: $e');
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

    debugPrint('🎯 所有本地缓存已清空，下次查询将使用百度词典版API');
  }

  /// 获取缓存统计
  Future<Map<String, dynamic>> getCacheStats() async {
    final sqliteStats = await _sqliteCache.getCacheStats();
    return {
      'lru': _memoryCache.getStats(),
      'sqlite': sqliteStats,
      'baidu_api': _baiduDict.getUsageStats(),
    };
  }

  /// 测试API词典是否正常工作
  /// [testWord] - 测试词语（默认"你好"）
  /// 返回测试结果和查询来源
  Future<Map<String, dynamic>> testApiDictionary({
    String testWord = '你好',
  }) async {
    debugPrint('\n🧪 ===== 开始API词典测试 =====');
    debugPrint('测试词语: $testWord');

    // 1. 检查API是否配置
    if (!_baiduDict.isConfigured) {
      return {
        'success': false,
        'error': '百度API未配置',
        'suggestion': '请在 BaiduDictService 中设置 API_KEY 和 SECRET_KEY',
      };
    }

    // 2. 清空缓存确保查询API
    await clearAllCache();

    // 3. 执行查询
    final startTime = DateTime.now();
    final result = await getWordDetail(word: testWord, language: 'en');
    final duration = DateTime.now().difference(startTime);

    // 4. 分析结果
    final testResult = {
      'success': result.summary != '(暂无释义)',
      'word': result.word,
      'pinyin': result.pinyin,
      'summary': result.summary,
      'entries_count': result.entries.length,
      'entries': result.entries.map((e) => e.toJson()).toList(),
      'query_time_ms': duration.inMilliseconds,
      'api_configured': _baiduDict.isConfigured,
    };

    if (testResult['success'] == true) {
      debugPrint('✅ API词典测试成功');
      debugPrint('查询耗时: ${duration.inMilliseconds}ms');
      debugPrint('结果: ${result.summary}');
    } else {
      debugPrint('❌ API词典测试失败');
      debugPrint('结果: ${result.summary}');
    }

    debugPrint('===== API词典测试完成 =====\n');
    return testResult;
  }
}
