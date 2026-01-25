import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:toneup_app/models/word_detail_model.dart';

/// 百度翻译词典版API服务
///
/// 提供丰富的词典数据(例句/近义词/音标/词性等)
/// 仅支持中英互查,其他语种需使用百度大模型翻译API
/// API文档: https://ai.baidu.com/ai-doc/MT/nkqrzmbpc
class BaiduDictService {
  static final BaiduDictService _instance = BaiduDictService._internal();
  factory BaiduDictService() => _instance;
  BaiduDictService._internal();

  // API配置
  static const String _apiKey = 'qBw2Q6tQO601ZgJZ6kD4fjQ2';
  static const String _secretKey = 'RvkfjjkGmuhHBJM2ete5qiOZ1rvFxN6w';
  static const String _tokenUrl = 'https://aip.baidubce.com/oauth/2.0/token';
  static const String _apiUrl =
      'https://aip.baidubce.com/rpc/2.0/mt/texttrans-with-dict/v1';

  // Access Token 缓存 (有效期30天)
  String? _accessToken;
  DateTime? _tokenExpiry;

  /// 获取Access Token (带缓存)
  Future<String?> _getAccessToken() async {
    try {
      // 检查缓存是否有效
      if (_accessToken != null &&
          _tokenExpiry != null &&
          DateTime.now().isBefore(_tokenExpiry!)) {
        return _accessToken;
      }

      // 请求新Token
      final uri = Uri.parse(_tokenUrl).replace(
        queryParameters: {
          'grant_type': 'client_credentials',
          'client_id': _apiKey,
          'client_secret': _secretKey,
        },
      );

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('获取Token超时'),
          );

      if (response.statusCode != 200) {
        debugPrint('❌ 获取Token失败: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data.containsKey('error')) {
        debugPrint('❌ Token错误: ${data['error_description']}');
        return null;
      }

      _accessToken = data['access_token'] as String;
      final expiresIn = data['expires_in'] as int; // 秒数,通常为30天
      _tokenExpiry = DateTime.now().add(
        Duration(seconds: expiresIn - 3600), // 提前1小时刷新
      );

      debugPrint('✅ 百度Access Token获取成功, 有效期: ${expiresIn ~/ 86400}天');
      return _accessToken;
    } catch (e) {
      debugPrint('❌ 获取Token异常: $e');
      return null;
    }
  }

  /// 词典查询 (仅支持中英互查)
  Future<WordDetailModel?> translate({
    required String word,
    String from = 'zh',
    String to = 'en',
  }) async {
    try {
      // 仅支持中英互查
      if (!(from == 'zh' || from == 'en') || !(to == 'zh' || to == 'en')) {
        debugPrint('⚠️ 百度词典版仅支持中英互查');
        return null;
      }

      // 获取Access Token
      final token = await _getAccessToken();
      if (token == null) {
        debugPrint('❌ 无法获取Access Token');
        return null;
      }

      // 构建请求
      final uri = Uri.parse(
        _apiUrl,
      ).replace(queryParameters: {'access_token': token});
      final body = jsonEncode({'from': from, 'to': to, 'q': word});

      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json;charset=utf-8'},
            body: body,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('API请求超时'),
          );

      if (response.statusCode != 200) {
        debugPrint('❌ 百度API请求失败: ${response.statusCode}');
        return null;
      }

      // 解析响应
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      // 检查错误
      if (data.containsKey('error_code')) {
        final errorCode = data['error_code'] as int;
        final errorMsg = data['error_msg'] ?? '未知错误';
        final detailedMsg = _getErrorMessage(errorCode);
        debugPrint('❌ 百度API错误 [$errorCode]: $errorMsg');
        debugPrint('💡 详细说明: $detailedMsg');

        // 特殊处理QPS限流
        if (errorCode == 18 || errorCode == 54003) {
          debugPrint('⚠️ 建议: 等待100-200ms后重试，或在SimpleDictionaryService中增加缓存命中率');
        }

        return null;
      }

      return _parseBaiduResponse(word, data, from, to);
    } catch (e) {
      debugPrint('❌ 百度API调用异常: $e');
      return null;
    }
  }

  /// 解析百度词典版API响应
  WordDetailModel _parseBaiduResponse(
    String word,
    Map<String, dynamic> data,
    String from,
    String to,
  ) {
    try {
      // 根据用户提供的实际API返回: data['result']['trans_result']
      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) {
        debugPrint('⚠️ API响应缺少result字段');
        return _fallbackModel(word, '');
      }

      final transResult = result['trans_result'] as List?;
      if (transResult == null || transResult.isEmpty) {
        debugPrint('⚠️ API返回空结果');
        return _fallbackModel(word, '');
      }

      final firstResult = transResult.first as Map<String, dynamic>;
      final translation = firstResult['dst'] as String? ?? '';

      // 提取TTS语音URL
      final srcTts = firstResult['src_tts'] as String?;
      final dstTts = firstResult['dst_tts'] as String?;
      if (srcTts != null || dstTts != null) {
        debugPrint('🔊 TTS语音: src=$srcTts, dst=$dstTts');
      }

      // 解析词典数据
      final dictJson = firstResult['dict'] as String?;
      if (dictJson == null || dictJson.isEmpty) {
        debugPrint('⚠️ 无词典数据,仅返回翻译');
        return _fallbackModel(word, translation);
      }

      // 二次解析dict JSON字符串
      final dictData = jsonDecode(dictJson) as Map<String, dynamic>;
      return _parseDictData(word, translation, dictData, from);
    } catch (e) {
      debugPrint('❌ 响应解析失败: $e');
      return _fallbackModel(word, '');
    }
  }

  /// 解析词典数据 (根据实际API响应结构)
  WordDetailModel _parseDictData(
    String word,
    String translation,
    Map<String, dynamic> dictData,
    String from,
  ) {
    final entries = <WordEntry>[];
    String? pinyin;

    try {
      // dict数据结构: {lang: "0", word_result: {simple_means: {...}, synthesize_means: {...}, zdict: {...}, edict: ""}}
      final wordResult = dictData['word_result'] as Map<String, dynamic>?;
      if (wordResult == null) {
        debugPrint('⚠️ 无word_result字段');
        return _fallbackModel(word, translation);
      }

      // 1. 解析 simple_means (简明释义) - 在word_result下
      try {
        final simpleMeansRaw = wordResult['simple_means'];
        if (simpleMeansRaw is Map<String, dynamic>) {
          final simpleMeans = simpleMeansRaw;
          final symbols = simpleMeans['symbols'] as List?;
          if (symbols != null && symbols.isNotEmpty) {
            final symbol = symbols.first as Map<String, dynamic>;

            // 提取拼音 (中→英查询)
            if (from == 'zh') {
              pinyin = symbol['word_symbol'] as String?; // e.g. "zhuàng tài"
            }

            // 解析 parts[0].means[] (详细词条)
            final parts = symbol['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              try {
                final part = parts.first as Map<String, dynamic>;
                final means = part['means'] as List?;
                if (means != null) {
                  for (var meanItem in means) {
                    final meanMap = meanItem as Map<String, dynamic>;
                    final pos = meanMap['part'] as String? ?? '';
                    final defs =
                        (meanMap['means'] as List?)?.cast<String>() ?? [];

                    if (defs.isNotEmpty) {
                      entries.add(
                        WordEntry(
                          pos: pos.isEmpty ? 'n.' : pos,
                          definitions: defs,
                          examples: [],
                        ),
                      );
                    }
                  }
                }
              } catch (e) {
                // parts字段在英→中查询时可能为String，跳过
              }
            }

            // 兜底: 使用 word_means
            if (entries.isEmpty) {
              final wordMeans =
                  (simpleMeans['word_means'] as List?)?.cast<String>() ?? [];
              if (wordMeans.isNotEmpty) {
                entries.add(
                  WordEntry(pos: '', definitions: wordMeans, examples: []),
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ simple_means解析失败: $e');
      }

      // 2. 解析 synthesize_means (例句) - 在word_result下
      try {
        final synthesizeMeansRaw = wordResult['synthesize_means'];
        if (synthesizeMeansRaw is Map<String, dynamic> && entries.isNotEmpty) {
          final synthesizeMeans = synthesizeMeansRaw;
          final symbols = synthesizeMeans['symbols'] as List?;
          if (symbols != null && symbols.isNotEmpty) {
            final symbol = symbols.first as Map<String, dynamic>;
            final cys = symbol['cys'] as List?;
            if (cys != null && cys.isNotEmpty) {
              final cy = cys.first as Map<String, dynamic>;
              final cyMeans = cy['means'] as List?;
              if (cyMeans != null && cyMeans.isNotEmpty) {
                final meanItem = cyMeans.first as Map<String, dynamic>;
                final ljs = meanItem['ljs'] as List?;
                if (ljs != null) {
                  final examplesList = <String>[];
                  for (var lj in ljs.take(5)) {
                    final ljMap = lj as Map<String, dynamic>;
                    final en = ljMap['ls'] as String? ?? '';
                    final zh = ljMap['ly'] as String? ?? '';
                    if (en.isNotEmpty && zh.isNotEmpty) {
                      examplesList.add('$en / $zh');
                    }
                  }
                  // 将例句添加到第一个词条
                  if (examplesList.isNotEmpty) {
                    entries[0] = WordEntry(
                      pos: entries[0].pos,
                      definitions: entries[0].definitions,
                      examples: examplesList,
                    );
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ synthesize_means解析失败: $e');
      }

      // 3. 解析 zdict (中文词典详解) - 英→中查询时，在word_result下
      try {
        final zdictRaw = wordResult['zdict'];
        if (zdictRaw is Map<String, dynamic>) {
          final zdict = zdictRaw;
          final detail = zdict['detail'] as Map<String, dynamic>?;
          if (detail != null) {
            final means = detail['means'] as List?;
            if (means != null && means.isNotEmpty) {
              final meanItem = means.first as Map<String, dynamic>;
              final exp = meanItem['exp'] as List?;
              if (exp != null && exp.isNotEmpty) {
                final expItem = exp.first as Map<String, dynamic>;
                final des = expItem['des'] as List?;
                if (des != null) {
                  final zhDefinitions = <String>[];
                  for (var desItem in des) {
                    final desMap = desItem as Map<String, dynamic>;
                    final main = desMap['main'] as String? ?? '';
                    // 排除标签行 (如 "[state;condition;state of affairs]")
                    if (main.isNotEmpty &&
                        !main.contains('[') &&
                        !main.contains('(1)')) {
                      zhDefinitions.add(main);
                    }
                  }
                  if (zhDefinitions.isNotEmpty) {
                    entries.add(
                      WordEntry(
                        pos: '详解',
                        definitions: zhDefinitions,
                        examples: [],
                      ),
                    );
                  }
                }
              }
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ zdict解析失败: $e');
      }
    } catch (e) {
      debugPrint('❌ 词典数据解析异常: $e');
    }

    // 如果没有任何词条,返回基础翻译
    if (entries.isEmpty) {
      return _fallbackModel(word, translation);
    }

    return WordDetailModel(
      word: word,
      pinyin: pinyin ?? '',
      summary: translation,
      entries: entries,
    );
  }

  /// 兜底模型 (解析失败时返回)
  WordDetailModel _fallbackModel(String word, String translation) {
    return WordDetailModel(
      word: word,
      pinyin: '',
      summary: translation.isEmpty ? '(无翻译)' : translation,
      entries: translation.isEmpty
          ? []
          : [
              WordEntry(pos: '', definitions: [translation], examples: []),
            ],
    );
  }

  /// 批量翻译 (优化性能)
  Future<Map<String, WordDetailModel?>> translateBatch(
    List<String> words, {
    String from = 'zh',
    String to = 'en',
  }) async {
    final results = <String, WordDetailModel?>{};

    for (var word in words) {
      results[word] = await translate(word: word, from: from, to: to);
      await Future.delayed(const Duration(milliseconds: 100)); // QPS限流
    }

    return results;
  }

  /// 检查API配置是否有效
  bool get isConfigured {
    return _apiKey != 'YOUR_BAIDU_API_KEY' &&
        _secretKey != 'YOUR_BAIDU_SECRET_KEY';
  }

  /// 清除Token缓存
  void clearTokenCache() {
    _accessToken = null;
    _tokenExpiry = null;
    debugPrint('🔄 百度Token缓存已清除');
  }

  /// 获取API使用统计
  Map<String, dynamic> getUsageStats() {
    return {
      'configured': isConfigured,
      'api_url': _apiUrl,
      'token_cached': _accessToken != null,
      'token_expires': _tokenExpiry?.toIso8601String() ?? 'N/A',
      'supported_languages': ['zh', 'en'],
      'note': '仅支持中英互查,词典版提供丰富的例句/音标/词性数据',
    };
  }

  /// 获取错误信息
  String _getErrorMessage(int errorCode) {
    switch (errorCode) {
      case 18:
        return 'QPS限流: 请求速度过快，请稍后再试。免费版QPS为10次/秒，建议间隔100ms以上。';
      case 52001:
        return '请求超时，请重试';
      case 52002:
        return '系统错误，请稍后重试';
      case 52003:
        return '未授权用户';
      case 54000:
        return '必填参数为空';
      case 54001:
        return '签名错误';
      case 54003:
        return 'QPS限流: 超过访问频率';
      case 54004:
        return '账户余额不足';
      case 54005:
        return '长query请求频繁';
      case 58000:
        return 'IP地址非法';
      case 58001:
        return '译文语言方向不支持';
      case 90107:
        return '认证未通过或未生效';
      default:
        return '未知错误 ($errorCode)';
    }
  }
}
