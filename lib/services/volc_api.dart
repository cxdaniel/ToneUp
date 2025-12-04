import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VolcTTS {
  /// 通过edge function方式调用
  /// 返回合成的音频数据（Uint8List）或可播放的URL（String），失败返回null
  Future<Uint8List?> synthesizeEF({
    // 擎苍:'zh_male_qingcang_mars_bigtts',
    // Tina老师:'zh_female_yingyujiaoyu_mars_bigtts',
    // 磁性解说男声/Morgan:'zh_male_jieshuonansheng_mars_bigtts'
    String voiceType = 'zh_male_jieshuonansheng_mars_bigtts',
    String encoding = "mp3",
    int compressionRate = 1,
    int rate = 24000,
    double speedRatio = 1.0,
    double volumeRatio = 1.0,
    double pitchRatio = 1.0,
    String emotion = "vocal-fry", //vocal-fry, magnetic, radio, ASMR
    String language = "cn",
    // request对象参数
    required String text,
    String textType = "plain",
    String operation = "query",
    String silenceDuration = "125",
    String withFrontend = "1",
    String frontendType = "unitTson",
    String pureEnglishOpt = "1",
    Map<String, dynamic>? extraParam,
  }) async {
    final User user = Supabase.instance.client.auth.currentUser!;
    final body = {
      "user": {"uid": user.id},
      "audio": {
        "voice_type": voiceType,
        //音色类型 https://www.volcengine.com/docs/6561/97465#%E5%A4%9A%E6%83%85%E6%84%9F-%E9%A3%8E%E6%A0%BC-%E8%AF%AD%E8%A8%80%E9%85%8D%E7%BD%AE%E4%BF%A1%E6%81%AF%E5%8F%82%E8%80%83
        "encoding": encoding, //音频编码格式
        "compression_rate": compressionRate, //opus格式时编码压缩比,[1, 20]，默认为 1
        "rate": rate, //音频采样率,默认为 24000，可选8000，16000
        "speed_ratio": speedRatio, //语速,[0.2,3]，默认为1，通常保留一位小数即可
        "volume_ratio": volumeRatio, //音量,[0.1, 3]，默认为1，通常保留一位小数
        "pitch_ratio": pitchRatio, //音高,[0.1, 3]，默认为1
        "emotion": emotion, //情感/风格
        "language": language, //语言类型
      },
      "request": {
        "reqid": DateTime.now().millisecondsSinceEpoch.toString(), // 简单生成唯一ID
        "text": text,
        "text_type": textType, //文本类型,plain / ssml
        "operation": operation, //query（非流式，http只能query
        "silence_duration": silenceDuration, //句尾静音时长,单位为ms，默认为125
        "with_frontend": withFrontend, //时间戳相关
        "frontend_type": frontendType,
        "pure_english_opt": pureEnglishOpt,
        if (extraParam != null) "extra_param": jsonEncode(extraParam),
      },
    };
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.functions.invoke(
        "tts_proxy",
        body: jsonEncode(body),
      );
      if (response.status == 200) {
        // 1. 将响应字节转为字符串，解析JSON
        final jsonData = jsonDecode(response.data) as Map<String, dynamic>;
        // 2. 验证请求成功（文档中code=3000且message=Success）
        if (jsonData["code"] == 3000 && jsonData["message"] == "Success") {
          // 3. 提取Base64编码的音频数据（文档中存放在data字段）
          final audioBase64 = jsonData["data"] as String?;
          if (audioBase64 != null && audioBase64.isNotEmpty) {
            // 4. Base64解码为二进制音频（Uint8List）
            return base64Decode(audioBase64);
          } else {
            debugPrint("响应中未找到有效的音频数据（data字段为空）");
          }
        } else {
          debugPrint("接口调用失败：jsonData=$jsonData");
        }
      } else {
        final errorMsg = jsonDecode(
          utf8.decode(response.data as List<int>),
        )["message"];
        debugPrint("请求失败（${response.status}）: $errorMsg");
      }
      return null;
    } catch (e) {
      debugPrint("请求错误: $e");
      return null;
    }
  }

  final FlutterTts _flutterTts = FlutterTts();
  FlutterTts get flutterTTS => _flutterTts;

  /// 🔹 新增：本地 TTS 方案（使用系统语音）
  /// 仅返回播放控制，不返回音频数据
  Future<void> speakLocal({
    required String text,
    String language = 'zh-CN',
    double pitch = 0.9,
    double rate = 0.5,
    double volume = 1.0,
  }) async {
    try {
      List<dynamic> voices = await _flutterTts.getVoices;
      for (var voice in voices) {
        if (voice is Map && voice['gender'] == 'male') {
          final tv = voice.map((k, v) => MapEntry(k.toString(), v.toString()));
          await _flutterTts.setVoice(tv);
          break;
        }
      }
      await _flutterTts.setLanguage(language);
      await _flutterTts.setPitch(pitch);
      await _flutterTts.setSpeechRate(rate);
      await _flutterTts.setVolume(volume);
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint("⚠️ 本地TTS错误: $e");
    }
  }

  /// 🔹 停止本地播放
  Future<void> stopLocal() async {
    await _flutterTts.stop();
  }
}
