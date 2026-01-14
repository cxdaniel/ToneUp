import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:jieba_flutter/analysis/jieba_segmenter.dart';
import 'package:toneup_app/models/media_content_model.dart';

/// 词语时间范围模型
class WordTimeRange {
  final String word;
  final int startMs;
  final int endMs;

  WordTimeRange({
    required this.word,
    required this.startMs,
    required this.endMs,
  });
}

/// 播客播放器状态管理
/// 负责音频播放控制、进度跟踪、Jieba词语级字幕高亮
class MediaPlayerProvider extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  MediaContentModel? _currentMedia;
  bool _disposed = false;

  // 播放状态
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;
  String? _errorMessage;

  // 字幕高亮状态（Jieba词语级别）
  int? _currentSegmentId; // 当前高亮的segment
  String? _currentHighlightedWord; // 当前高亮的词语
  WordTimeRange? _currentHighlightedWordRange; // 当前高亮词语的时间范围
  final Map<int, List<WordTimeRange>> _segmentWordTimings =
      {}; // 缓存每个segment的词语时间范围

  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  // Getters
  AudioPlayer get audioPlayer => _audioPlayer;
  MediaContentModel? get currentMedia => _currentMedia;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed => _playbackSpeed;
  String? get errorMessage => _errorMessage;
  int? get currentSegmentId => _currentSegmentId;
  String? get currentHighlightedWord => _currentHighlightedWord;
  WordTimeRange? get currentHighlightedWordRange =>
      _currentHighlightedWordRange;

  MediaPlayerProvider() {
    _initializeAudioSession();
    _initializeListeners();
  }

  /// 初始化音频会话（支持后台播放）
  Future<void> _initializeAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      debugPrint('✅ 音频会话初始化成功（支持后台播放）');
    } catch (e) {
      debugPrint('⚠️ 音频会话初始化失败: $e');
    }
  }

  /// 初始化音频播放器监听
  void _initializeListeners() {
    // 监听播放进度
    _positionSubscription = _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      _updateHighlightedWord(position.inMilliseconds);
      if (!_disposed) notifyListeners();
    });

    // 监听总时长
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration;
        if (!_disposed) notifyListeners();
      }
    });

    // 监听播放状态
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      _isLoading =
          state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;

      // 播放完成时停止并重置到开头
      if (state.processingState == ProcessingState.completed) {
        _audioPlayer.pause();
        _audioPlayer.seek(Duration.zero);
        _isPlaying = false;
      }

      if (!_disposed) notifyListeners();
    });
  }

  /// 加载播客内容
  Future<void> loadMedia(MediaContentModel media) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _currentMedia = media;
      notifyListeners();

      // 预处理所有segment的Jieba分词和时间范围
      _preprocessWordTimings();

      // 加载音频
      await _audioPlayer.setUrl(media.mediaUrl);

      _isLoading = false;
      notifyListeners();

      // 自动开始播放
      await _audioPlayer.play();
    } catch (e) {
      _errorMessage = '加载音频失败: $e';
      _isLoading = false;
      debugPrint('❌ MediaPlayerProvider 加载音频失败: $e');
      notifyListeners();
    }
  }

  /// 预处理所有segment的词语时间范围
  /// 使用Jieba分词，为每个词语计算起始和结束时间
  void _preprocessWordTimings() {
    if (_currentMedia == null) return;

    _segmentWordTimings.clear();
    final wordTimings = _currentMedia!.wordTimings;
    if (wordTimings == null) return;

    final segments = _currentMedia!.transcript?.segments ?? [];

    for (final segment in segments) {
      final segmentId = segment.id;
      final segmentText = segment.text;

      // 使用Jieba分词
      final seg = JiebaSegmenter();
      final words = seg.sentenceProcess(segmentText);
      final segmentWordTimingsList = <WordTimeRange>[];

      // 获取该segment的字级别时间数据
      final charTimings = wordTimings.getSegmentWords(segmentId.toString());
      if (charTimings == null || charTimings.isEmpty) continue;

      debugPrint(
        '🔍 Segment $segmentId: 原文长度=${segmentText.length}, charTimings长度=${charTimings.length}, 分词数=${words.length}',
      );

      // 建立原文字符到 charTimings 索引的映射（跳过标点符号等无时间数据的字符）
      int charTimingIndex = 0; // charTimings 数组的索引
      int textIndex = 0; // 在原文中的位置
      int lastEndMs = (segment.start * 1000).toInt(); // 上一个词的结束时间

      for (final word in words) {
        if (word.trim().isEmpty) continue;

        // 检查是否是标点符号（不包含汉字、字母、数字）
        final isPunctuation = !RegExp(
          r'[\u4e00-\u9fa5a-zA-Z0-9]',
        ).hasMatch(word);

        // 在原文中找到这个词语的位置
        final wordStartInText = segmentText.indexOf(word, textIndex);
        if (wordStartInText == -1) {
          debugPrint('⚠️ Segment $segmentId: 词语 "$word" 未在原文中找到');
          continue;
        }

        // 标点符号没有时间数据，但仍需要显示
        if (isPunctuation) {
          // 使用前一个词的结束时间作为标点的时间范围
          segmentWordTimingsList.add(
            WordTimeRange(word: word, startMs: lastEndMs, endMs: lastEndMs),
          );
          textIndex = wordStartInText + word.length;
          continue;
        }

        // 如果当前 charTiming 索引已经用完，跳过这个词
        if (charTimingIndex >= charTimings.length) {
          debugPrint('⚠️ Segment $segmentId: 词语 "$word" charTimingIndex 已超出范围');
          break;
        }

        // 计算这个词语实际能匹配多少个字符的时间数据
        final availableTimings = charTimings.length - charTimingIndex;
        final wordCharsWithTiming = word.length <= availableTimings
            ? word.length
            : availableTimings;

        if (wordCharsWithTiming <= 0) {
          textIndex = wordStartInText + word.length;
          continue;
        }

        // 获取词语的起始和结束时间
        final firstCharIdx = charTimingIndex;
        final lastCharIdx = charTimingIndex + wordCharsWithTiming - 1;

        final startMs = charTimings[firstCharIdx].startMs;
        final segmentEndMs = (segment.end * 1000).toInt();
        final endMs = charTimings[lastCharIdx].getEndMs(
          lastCharIdx + 1 < charTimings.length
              ? charTimings[lastCharIdx + 1]
              : null,
          segmentEndMs,
        );

        segmentWordTimingsList.add(
          WordTimeRange(word: word, startMs: startMs, endMs: endMs),
        );

        // 更新上一个词的结束时间（供标点符号使用）
        lastEndMs = endMs;

        charTimingIndex += wordCharsWithTiming;
        textIndex = wordStartInText + word.length;
      }

      _segmentWordTimings[segmentId] = segmentWordTimingsList;
    }

    debugPrint('✅ 预处理完成，共 ${_segmentWordTimings.length} 个segments');
  }

  /// 根据当前播放位置更新高亮的词语
  void _updateHighlightedWord(int currentMs) {
    if (_currentMedia == null || _segmentWordTimings.isEmpty) return;

    final segments = _currentMedia!.transcript?.segments ?? [];

    // 找到当前播放位置对应的segment
    for (final segment in segments) {
      final segmentStartMs = (segment.start * 1000).toInt();
      final segmentEndMs = (segment.end * 1000).toInt();

      if (currentMs >= segmentStartMs && currentMs < segmentEndMs) {
        _currentSegmentId = segment.id;

        // 找到该segment中当前高亮的词语
        final wordTimings = _segmentWordTimings[segment.id];
        if (wordTimings == null) return;

        for (final wordTiming in wordTimings) {
          if (currentMs >= wordTiming.startMs && currentMs < wordTiming.endMs) {
            // 通过时间范围判断是否需要更新高亮（避免重复词语同时高亮）
            if (_currentHighlightedWordRange?.startMs != wordTiming.startMs ||
                _currentHighlightedWordRange?.endMs != wordTiming.endMs) {
              _currentHighlightedWord = wordTiming.word;
              _currentHighlightedWordRange = wordTiming;
              // 只在词语切换时才通知更新，减少UI刷新
              if (!_disposed) notifyListeners();
            }
            return;
          }
        }

        // 如果没有匹配的词语，清除高亮
        if (_currentHighlightedWord != null) {
          _currentHighlightedWord = null;
          _currentHighlightedWordRange = null;
          if (!_disposed) notifyListeners();
        }
        return;
      }
    }

    // 如果不在任何segment范围内，清除高亮
    if (_currentSegmentId != null || _currentHighlightedWord != null) {
      _currentSegmentId = null;
      _currentHighlightedWord = null;
      _currentHighlightedWordRange = null;
      if (!_disposed) notifyListeners();
    }
  }

  /// 获取指定segment的词语时间范围列表
  List<WordTimeRange>? getSegmentWordTimings(int segmentId) {
    return _segmentWordTimings[segmentId];
  }

  /// 播放/暂停
  Future<void> togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.play();
      }
    } catch (e) {
      _errorMessage = '播放控制失败: $e';
      debugPrint('❌ 播放控制失败: $e');
      notifyListeners();
    }
  }

  /// 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    try {
      await _audioPlayer.seek(position);
    } catch (e) {
      _errorMessage = '跳转失败: $e';
      debugPrint('❌ 跳转失败: $e');
      notifyListeners();
    }
  }

  /// 快进10秒
  Future<void> seekForward() async {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    await seekTo(newPosition > _totalDuration ? _totalDuration : newPosition);
  }

  /// 跳转到上一个分段
  Future<void> goToPreviousSegment() async {
    if (_currentMedia == null) return;

    final segments = _currentMedia!.transcript?.segments ?? [];
    if (segments.isEmpty) return;

    // 找到当前分段的索引
    final currentIndex = segments.indexWhere((s) => s.id == _currentSegmentId);

    if (currentIndex <= 0) {
      // 如果是第一个分段或未找到，跳转到第一个分段开始
      await seekTo(
        Duration(milliseconds: (segments.first.start * 1000).toInt()),
      );
    } else {
      // 跳转到上一个分段开始
      await seekTo(
        Duration(
          milliseconds: (segments[currentIndex - 1].start * 1000).toInt(),
        ),
      );
    }
  }

  /// 跳转到下一个分段
  Future<void> goToNextSegment() async {
    if (_currentMedia == null) return;

    final segments = _currentMedia!.transcript?.segments ?? [];
    if (segments.isEmpty) return;

    // 找到当前分段的索引
    final currentIndex = segments.indexWhere((s) => s.id == _currentSegmentId);

    if (currentIndex == -1 || currentIndex >= segments.length - 1) {
      // 如果是最后一个分段或未找到，跳转到最后一个分段开始
      await seekTo(
        Duration(milliseconds: (segments.last.start * 1000).toInt()),
      );
    } else {
      // 跳转到下一个分段开始
      await seekTo(
        Duration(
          milliseconds: (segments[currentIndex + 1].start * 1000).toInt(),
        ),
      );
    }
  }

  /// 设置播放速度
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      await _audioPlayer.setSpeed(speed);
      _playbackSpeed = speed;
      notifyListeners();
    } catch (e) {
      _errorMessage = '设置播放速度失败: $e';
      debugPrint('❌ 设置播放速度失败: $e');
      notifyListeners();
    }
  }

  /// 点击词语，跳转到该词语的播放位置
  Future<void> seekToWord(int segmentId, String word) async {
    final wordTimings = _segmentWordTimings[segmentId];
    if (wordTimings == null) return;

    for (final wordTiming in wordTimings) {
      if (wordTiming.word == word) {
        await seekTo(Duration(milliseconds: wordTiming.startMs));
        return;
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }
}
