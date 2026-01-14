# Word Timings 使用示例

## 数据库迁移

### 1. 执行Schema迁移
在Supabase SQL Editor中执行：
```bash
supabase_migrations/03_add_word_timings.sql
```

### 2. 更新Mock数据（可选）
如需重新插入mock数据：
```bash
supabase_migrations/02_mock_podcast_data.sql
```

## 前端使用示例

### 1. 获取媒体内容和字时间数据

```dart
import 'package:toneup_app/models/media_content_model.dart';
import 'package:toneup_app/models/word_timing_model.dart';
import 'package:toneup_app/services/media_service.dart';

// 获取完整的媒体内容（包括word_timings）
final mediaService = MediaService();
final media = await mediaService.getMediaById(1);

// 访问字时间数据
final WordTimingsData? wordTimings = media.wordTimings;
if (wordTimings != null) {
  print('总段落数: ${wordTimings.segmentTimings.length}');
  print('总字符数: ${wordTimings.totalCharCount}');
}
```

### 2. 播放器中实现字幕高亮

```dart
import 'package:just_audio/just_audio.dart';

class PodcastPlayerPage extends StatefulWidget {
  final MediaContentModel media;
  
  const PodcastPlayerPage({required this.media});
  
  @override
  State<PodcastPlayerPage> createState() => _PodcastPlayerPageState();
}

class _PodcastPlayerPageState extends State<PodcastPlayerPage> {
  late AudioPlayer _audioPlayer;
  int? _currentSegmentId;
  int? _highlightCharIndex;
  
  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    // 监听播放位置
    _audioPlayer.positionStream.listen((position) {
      final currentMs = position.inMilliseconds;
      _updateHighlight(currentMs);
    });
  }
  
  void _updateHighlight(int currentMs) {
    // 找到当前播放的segment
    final segment = _findCurrentSegment(currentMs / 1000);
    if (segment == null) return;
    
    final wordTimings = widget.media.wordTimings;
    if (wordTimings == null) return;
    
    setState(() {
      _currentSegmentId = segment.id;
      
      // 找到当前高亮的字索引
      _highlightCharIndex = wordTimings.getCurrentCharIndex(
        segment.id.toString(),
        currentMs
      );
    });
  }
  
  TranscriptSegment? _findCurrentSegment(double currentSeconds) {
    return widget.media.transcript?.segments.firstWhere(
      (seg) => currentSeconds >= seg.start && currentSeconds < seg.end,
      orElse: () => null,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 播放控制器
          _buildPlayerControls(),
          
          // 字幕显示区域
          Expanded(
            child: ListView.builder(
              itemCount: widget.media.transcript?.segments.length ?? 0,
              itemBuilder: (context, index) {
                final segment = widget.media.transcript!.segments[index];
                return _buildSubtitleSegment(segment);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSubtitleSegment(TranscriptSegment segment) {
    final isCurrentSegment = segment.id == _currentSegmentId;
    final wordTimings = widget.media.wordTimings;
    
    if (!isCurrentSegment || wordTimings == null) {
      // 非当前segment，显示普通文本
      return ListTile(
        title: Text(segment.text),
        subtitle: Text(segment.translation ?? ''),
      );
    }
    
    // 当前segment，使用字高亮
    return _buildHighlightedSubtitle(segment, wordTimings);
  }
  
  Widget _buildHighlightedSubtitle(
    TranscriptSegment segment,
    WordTimingsData wordTimings,
  ) {
    final segmentWords = wordTimings.getSegmentWords(segment.id.toString());
    if (segmentWords == null) {
      return ListTile(title: Text(segment.text));
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 字级别高亮显示
          Wrap(
            spacing: 2,
            runSpacing: 4,
            children: segmentWords.asMap().entries.map((entry) {
              final index = entry.key;
              final wordTiming = entry.value;
              final isHighlight = index == _highlightCharIndex;
              
              return GestureDetector(
                onTap: () {
                  // 点击跳转到该字的时间位置
                  _audioPlayer.seek(
                    Duration(milliseconds: wordTiming.startMs)
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                  decoration: isHighlight
                      ? BoxDecoration(
                          color: Colors.yellow.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        )
                      : null,
                  child: Text(
                    wordTiming.char,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: isHighlight 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      color: isHighlight 
                          ? Colors.blue 
                          : Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          SizedBox(height: 8),
          
          // 英文翻译
          if (segment.translation != null)
            Text(
              segment.translation!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPlayerControls() {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 进度条
          StreamBuilder<Duration?>(
            stream: _audioPlayer.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final duration = _audioPlayer.duration ?? Duration.zero;
              
              return Column(
                children: [
                  Slider(
                    value: position.inMilliseconds.toDouble(),
                    max: duration.inMilliseconds.toDouble(),
                    onChanged: (value) {
                      _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position)),
                      Text(_formatDuration(duration)),
                    ],
                  ),
                ],
              );
            },
          ),
          
          // 播放按钮
          StreamBuilder<PlayerState>(
            stream: _audioPlayer.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final isPlaying = playerState?.playing ?? false;
              
              return IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                iconSize: 48,
                onPressed: () {
                  if (isPlaying) {
                    _audioPlayer.pause();
                  } else {
                    _audioPlayer.play();
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }
  
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
```

### 3. 结合Jieba分词实现词语查询

```dart
import 'package:jieba_flutter/jieba_flutter.dart';

Widget _buildSegmentWithWordBoundaries(
  TranscriptSegment segment,
  WordTimingsData wordTimings,
) {
  // 使用Jieba分词
  final words = JiebaSegmenter.instance.cut(segment.text);
  final segmentWordTimings = wordTimings.getSegmentWords(
    segment.id.toString()
  );
  
  if (segmentWordTimings == null) {
    return Text(segment.text);
  }
  
  int charOffset = 0;
  
  return Wrap(
    spacing: 4,
    runSpacing: 8,
    children: words.map((word) {
      final wordLength = word.length;
      final wordStartIndex = charOffset;
      final wordEndIndex = charOffset + wordLength;
      
      // 获取这个词的所有字
      final wordChars = segmentWordTimings
          .sublist(wordStartIndex, wordEndIndex);
      
      charOffset += wordLength;
      
      return GestureDetector(
        onTap: () => _showWordDefinition(word),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: wordChars.map((timing) {
              final isHighlight = segmentWordTimings.indexOf(timing) 
                  == _highlightCharIndex;
              
              return Text(
                timing.char,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: isHighlight 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                  color: isHighlight ? Colors.blue : Colors.black87,
                ),
              );
            }).toList(),
          ),
        ),
      );
    }).toList(),
  );
}

void _showWordDefinition(String word) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(word),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 这里可以调用词典API获取定义
          Text('词语: $word'),
          // TODO: 显示拼音、释义、例句等
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('关闭'),
        ),
      ],
    ),
  );
}
```

### 4. 性能优化建议

```dart
// 1. 只在播放器页面加载word_timings
final media = await supabase
    .from('media_content')
    .select('*')  // 包含word_timings
    .eq('id', mediaId)
    .single();

// 2. 列表页不加载word_timings
final mediaList = await supabase
    .from('media_content')
    .select('id,title,description,cover_image_url,duration_seconds,hsk_level,transcript')
    .eq('review_status', 'approved');

// 3. 使用本地缓存
class WordTimingsCache {
  static final _cache = <int, WordTimingsData>{};
  static const _maxCacheSize = 5;
  
  static void cache(int mediaId, WordTimingsData data) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[mediaId] = data;
  }
  
  static WordTimingsData? get(int mediaId) => _cache[mediaId];
  
  static void clear() => _cache.clear();
}
```

## 数据格式说明

### 紧凑数组格式
```json
{
  "1": [["今", 160], ["天", 320], ["呢", 400]],
  "2": [["春", 4720], ["节", 4920]]
}
```

- **Key**: segment ID (字符串)
- **Value**: 数组，每个元素是 `[字符, 起始时间(毫秒)]`
- **结束时间**: 从下一个字的起始时间推算

### 存储空间对比
- 完整ASR JSON: ~45KB
- 当前segments: ~2KB
- 紧凑word_timings: ~6KB
- **总计**: ~8KB (比完整ASR减少82%)

## API参考

### WordTiming
```dart
class WordTiming {
  final String char;        // 字符
  final int startMs;        // 起始时间(毫秒)
  
  int getEndMs(WordTiming? nextWord, int segmentEndMs);
}
```

### WordTimingsData
```dart
class WordTimingsData {
  final Map<String, List<WordTiming>> segmentTimings;
  
  // 根据播放位置找到当前高亮的字索引
  int? getCurrentCharIndex(String segmentId, int currentMs);
  
  // 获取指定segment的所有字
  List<WordTiming>? getSegmentWords(String segmentId);
  
  // 获取总字符数
  int get totalCharCount;
}
```

### MediaContentModel
```dart
class MediaContentModel {
  // 原始JSONB数据
  final Map<String, dynamic>? wordTimingsJson;
  
  // 懒加载解析的强类型数据
  WordTimingsData? get wordTimings;
}
```

## 故障排查

### 问题1: wordTimings返回null
**原因**: word_timings字段为空或格式错误
**解决**: 检查数据库中word_timings字段是否正确填充

### 问题2: 字幕高亮不准确
**原因**: 时间戳可能不精确
**解决**: 
1. 检查ASR数据质量
2. 调整getCurrentCharIndex逻辑的时间容差

### 问题3: 性能问题
**原因**: 每次渲染都解析JSON
**解决**: 
1. 使用懒加载 (已实现)
2. 添加本地缓存
3. 只在需要时加载word_timings字段

## 未来扩展

### 1. 支持跟读打分
```dart
// 使用word_timings进行精确的发音评分
final userWordTiming = recordedTimings[i];
final referenceWordTiming = wordTimings.getWordAt(segmentId, i);

final timingAccuracy = calculateTimingScore(
  userWordTiming.startMs,
  referenceWordTiming.startMs,
);
```

### 2. 支持字幕编辑
```dart
// 允许用户手动调整字的时间戳
void adjustWordTiming(String segmentId, int wordIndex, int newStartMs) {
  final words = wordTimings.getSegmentWords(segmentId);
  words[wordIndex] = WordTiming(
    char: words[wordIndex].char,
    startMs: newStartMs,
  );
}
```

### 3. 生成学习报告
```dart
// 统计用户在哪些字上停留时间较长
Map<String, int> analyzeUserPauses(List<Duration> pausePoints) {
  // 分析用户重复播放的字
  // 生成个性化学习建议
}
```
