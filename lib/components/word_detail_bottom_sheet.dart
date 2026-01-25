import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:toneup_app/models/word_detail_model.dart';
import 'package:toneup_app/providers/media_player_provider.dart';
import 'package:toneup_app/providers/tts_provider.dart';

/// 词语详情面板（底部弹出）
/// 显示词语的拼音、翻译和例句
class WordDetailBottomSheet extends StatefulWidget {
  final WordDetailModel wordDetail;
  final MediaPlayerProvider? playerProvider; // 播放器 provider（用于暂停/恢复）

  const WordDetailBottomSheet({
    super.key,
    required this.wordDetail,
    this.playerProvider,
  });

  /// 显示词典面板
  static Future<void> show(
    BuildContext context,
    WordDetailModel wordDetail, {
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
        wordDetail: wordDetail,
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
  TTSProvider? _ttsProvider;

  @override
  void dispose() {
    // 面板关闭时停止 TTS（使用保存的引用）
    _ttsProvider?.stop();
    super.dispose();
  }

  /// 播放词语发音
  Future<void> _speakWord(TTSProvider tts) async {
    if (tts.state == TTSState.playing) {
      await tts.stop();
    } else {
      await tts.play(widget.wordDetail.word, uselocal: false);
    }
  }

  /// 判断是否有详细的词条信息（避免显示冗余数据）
  bool _hasDetailedEntries() {
    if (widget.wordDetail.entries.isEmpty) return false;

    final summary = widget.wordDetail.summary?.trim() ?? '';

    // 如果只有一个entry
    if (widget.wordDetail.entries.length == 1) {
      final entry = widget.wordDetail.entries.first;

      // 有例句，显示详细解释
      if (entry.examples.isNotEmpty) return true;

      // 有多个释义，显示详细解释
      if (entry.definitions.length > 1) return true;

      // 只有一个释义且和summary相同，不显示
      if (entry.definitions.length == 1 &&
          entry.definitions.first.trim() == summary) {
        return false;
      }

      // 只有一个释义但和summary不同，显示
      return true;
    }

    // 有多个entries，显示详细解释
    return true;
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
            color: theme.colorScheme.primary,
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
            spacing: 12,
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
              // 汉字 + 拼音 + 播放按钮
              Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                children: [
                  Text(
                    widget.wordDetail.word,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primaryContainer,
                    ),
                  ),
                  // 拼音
                  Text(
                    widget.wordDetail.pinyin,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primaryContainer,
                    ),
                    textAlign: TextAlign.center,
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
                              color: theme.colorScheme.primaryContainer,
                            ),
                          )
                        : Icon(
                            tts.state == TTSState.playing
                                ? Icons.stop_circle
                                : Icons.volume_up,
                            color: theme.colorScheme.primaryContainer,
                          ),
                    iconSize: 36,
                    tooltip: tts.state == TTSState.playing ? '停止' : '播放发音',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 关键释意（summary）
              if (widget.wordDetail.summary != null &&
                  widget.wordDetail.summary!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withAlpha(128),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.wordDetail.summary!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                ),

              // 详细解释（仅在有额外信息时显示）
              if (_hasDetailedEntries()) ...[
                const SizedBox(height: 24),
                _buildSectionTitle(context, '详细解释'),
                const SizedBox(height: 12),
                ...widget.wordDetail.entries.map((entry) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 词性标签
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.tertiaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.pos,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 释义列表（跳过与summary重复的单一释义）
                      if (entry.definitions.length > 1 ||
                          (entry.definitions.isNotEmpty &&
                              entry.definitions.first.trim() !=
                                  (widget.wordDetail.summary?.trim() ?? '')))
                        ...entry.definitions.asMap().entries.map((defEntry) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 16, bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (entry.definitions.length > 1)
                                  Text(
                                    '${defEntry.key + 1}. ',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                Expanded(
                                  child: Text(
                                    defEntry.value,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                      // 该词性的例句
                      if (entry.examples.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(left: 16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer
                                .withAlpha(77),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.outline.withAlpha(51),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: entry.examples.map((example) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  example,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSecondaryContainer,
                                    height: 1.4,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],
                  );
                }),
              ],

              const SizedBox(height: 16),

              // Close button
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primaryContainer,
                  backgroundColor: theme.colorScheme.onPrimaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}
