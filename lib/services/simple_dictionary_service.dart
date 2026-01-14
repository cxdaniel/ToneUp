import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:pinyin/pinyin.dart';
import 'package:toneup_app/models/word_detail_model.dart';
import 'package:toneup_app/services/utils.dart';

/// 简易词典服务
/// 提供基础的词语查询功能（拼音 + 翻译）
class SimpleDictionaryService {
  static final SimpleDictionaryService _instance =
      SimpleDictionaryService._internal();
  factory SimpleDictionaryService() => _instance;
  SimpleDictionaryService._internal() {
    _loadDictionary();
  }

  Map<String, dynamic> _dictionary = {};
  bool _isLoaded = false;

  /// 加载词典文件
  Future<void> _loadDictionary() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/dict/cedict_hsk.json',
      );
      _dictionary = jsonDecode(jsonString) as Map<String, dynamic>;
      _isLoaded = true;
      debugPrint('✅ CC-CEDICT 词典加载成功，共 ${_dictionary.length} 词条');
    } catch (e) {
      debugPrint('❌ 词典加载失败: $e');
      _isLoaded = false;
    }
  }

  /// 查询词语详情
  ///
  /// [word] - 要查询的汉字词语
  /// [contextTranslation] - 上下文的英文翻译（来自 segment.translation）
  /// [contextSentence] - 上下文的例句（来自 segment.text）
  WordDetailModel getWordDetail({
    required String word,
    String? contextTranslation,
    String? contextSentence,
  }) {
    String pinyin;
    String? translation;

    // 1. 尝试从词典查询
    if (_isLoaded && _dictionary.containsKey(word)) {
      final entry = _dictionary[word] as Map<String, dynamic>;
      pinyin = entry['pinyin'] as String? ?? '';
      final definitions = entry['definitions'] as List<dynamic>?;
      translation = definitions?.join('; ');
    } else {
      // 2. 词典中没有，使用拼音库生成拼音
      pinyin = AppUtils.isChinese(word)
          ? PinyinHelper.getPinyin(word, format: PinyinFormat.WITH_TONE_MARK)
          : '';
      // 3. 使用上下文翻译作为备选
      translation = contextTranslation;
    }

    return WordDetailModel(
      word: word,
      pinyin: pinyin,
      translation: translation,
      exampleSentence: contextSentence,
    );
  }
}
