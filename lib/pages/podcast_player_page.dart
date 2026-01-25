import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toneup_app/components/chars_with_pinyin.dart';
import 'package:toneup_app/components/word_detail_bottom_sheet.dart';
import 'package:toneup_app/models/media_content_model.dart';
import 'package:toneup_app/providers/media_player_provider.dart';
import 'package:toneup_app/providers/profile_provider.dart';
import 'package:toneup_app/services/simple_dictionary_service.dart';

/// 播客播放器页面
/// 专注于播放和字幕学习的交互
class PodcastPlayerPage extends StatefulWidget {
  final MediaContentModel media;

  const PodcastPlayerPage({super.key, required this.media});

  @override
  State<PodcastPlayerPage> createState() => _PodcastPlayerPageState();
}

class _PodcastPlayerPageState extends State<PodcastPlayerPage> {
  late MediaPlayerProvider _playerProvider;
  late ThemeData theme;
  bool _showPinyin = true; // 是否显示拼音
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _segmentKeys = {}; // 每个segment的key，用于滚动定位
  int? _lastScrolledSegmentId; // 上次滚动到的segment ID
  double? _draggingPosition; // 拖动进度条时的临时位置（毫秒）
  final _dictionaryService = SimpleDictionaryService(); // 词典服务

  @override
  void initState() {
    super.initState();
    _playerProvider = context.read<MediaPlayerProvider>();
    // 初始化segment keys
    for (final segment in widget.media.transcript?.segments ?? []) {
      _segmentKeys[segment.id] = GlobalKey();
    }
    // 加载播客内容
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playerProvider.loadMedia(widget.media);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 自动滚动到当前播放的segment
  void _scrollToCurrentSegment(int? segmentId) {
    if (segmentId == null || segmentId == _lastScrolledSegmentId) return;
    _lastScrolledSegmentId = segmentId;

    final key = _segmentKeys[segmentId];
    if (key == null || key.currentContext == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.2, // 滚动到屏幕上方20%位置
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Consumer<MediaPlayerProvider>(
        builder: (context, player, _) {
          // 当segment变化时自动滚动
          _scrollToCurrentSegment(player.currentSegmentId);

          if (player.isLoading && player.currentMedia == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (player.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    player.errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // 顶部标题栏
              _buildTopBar(),

              // 字幕区域
              Expanded(child: _buildSubtitles(player)),

              // 底部播放控制条
              _buildBottomPlayer(player),
            ],
          );
        },
      ),
    );
  }

  /// 顶部标题栏
  Widget _buildTopBar() {
    final viewPadding = MediaQuery.of(context).viewPadding;

    return Container(
      padding: EdgeInsets.fromLTRB(8, viewPadding.top + 8, 16, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          // 小封面
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.podcasts,
              size: 24,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          // 标题
          Expanded(
            child: Text(
              widget.media.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 字幕区域
  Widget _buildSubtitles(MediaPlayerProvider player) {
    final segments = widget.media.transcript?.segments ?? [];

    if (segments.isEmpty) {
      return const Center(child: Text('暂无字幕数据'));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: segments.length,
      itemBuilder: (context, index) {
        final segment = segments[index];
        final isCurrentSegment = player.currentSegmentId == segment.id;

        return Container(
          key: _segmentKeys[segment.id],
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isCurrentSegment
                ? theme.colorScheme.primaryContainer.withAlpha(128)
                : theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              // 中文字幕（Jieba词语级高亮）+ 拼音
              _buildWordHighlightedText(
                text: segment.text,
                player: player,
                segmentId: segment.id,
              ),

              // 英文翻译
              if (isCurrentSegment)
                Divider(color: theme.colorScheme.outlineVariant),

              if (isCurrentSegment)
                Text(
                  segment.translation ?? '',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// 构建词语级高亮文本（带拼音）
  Widget _buildWordHighlightedText({
    required String text,
    required MediaPlayerProvider player,
    required int segmentId,
  }) {
    final wordTimings = player.getSegmentWordTimings(segmentId);

    if (wordTimings == null || wordTimings.isEmpty) {
      return Text(text, style: theme.textTheme.titleLarge);
    }

    final isCurrentSegment = player.currentSegmentId == segmentId;
    final currentHighlightedWordRange = player.currentHighlightedWordRange;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: wordTimings.map((wordTiming) {
        // 使用时间范围判断高亮，避免重复词语同时高亮
        final isHighlighted =
            isCurrentSegment &&
            currentHighlightedWordRange != null &&
            currentHighlightedWordRange.startMs == wordTiming.startMs &&
            currentHighlightedWordRange.endMs == wordTiming.endMs;

        return GestureDetector(
          onTap: () {
            if (isCurrentSegment) {
              // 当前高亮分段：显示词典面板
              _showWordDetailPanel(wordTiming.word, segmentId);
            } else {
              // 非高亮分段：跳转播放进度
              player.seekToWord(segmentId, wordTiming.word);
            }
          },
          child: CharsWithPinyin(
            chinese: wordTiming.word,
            showPinyin: isCurrentSegment ? _showPinyin : false,
            size: isCurrentSegment ? 28 : 20,
            spacing: isCurrentSegment ? 1.6 : 1.2,
            charsColor: isCurrentSegment
                ? isHighlighted
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.primary
                : theme.colorScheme.secondary,
            pinyinColor: theme.colorScheme.secondary,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w300,
          ),
        );
      }).toList(),
    );
  }

  /// 底部播放控制条
  Widget _buildBottomPlayer(MediaPlayerProvider player) {
    final viewPadding = MediaQuery.of(context).viewPadding;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, viewPadding.bottom + 16),
      decoration: BoxDecoration(
        // color: theme.colorScheme.primaryContainer.withAlpha(100),
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 进度条
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
            ),
            child: Slider(
              value:
                  _draggingPosition ??
                  player.currentPosition.inMilliseconds.toDouble(),
              min: 0,
              max: player.totalDuration.inMilliseconds.toDouble() > 0
                  ? player.totalDuration.inMilliseconds.toDouble()
                  : 1.0,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                setState(() {
                  _draggingPosition = value;
                });
              },
              onChangeEnd: (value) {
                player.seekTo(Duration(milliseconds: value.toInt()));
                setState(() {
                  _draggingPosition = null;
                });
              },
            ),
          ),

          // 时间显示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(
                    _draggingPosition != null
                        ? Duration(milliseconds: _draggingPosition!.toInt())
                        : player.currentPosition,
                  ),
                  style: theme.textTheme.labelMedium,
                ),
                Text(
                  '-${_formatDuration(player.totalDuration - (_draggingPosition != null ? Duration(milliseconds: _draggingPosition!.toInt()) : player.currentPosition))}',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 播放控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // 播放速度
              GestureDetector(
                onTap: _showSpeedDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${player.playbackSpeed}X',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // 上一个分段
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up),
                iconSize: 32,
                onPressed: player.goToPreviousSegment,
              ),

              // 播放/暂停
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    player.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: theme.colorScheme.onPrimary,
                  ),
                  iconSize: 48,
                  onPressed: player.togglePlayPause,
                ),
              ),

              // 下一个分段
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down),
                iconSize: 32,
                onPressed: player.goToNextSegment,
              ),

              // 拼音开关
              IconButton(
                icon: Icon(
                  _showPinyin ? Icons.text_fields : Icons.text_fields_outlined,
                ),
                iconSize: 32,
                color: _showPinyin ? theme.colorScheme.primary : null,
                onPressed: () {
                  setState(() {
                    _showPinyin = !_showPinyin;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 显示词语详情面板
  void _showWordDetailPanel(String word, int segmentId) async {
    // 获取当前 segment 的翻译和文本作为上下文
    final segments = widget.media.transcript?.segments ?? [];
    final segment = segments.firstWhere(
      (s) => s.id == segmentId,
      orElse: () => segments.first,
    );

    // 获取用户母语设置（在异步操作前获取所有 context 数据）
    final profile = context.read<ProfileProvider>().profile;
    final language = profile?.nativeLanguage ?? 'en';

    final wordDetail = await _dictionaryService.getWordDetail(
      word: word,
      language: language,
      contextTranslation: segment.translation,
    );

    // 异步操作后检查 widget 是否仍然挂载
    if (!mounted) return;

    WordDetailBottomSheet.show(
      context,
      wordDetail,
      playerProvider: _playerProvider,
    );
  }

  /// 显示速度选择对话框
  void _showSpeedDialog() {
    final player = context.read<MediaPlayerProvider>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('播放速度'),
          content: RadioGroup<double>(
            groupValue: player.playbackSpeed,
            onChanged: (value) {
              if (value != null) {
                player.setPlaybackSpeed(value);
                Navigator.pop(context);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
                return RadioListTile<double>(
                  title: Text('${speed}X'),
                  value: speed,
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  /// 格式化时长显示
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
