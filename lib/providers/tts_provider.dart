import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:toneup_app/services/volc_api.dart';

enum TTSState { idle, loading, playing, completed, error }

class TTSProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final VolcTTS _volcTTS = VolcTTS();
  final Map<String, Uint8List> _memoryCache = {}; // ✅ L1 内存缓存
  TTSState _state = TTSState.idle;
  TTSState get state => _state;
  int _currentTaskId = 0;
  bool _disposed = false;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  @override
  void dispose() {
    _disposed = true;
    _audioPlayer.dispose();
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  void _setState(TTSState newState) {
    _state = newState;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  TTSProvider() {
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _setState(TTSState.completed);
      }
    });
    _volcTTS.flutterTTS.setCompletionHandler(() {
      _setState(TTSState.completed);
    });
    _volcTTS.flutterTTS.setCancelHandler(() {
      _setState(TTSState.completed);
    });
    _volcTTS.flutterTTS.setErrorHandler((e) {
      _setState(TTSState.error);
      debugPrint('Flutter_tts播放错误：$e');
    });
  }

  /// 🔹 生成唯一hash（区分不同语音类型）
  String _hashKey(String text, {String voiceType = 'default'}) {
    final raw = '$voiceType|$text';
    return md5.convert(utf8.encode(raw)).toString();
  }

  /// 🔹 获取缓存文件路径（L2）
  Future<File> _getCachedFile(String key) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/tts_$key.mp3');
  }

  /// 🔹 从本地加载缓存
  Future<Uint8List?> _loadFromFileCache(String key) async {
    if (kIsWeb) return null;
    final file = await _getCachedFile(key);
    if (await file.exists()) return await file.readAsBytes();
    return null;
  }

  /// 🔹 保存音频到缓存
  Future<void> _saveToFileCache(String key, Uint8List bytes) async {
    if (kIsWeb) return;
    final file = await _getCachedFile(key);
    await file.writeAsBytes(bytes, flush: true);
  }

  /// 🔹 获取音频：内存 → 文件 → 请求
  Future<Uint8List?> _getOrCreateAudio(
    String text, {
    String voiceType = 'zh_male_jieshuonansheng_mars_bigtts',
  }) async {
    final key = _hashKey(text, voiceType: voiceType);
    // L1 内存缓存
    if (_memoryCache.containsKey(key)) {
      return _memoryCache[key];
    }
    // L2 文件缓存
    if (!kIsWeb) {
      final fileData = await _loadFromFileCache(key);
      if (fileData != null) {
        _memoryCache[key] = fileData; // 同步到内存缓存
        return fileData;
      }
    }
    // L3 远程请求
    final result = await _volcTTS.synthesizeEF(text: text);
    if (result != null) {
      _memoryCache[key] = result;
      if (!kIsWeb) await _saveToFileCache(key, result);
      return result;
    }
    return null;
  }

  /// 🔹 播放语音
  Future<void> play(String text, {bool uselocal = false}) async {
    debugPrint('🎹 播放音频.local:$uselocal: "$text"');
    if (uselocal) {
      // 本地播放
      try {
        _setState(TTSState.loading);
        await _volcTTS.speakLocal(text: text);
        _setState(TTSState.playing);
      } catch (e) {
        _setState(TTSState.error);
      }
    } else {
      // 云端接口
      try {
        await _audioPlayer.stop();
        _setState(TTSState.loading);
        final int taskID = ++_currentTaskId;

        final audioData = await _getOrCreateAudio(text);
        if (audioData == null) {
          debugPrint("❌ TTS 合成失败");
          _setState(TTSState.error);
          return;
        }
        if (taskID != _currentTaskId) return;

        if (kIsWeb) {
          // Web 不支持本地文件缓存，因此仅使用内存缓存
          await _audioPlayer.setAudioSource(
            AudioSource.uri(
              Uri.dataFromBytes(audioData, mimeType: 'audio/mpeg'),
            ),
          );
        } else {
          // 移动端：可写入临时文件播放
          final tempDir = await getTemporaryDirectory();
          final path =
              '${tempDir.path}/tts_temp_${DateTime.now().millisecondsSinceEpoch}.mp3';
          final file = File(path);
          await file.writeAsBytes(audioData, flush: true);
          await _audioPlayer.setAudioSource(AudioSource.uri(Uri.file(path)));
        }

        _setState(TTSState.playing);
        await _audioPlayer.play();
      } catch (e) {
        debugPrint("TTS 播放错误: $e");
        _setState(TTSState.error);
      }
    }
  }

  Future<void> stop() async {
    _currentTaskId++;
    _setState(TTSState.idle);
    await _audioPlayer.stop();
    await _volcTTS.stopLocal();
  }
}
