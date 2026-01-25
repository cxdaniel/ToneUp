import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:toneup_app/models/word_detail_model.dart';

/// 有道智云API服务
///
/// 提供专业的汉英词典翻译服务
/// API文档: https://ai.youdao.com/DOCSIRMA/html/trans/api/wbfy/index.html
class YoudaoApiService {
  static final YoudaoApiService _instance = YoudaoApiService._internal();
  factory YoudaoApiService() => _instance;
  YoudaoApiService._internal();

  // API配置 - 需要在有道智云控制台获取
  static const String _appKey = '1c289b56f5e6f8b0'; // TODO: 替换为实际APP KEY
  static const String _appSecret =
      'lZLHyZmoqUAPI1xN5zi1nLRYJWt17wFj'; // TODO: 替换为实际APP SECRET
  static const String _apiUrl = 'https://openapi.youdao.com/api';

  /// 翻译查询
  ///
  /// [word] - 要翻译的汉字词语
  /// [from] - 源语言 (zh-CHS: 中文)
  /// [to] - 目标语言 (en: 英语, ja: 日语, ko: 韩语)
  Future<WordDetailModel?> translate({
    required String word,
    String from = 'zh-CHS',
    String to = 'en',
  }) async {
    try {
      // 生成签名
      final salt = DateTime.now().millisecondsSinceEpoch.toString();
      final curtime = (DateTime.now().millisecondsSinceEpoch ~/ 1000)
          .toString();
      final sign = _generateSign(word, salt, curtime);

      // 构建请求参数
      final params = {
        'q': word,
        'from': from,
        'to': to,
        'appKey': _appKey,
        'salt': salt,
        'sign': sign,
        'signType': 'v3',
        'curtime': curtime,
      };

      // 发送请求 (使用POST方式,符合官方文档推荐)
      final uri = Uri.parse(_apiUrl);
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: params,
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('API请求超时');
            },
          );

      if (response.statusCode != 200) {
        debugPrint('❌ 有道API请求失败: ${response.statusCode}');
        return null;
      }

      // 解析响应
      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      // errorCode为字符串类型,"0"表示成功
      final errorCode = data['errorCode']?.toString() ?? '';
      if (errorCode != '0') {
        debugPrint('❌ 有道API错误 [$errorCode]: ${_getErrorMessage(errorCode)}');
        return null;
      }

      return _parseYoudaoResponse(word, data, to);
    } catch (e) {
      debugPrint('❌ 有道API调用异常: $e');
      return null;
    }
  }

  /// 生成签名（有道API v3签名算法）
  String _generateSign(String query, String salt, String curtime) {
    final input = query.length <= 20
        ? query
        : query.substring(0, 10) +
              query.length.toString() +
              query.substring(query.length - 10);

    final signStr = '$_appKey$input$salt$curtime$_appSecret';
    return sha256.convert(utf8.encode(signStr)).toString();
  }

  /// 解析有道API响应
  WordDetailModel _parseYoudaoResponse(
    String word,
    Map<String, dynamic> data,
    String targetLang,
  ) {
    // 基础翻译
    final translation = (data['translation'] as List?)?.first as String? ?? '';

    // 词典详细信息（如果有）
    final basic = data['basic'] as Map<String, dynamic>?;
    final webDict = data['web'] as List?;

    // 解析词条
    final entries = <WordEntry>[];

    // 1. 基础释义
    if (basic != null) {
      final explains = basic['explains'] as List?;
      if (explains != null) {
        for (var explain in explains) {
          final parts = explain.toString().split('.');
          if (parts.length >= 2) {
            entries.add(
              WordEntry(
                pos: parts[0].trim(),
                definitions: [parts.sublist(1).join('.').trim()],
                examples: [],
              ),
            );
          } else {
            entries.add(
              WordEntry(
                pos: '',
                definitions: [explain.toString()],
                examples: [],
              ),
            );
          }
        }
      }

      // 2. 词形变化 (wfs - word forms)
      final wfs = basic['wfs'] as List?;
      if (wfs != null && wfs.isNotEmpty) {
        for (var wf in wfs) {
          final wfData = wf as Map<String, dynamic>;
          final wfInfo = wfData['wf'] as Map<String, dynamic>?;
          if (wfInfo != null) {
            entries.add(
              WordEntry(
                pos: wfInfo['name'] ?? '',
                definitions: [wfInfo['value'] ?? ''],
                examples: [],
              ),
            );
          }
        }
      }
    }

    // 3. 网络释义（补充）
    if (webDict != null && entries.isEmpty) {
      for (var item in webDict) {
        final webItem = item as Map<String, dynamic>;
        final key = webItem['key'] as String?;
        final values = (webItem['value'] as List?)?.cast<String>() ?? [];
        if (key != null && values.isNotEmpty) {
          entries.add(WordEntry(pos: 'web', definitions: values, examples: []));
        }
      }
    }

    // 拼音（如果有）
    String? pinyin = basic?['phonetic'] as String?;

    // 如果没有拼音，需要额外生成（使用pinyin库）
    if (pinyin == null || pinyin.isEmpty) {
      // 这个在SimpleDictionaryService中处理
    }

    return WordDetailModel(
      word: word,
      pinyin: pinyin ?? '',
      summary: translation.isNotEmpty
          ? translation
          : entries.firstOrNull?.definitions.firstOrNull,
      entries: entries.isNotEmpty
          ? entries
          : [
              WordEntry(pos: '', definitions: [translation], examples: []),
            ],
      hskLevel: null, // 有道API不提供HSK等级
    );
  }

  /// 批量翻译（优化性能）
  Future<Map<String, WordDetailModel?>> translateBatch(
    List<String> words, {
    String from = 'zh-CHS',
    String to = 'en',
  }) async {
    final results = <String, WordDetailModel?>{};

    // 有道API不支持批量，需要串行调用
    // 添加限流避免超出API配额
    for (var word in words) {
      results[word] = await translate(word: word, from: from, to: to);

      // 限流：每秒最多10次请求
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return results;
  }

  /// 获取错误码对应的中文说明
  String _getErrorMessage(String errorCode) {
    const errorMessages = {
      '101': '缺少必填参数',
      '102': '不支持的语言类型',
      '103': '翻译文本过长',
      '108': '应用ID无效',
      '110': '无相关服务的有效应用',
      '111': '开发者账号无效',
      '202': '签名检验失败',
      '206': '时间戳无效',
      '207': '重放请求',
      '401': '账户已欠费',
      '411': '访问频率受限',
    };
    return errorMessages[errorCode] ?? '未知错误($errorCode)';
  }

  /// 检查API配置是否有效
  bool get isConfigured {
    return _appKey != 'YOUR_YOUDAO_APP_KEY' &&
        _appSecret != 'YOUR_YOUDAO_APP_SECRET';
  }

  /// 获取API使用统计（需要额外实现）
  Map<String, dynamic> getUsageStats() {
    return {
      'configured': isConfigured,
      'api_url': _apiUrl,
      'app_key': _appKey.substring(0, 8) + '...',
    };
  }
}
