import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:toneup_app/models/word_detail_model.dart';
import 'package:pinyin/pinyin.dart';

/// 多语言词典API服务
/// 主力：DeepL API (免费500,000字符/月，质量最高)
/// 降级：MyMemory API (免费14,000次/天，无需注册)
class DictionaryApiService {
  static final DictionaryApiService _instance =
      DictionaryApiService._internal();
  factory DictionaryApiService() => _instance;
  DictionaryApiService._internal();

  // DeepL API配置
  static const String _deepLApiKey = 'YOUR_DEEPL_API_KEY'; // TODO: 配置你的DeepL密钥
  static const String _deepLBaseUrl = 'https://api-free.deepl.com/v2';

  // MyMemory API配置（降级方案）
  static const String _myMemoryBaseUrl = 'https://api.mymemory.translated.net';

  /// 查询词语翻译
  /// [word] - 汉字词语
  /// [targetLang] - 目标语言代码 (en, ja, ko, es, fr, de等)
  Future<WordDetailModel?> translateWord(String word, String targetLang) async {
    try {
      debugPrint('🌐 调用API查询: $word → $targetLang');

      // 1. 获取拼音
      final pinyin = PinyinHelper.getPinyin(
        word,
        format: PinyinFormat.WITH_TONE_MARK,
      );

      // 2. 优先使用DeepL API（质量更高）
      String? translation;
      if (_deepLApiKey != 'YOUR_DEEPL_API_KEY' && _deepLApiKey.isNotEmpty) {
        translation = await _callDeepLApi(word, targetLang);
      }

      // 3. 降级到MyMemory（如果DeepL失败或未配置）
      translation ??= await _callMyMemoryApi(word, targetLang);

      if (translation == null) {
        debugPrint('⚠️ 所有API均未返回翻译');
        return null;
      }

      // 4. 构建词条
      return WordDetailModel(
        word: word,
        pinyin: pinyin,
        summary: translation,
        entries: [
          WordEntry(pos: 'n./v.', definitions: [translation], examples: []),
        ],
      );
    } catch (e) {
      debugPrint('❌ API查询失败: $e');
      return null;
    }
  }

  /// 调用 DeepL Translation API
  Future<String?> _callDeepLApi(String text, String targetLang) async {
    try {
      // DeepL语言代码映射
      final deeplLangCode = _mapToDeepLLangCode(targetLang);
      if (deeplLangCode == null) {
        debugPrint('⚠️ DeepL不支持语言: $targetLang');
        return null;
      }

      final url = Uri.parse('$_deepLBaseUrl/translate');
      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'DeepL-Auth-Key $_deepLApiKey',
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'text': text,
              'source_lang': 'ZH',
              'target_lang': deeplLangCode,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translations = data['translations'] as List?;

        if (translations != null && translations.isNotEmpty) {
          final translatedText = translations[0]['text'] as String?;
          if (translatedText != null && translatedText != text) {
            debugPrint('✅ DeepL翻译成功: $text → $translatedText');
            return translatedText;
          }
        }
      } else if (response.statusCode == 403) {
        debugPrint('❌ DeepL API密钥无效');
      } else if (response.statusCode == 456) {
        debugPrint('⚠️ DeepL配额已用完');
      }

      return null;
    } catch (e) {
      debugPrint('❌ DeepL API请求失败: $e');
      return null;
    }
  }

  /// 映射语言代码到DeepL格式
  String? _mapToDeepLLangCode(String lang) {
    const langMap = {
      'en': 'EN',
      'ja': 'JA',
      'ko': 'KO',
      'es': 'ES',
      'fr': 'FR',
      'de': 'DE',
      'pt': 'PT',
      'it': 'IT',
      'nl': 'NL',
      'pl': 'PL',
      'ru': 'RU',
    };
    return langMap[lang];
  }

  /// 调用 MyMemory Translation API（降级方案）
  Future<String?> _callMyMemoryApi(String text, String targetLang) async {
    try {
      // MyMemory API需要源语言和目标语言
      final sourceLang = 'zh'; // 中文
      final url = Uri.parse(
        '$_myMemoryBaseUrl/get?q=$text&langpair=$sourceLang|$targetLang',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // MyMemory返回格式: {"responseData": {"translatedText": "..."}}
        final translatedText = data['responseData']?['translatedText'];

        if (translatedText != null && translatedText != text) {
          return translatedText as String;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ MyMemory API请求失败: $e');
      return null;
    }
  }

  /// 批量查询词语（优化多个词同时查询）
  Future<Map<String, WordDetailModel>> batchTranslate(
    List<String> words,
    String targetLang,
  ) async {
    final results = <String, WordDetailModel>{};

    // 限制并发数为3，避免API限流
    const batchSize = 3;
    for (var i = 0; i < words.length; i += batchSize) {
      final batch = words.skip(i).take(batchSize).toList();

      final futures = batch.map((word) => translateWord(word, targetLang));
      final batchResults = await Future.wait(futures);

      for (var j = 0; j < batch.length; j++) {
        if (batchResults[j] != null) {
          results[batch[j]] = batchResults[j]!;
        }
      }

      // 避免API限流，每批次间隔100ms
      if (i + batchSize < words.length) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    return results;
  }

  /// 检查API可用性
  Future<bool> checkApiAvailability() async {
    try {
      // 优先检查DeepL
      if (_deepLApiKey != 'YOUR_DEEPL_API_KEY' && _deepLApiKey.isNotEmpty) {
        final url = Uri.parse('$_deepLBaseUrl/usage');
        final response = await http
            .get(
              url,
              headers: {'Authorization': 'DeepL-Auth-Key $_deepLApiKey'},
            )
            .timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final characterCount = data['character_count'] as int?;
          final characterLimit = data['character_limit'] as int?;
          debugPrint('✅ DeepL可用: $characterCount / $characterLimit 字符已使用');
          return true;
        }
      }

      // 降级到MyMemory
      final url = Uri.parse('$_myMemoryBaseUrl/get?q=test&langpair=en|zh');
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ API不可用: $e');
      return false;
    }
  }
}
