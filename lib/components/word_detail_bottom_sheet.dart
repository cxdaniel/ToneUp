import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toneup_app/models/word_detail_model.dart';
import 'package:toneup_app/providers/media_player_provider.dart';
import 'package:toneup_app/providers/tts_provider.dart';
import 'package:toneup_app/services/simple_dictionary_service.dart';

/// 词语详情面板（底部弹出）
/// 显示词语的拼音、翻译和例句
class WordDetailBottomSheet extends StatefulWidget {
  final String word; // 要查询的词语
  final String language; // 目标语言
  final MediaPlayerProvider? playerProvider; // 播放器 provider（用于暂停/恢复）

  const WordDetailBottomSheet({
    super.key,
    required this.word,
    required this.language,
    this.playerProvider,
  });

  /// 显示词典面板（立即打开，内部异步加载）
  static Future<void> show(
    BuildContext context, {
    required String word,
    required String language,
    MediaPlayerProvider? playerProvider,
  }) async {
    // 记录打开面板前的播放状态
    final wasPlaying = playerProvider?.isPlaying ?? false;

    // 如果正在播放，暂停播放器
    if (wasPlaying) {
      await playerProvider?.togglePlayPause();
    }

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => WordDetailBottomSheet(
        word: word,
        language: language,
        playerProvider: playerProvider,
      ),
    );

    // 面板关闭后，如果之前在播放，恢复播放
    if (wasPlaying && playerProvider != null) {
      await playerProvider.togglePlayPause();
    }
  }

  @override
  State<WordDetailBottomSheet> createState() => _WordDetailBottomSheetState();
}

class _WordDetailBottomSheetState extends State<WordDetailBottomSheet> {
  final _dictionaryService = SimpleDictionaryService();
  TTSProvider? _ttsProvider;
  WordDetailModel? _wordDetail;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWordDetail();
  }

  /// 加载词语详情
  Future<void> _loadWordDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _dictionaryService.getWordDetail(
        word: widget.word,
        language: widget.language,
      );
      if (mounted) {
        setState(() {
          _wordDetail = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // 面板关闭时停止 TTS（使用保存的引用）
    _ttsProvider?.stop();
    super.dispose();
  }

  /// 播放词语发音
  Future<void> _speakWord(TTSProvider tts) async {
    if (_wordDetail == null) return;

    if (tts.state == TTSState.playing) {
      await tts.stop();
    } else {
      await tts.play(_wordDetail!.word, uselocal: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<TTSProvider>(
      builder: (context, tts, _) {
        // 保存 TTS Provider 引用供 dispose 使用
        _ttsProvider = tts;

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).viewPadding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 拖动指示条
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Loading 状态
              if (_isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading: ${widget.word}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 错误状态
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: theme.colorScheme.error,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Dictionary Load Error',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // 成功加载数据
              if (!_isLoading && _error == null && _wordDetail != null) ...[
                // 基础信息卡片
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(77),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: [
                      // 词语 + 拼音 + 播放按钮
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _wordDetail!.word,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          Spacer(),
                          // 拼音
                          Text(
                            _wordDetail!.pinyin,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer
                                  .withAlpha(204),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          // 播放按钮
                          IconButton(
                            onPressed: tts.state == TTSState.loading
                                ? null
                                : () => _speakWord(tts),
                            icon: tts.state == TTSState.loading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : Icon(
                                    tts.state == TTSState.playing
                                        ? Icons.stop_circle
                                        : Icons.volume_up,
                                    color: theme.colorScheme.primary,
                                  ),
                            iconSize: 32,
                            tooltip: tts.state == TTSState.playing
                                ? '停止'
                                : '播放发音',
                          ),
                        ],
                      ),
                      // 概要释义
                      if (_wordDetail!.summary != null &&
                          _wordDetail!.summary!.isNotEmpty)
                        Text(
                          _wordDetail!.summary!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            height: 1.5,
                          ),
                        ),

                      // 元数据行
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          // HSK等级
                          if (_wordDetail!.hskLevel != null)
                            _buildMetaChip(
                              theme,
                              Icons.school,
                              'HSK ${_wordDetail!.hskLevel}',
                              theme.colorScheme.tertiary,
                            ),
                          // 词条数
                          _buildMetaChip(
                            theme,
                            Icons.article,
                            '${_wordDetail!.entries.length} 词条',
                            theme.colorScheme.secondary,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 词条详情列表
                if (_wordDetail!.entries.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  // Text(
                  //   '词条详情',
                  //   style: theme.textTheme.titleMedium?.copyWith(
                  //     fontWeight: FontWeight.bold,
                  //     color: theme.colorScheme.onSurface,
                  //   ),
                  // ),
                  ..._wordDetail!.entries.asMap().entries.map((mapEntry) {
                    final index = mapEntry.key;
                    final entry = mapEntry.value;
                    return _buildEntryCard(theme, entry, index + 1);
                  }),
                ],
              ],

              const SizedBox(height: 24),

              // 关闭按钮
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 构建元数据芯片
  Widget _buildMetaChip(
    ThemeData theme,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  /// 构建单个词条卡片
  Widget _buildEntryCard(ThemeData theme, WordEntry entry, int index) {
    final definitions = entry.definitions;
    final examples = entry.examples;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 词条标题（序号 + 词性）
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          runAlignment: WrapAlignment.start,
          spacing: 12,
          children: [
            if (entry.pos.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(entry.pos, style: theme.textTheme.titleLarge),
              ),
            ],
            if (definitions.isNotEmpty) ...[
              ...definitions.asMap().entries.map((defEntry) {
                return Text(
                  defEntry.value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                );
              }),
            ],
          ],
        ),

        // 例句列表
        if (examples.isNotEmpty) ...[
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              ...examples.map((example) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '• $example',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ],
    );
  }
}
