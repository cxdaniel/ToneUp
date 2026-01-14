import 'package:flutter/material.dart';
import 'package:toneup_app/models/word_detail_model.dart';
import 'package:toneup_app/providers/media_player_provider.dart';
import 'package:toneup_app/services/volc_api.dart';

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
  final _volcTTS = VolcTTS();
  bool _isSpeaking = false;

  @override
  void dispose() {
    _volcTTS.stopLocal(); // 面板关闭时停止 TTS
    super.dispose();
  }

  /// 播放词语发音
  Future<void> _speakWord() async {
    if (_isSpeaking) {
      await _volcTTS.stopLocal();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await _volcTTS.speakLocal(text: widget.wordDetail.word);
      // TTS 播放完成后重置状态
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isSpeaking = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

          const SizedBox(height: 24),

          // 汉字 + 播放按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.wordDetail.word,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              // 播放按钮
              IconButton(
                onPressed: _speakWord,
                icon: Icon(
                  _isSpeaking ? Icons.stop_circle : Icons.volume_up,
                  color: theme.colorScheme.primary,
                ),
                iconSize: 36,
                tooltip: _isSpeaking ? '停止' : '播放发音',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 拼音
          Text(
            widget.wordDetail.pinyin,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.secondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // 翻译区域
          if (widget.wordDetail.translation != null &&
              widget.wordDetail.translation!.isNotEmpty) ...[
            _buildSectionTitle(context, '翻译'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(77),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.wordDetail.translation!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // 例句区域
          if (widget.wordDetail.exampleSentence != null &&
              widget.wordDetail.exampleSentence!.isNotEmpty) ...[
            _buildSectionTitle(context, '例句'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer.withAlpha(77),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.wordDetail.exampleSentence!,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  height: 1.6,
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 关闭按钮
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('关闭'),
          ),
        ],
      ),
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
