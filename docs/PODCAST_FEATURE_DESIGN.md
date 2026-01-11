# ToneUp App - Podcast 学习功能设计文档

> **文档版本**: v1.0  
> **更新日期**: 2026年1月11日  
> **产品参考**: ListenLeap App  
> **状态**: 设计阶段 → 待实施

---

## 📑 目录

- [功能概述](#功能概述)
- [产品定位](#产品定位)
- [数据库设计](#数据库设计)
- [内容生产策略](#内容生产策略)
- [版权合规方案](#版权合规方案)
- [AIGC 自动化流水线](#aigc-自动化流水线)
- [UI/UX 设计](#uiux-设计)
- [技术实现方案](#技术实现方案)
- [实施路线图](#实施路线图)

---

## 功能概述

### 核心价值主张
通过**真实的中文音频/视频内容**（播客、新闻、访谈、短视频）进行沉浸式学习，结合：
- 📝 **逐句字幕** - 支持拼音/汉字双语显示
- 🔊 **跟读练习** - 录音对比与发音评分
- 📚 **生词本** - 点击即查，自动添加到复习列表
- 🎯 **难度分级** - 按HSK等级推荐内容
- 📊 **学习追踪** - 记录播放进度、完成度、复习计划

### 与现有功能的协同
| 现有功能 | Podcast功能 | 协同点 |
|---------|------------|-------|
| 每周学习计划 | 推荐Podcast内容 | 根据目标指标推荐相关主题 |
| 练习题目 | Podcast听力题 | 从Podcast生成理解测试题 |
| 能力评估 | 听力/阅读指标 | 提升listening, comprehension |
| 生词本 | Podcast生词 | 统一到user_materials |
| TTS语音 | Podcast原音 | 对比学习，提升发音 |

---

## 产品定位

### 目标用户
1. **中高级学习者 (HSK 3-6)**: 需要真实语境练习听力
2. **文化爱好者**: 对中国文化、历史、时事感兴趣
3. **商务学习者**: 需要专业领域词汇（经济、科技等）
4. **备考学生**: HSK听力部分训练

### 内容主题分类
```yaml
文化主题 (culture_tag):
  - 传统节日 (春节、中秋)
  - 历史人物 (孔子、李白)
  - 饮食文化 (粤菜、川菜)
  - 艺术形式 (京剧、书法)

话题主题 (topic_tag):
  - 日常生活 (购物、交通)
  - 商务职场 (会议、谈判)
  - 旅游出行 (景点、住宿)
  - 科技创新 (AI、新能源)
  - 教育学习 (考试、留学)
  - 健康养生 (中医、运动)
```

### 竞品对比

| 功能 | ToneUp Podcast | ListenLeap | ChinesePod | HelloChinese |
|------|---------------|------------|------------|--------------|
| 真实内容 | ✅ 新闻/访谈 | ✅ 播客 | ❌ 录制内容 | ❌ 录制内容 |
| 逐句字幕 | ✅ | ✅ | ✅ | ✅ |
| 跟读录音 | ✅ | ❌ | ✅ | ✅ |
| HSK分级 | ✅ | ❌ | ✅ | ✅ |
| AIGC生成 | ✅ (计划) | ❌ | ❌ | ❌ |
| 价格 | ¥18/月 | $9.99/月 | $14/月 | $12.99/月 |

**差异化优势**:
- ✨ **智能推荐**: 基于15维能力指标精准匹配内容
- ✨ **AIGC规模化**: 成本优势支持海量免费内容
- ✨ **学练一体**: Podcast学习 → 自动生成练习题 → 能力评估闭环

---

## 数据库设计

### 新增表结构

#### `media_content` (媒体内容)
```sql
CREATE TABLE media_content (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,                      -- 标题: "春节习俗介绍"
  description TEXT,                         -- 简介
  content_type TEXT NOT NULL,               -- 'audio' | 'video'
  source_type TEXT NOT NULL,                -- 'ugc' | 'admin' | 'aigc'
  
  -- HSK分级与标签
  hsk_level INTEGER NOT NULL,               -- 1-6
  topic_tag INTEGER,                        -- 关联话题
  culture_tag INTEGER,                      -- 关联文化
  
  -- 媒体资源
  media_url TEXT NOT NULL,                  -- Storage路径或外部URL
  cover_image_url TEXT,                     -- 封面图
  duration_seconds INTEGER,                 -- 时长（秒）
  
  -- 字幕数据（JSON）
  transcript JSONB NOT NULL,                -- 完整字幕，见下方结构
  
  -- 学习数据
  vocabulary_list TEXT[],                   -- 核心词汇数组
  difficulty_score FLOAT,                   -- 难度系数 (0-100)
  
  -- 审核状态
  status TEXT DEFAULT 'pending',            -- 'pending' | 'approved' | 'rejected'
  reviewed_by UUID REFERENCES auth.users,   -- 审核人
  reviewed_at TIMESTAMP,
  
  -- 统计数据
  view_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  
  -- 上传者信息（UGC）
  uploaded_by UUID REFERENCES auth.users,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_media_level ON media_content(hsk_level);
CREATE INDEX idx_media_status ON media_content(status);
CREATE INDEX idx_media_topic ON media_content(topic_tag);
CREATE INDEX idx_media_culture ON media_content(culture_tag);
```

**transcript 字段结构**:
```json
{
  "segments": [
    {
      "id": 0,
      "start": 0.5,        // 开始时间（秒）
      "end": 3.2,          // 结束时间（秒）
      "text": "大家好，欢迎来到我的频道。",
      "pinyin": "dà jiā hǎo, huān yíng lái dào wǒ de pín dào.",
      "translation": "Hello everyone, welcome to my channel.",
      "keywords": ["大家", "欢迎", "频道"],  // 本句关键词
      "difficulty": 2      // 句子难度 (HSK等级)
    }
  ]
}
```

---

#### `media_segments` (字幕片段表)
```sql
-- 可选设计：将transcript拆分到独立表，便于检索和复用
CREATE TABLE media_segments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  media_id UUID NOT NULL REFERENCES media_content(id) ON DELETE CASCADE,
  segment_index INTEGER NOT NULL,
  start_time FLOAT NOT NULL,
  end_time FLOAT NOT NULL,
  chinese_text TEXT NOT NULL,
  pinyin_text TEXT,
  english_translation TEXT,
  keywords TEXT[],
  difficulty INTEGER,
  
  UNIQUE(media_id, segment_index)
);

CREATE INDEX idx_segments_media ON media_segments(media_id);
```

---

#### `user_media_progress` (用户学习进度)
```sql
CREATE TABLE user_media_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  media_id UUID NOT NULL REFERENCES media_content(id) ON DELETE CASCADE,
  
  -- 播放进度
  current_time FLOAT DEFAULT 0,             -- 当前播放位置（秒）
  completed BOOLEAN DEFAULT FALSE,          -- 是否完成
  completion_rate FLOAT DEFAULT 0,          -- 完成率 (0-1)
  
  -- 学习统计
  play_count INTEGER DEFAULT 0,             -- 播放次数
  total_duration FLOAT DEFAULT 0,           -- 累计学习时长
  last_played_at TIMESTAMP,
  
  -- 生词记录
  saved_words TEXT[],                       -- 保存的生词
  
  -- 跟读练习
  shadowing_attempts INTEGER DEFAULT 0,     -- 跟读次数
  shadowing_score FLOAT,                    -- 平均跟读得分
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  UNIQUE(user_id, media_id)
);

CREATE INDEX idx_progress_user ON user_media_progress(user_id);
CREATE INDEX idx_progress_media ON user_media_progress(media_id);
```

---

#### `user_saved_vocabulary` (用户生词本)
```sql
CREATE TABLE user_saved_vocabulary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  word TEXT NOT NULL,
  pinyin TEXT,
  definition TEXT,
  example_sentence TEXT,
  
  -- 来源追溯
  source_media_id UUID REFERENCES media_content(id),
  source_context TEXT,                      -- 原句上下文
  
  -- 复习数据
  review_count INTEGER DEFAULT 0,
  last_reviewed_at TIMESTAMP,
  mastery_level INTEGER DEFAULT 0,          -- 掌握程度 (0-5)
  
  created_at TIMESTAMP DEFAULT NOW(),
  
  UNIQUE(user_id, word)
);

CREATE INDEX idx_vocab_user ON user_saved_vocabulary(user_id);
```

---

### 数据关系图

```
media_content (媒体内容)
    ↓ (1:N)
media_segments (字幕片段)
    ↓
user_media_progress (学习进度)
    ↑ (M:1)
auth.users (用户)
    ↓ (1:N)
user_saved_vocabulary (生词本)
```

---

## 内容生产策略

### 三阶段演进路径

#### Phase 1: 管理员主导 (70%) + UGC (30%)
**时间**: v1.1 - Q1 2026  
**目标**: 快速积累种子内容，验证用户需求

**管理员内容来源**:
1. **公开版权内容**:
   - 政府官方媒体（人民日报、新华社）
   - Creative Commons许可播客
   - 自制教学视频
2. **授权合作**:
   - 与中文学习博主合作
   - 购买播客授权

**UGC审核流程**:
```
用户上传 → 自动检测（Audio Fingerprinting）→ 
人工审核（标题、内容合规）→ 
版权声明确认 → 
发布/拒绝
```

**审核标准**:
- ❌ **拒绝**: 第三方版权内容（综艺、电影、音乐）
- ✅ **通过**: 原创录制、公开演讲、自制教学
- ⚠️ **待定**: 新闻片段（需Fair Use分析）

---

#### Phase 2: AIGC占比50%
**时间**: v2.0 - Q2-Q3 2026  
**目标**: 降低内容成本，提升更新频率

**AIGC内容类型**:
- 📰 **新闻摘要**: GPT-4改写当日新闻，生成学习脚本
- 💬 **对话场景**: 模拟商务会议、购物对话
- 📖 **文化故事**: 中国历史、成语故事改编
- 🎓 **专题讲座**: 语法点、词汇专题解析

**质量保证**:
- 人工审核最终脚本
- TTS多语音混用（避免单调）
- 用户反馈评分系统

---

#### Phase 3: AIGC占比80%
**时间**: v3.0+ - 2026 Q4  
**目标**: 实现内容自动化，个性化推荐

**自动化流水线**:
```
用户学习数据 → AI分析薄弱点 → 
自动生成针对性内容 → 
自动发布 → 
用户学习 → 反馈循环
```

**个性化引擎**:
- 基于用户能力指标生成定制内容
- 根据话题兴趣推荐
- 动态调整难度

---

## 版权合规方案

### Safe Harbor避风港原则

#### 实施要点
1. **DMCA合规**:
   - 设置版权代理人（Copyright Agent）
   - 公示投诉流程（页面：/dmca-policy）
   - 快速移除侵权内容（24小时内）

2. **用户协议条款**:
   ```markdown
   ## 内容上传协议
   - 用户保证拥有上传内容的版权或合法授权
   - 用户授予ToneUp非独占、全球性使用权
   - ToneUp有权移除任何侵权内容
   - 多次侵权用户将被永久封禁
   ```

3. **技术保护措施**:
   - **Audio Fingerprinting**: 集成ACRCloud或Audible Magic检测
   - **水印系统**: 为AIGC内容添加数字水印
   - **上传限制**: 单个文件最大100MB，每日最多5条

---

### Fair Use教育豁免分析

**四要素测试**:

| 要素 | ToneUp的情况 | 评分 |
|------|-------------|------|
| 使用目的 | ✅ 教育性、非盈利性质 | 有利 |
| 原作品性质 | ⚠️ 事实性新闻vs创意作品 | 中性 |
| 使用比例 | ✅ 短片段（<5分钟） | 有利 |
| 市场影响 | ✅ 不替代原作品市场 | 有利 |

**降低风险策略**:
- 仅使用新闻、访谈等事实性内容
- 添加实质性教育注释（字幕、生词解释）
- 限制每段长度不超过5分钟
- 标注来源，引导用户观看完整版

**法律咨询建议**: 在正式上线前咨询美国知识产权律师

---

## AIGC 自动化流水线

### 7步生产流程

#### Step 1: 内容规划（AI驱动）
```python
# GPT-4 Prompt
根据以下用户画像生成本周学习主题：
- HSK等级: 4
- 薄弱指标: 听力速度、商务词汇
- 兴趣话题: 科技、经济

输出格式：
{
  "theme": "电商行业发展趋势",
  "learning_objectives": ["商务词汇", "快速听力"],
  "difficulty": 4,
  "duration": "5分钟"
}
```

**输出**: 每周10个主题方案

---

#### Step 2: 脚本生成（GPT-4o）
```python
# GPT-4o Prompt
基于主题"电商行业发展趋势"，生成一段5分钟的中文播客脚本：
- HSK等级: 4
- 词汇复杂度: 适中（1000-2500词）
- 语速: 180字/分钟
- 结构: 开场白 → 主要内容 → 总结

输出JSON格式，包含：
- 完整中文文本
- 逐句时间戳预估
- 核心词汇列表
- 英文翻译
```

**输出**: 结构化脚本JSON

---

#### Step 3: 音频合成（火山引擎TTS）
```dart
// 使用VolcTTS API
final segments = [];
for (var sentence in script['sentences']) {
  final audio = await VolcTTS().synthesizeEF(
    sentence['text'],
    voiceType: 'zh_female_tianmeiruixin_moon_bigtts'
  );
  segments.add({
    'audio': audio,
    'start': currentTime,
    'end': currentTime + duration,
    'text': sentence['text']
  });
  currentTime += duration + 0.3; // 句间停顿
}

// 拼接音频
final fullAudio = AudioMerger.merge(segments);
```

**成本**: ¥0.015/分钟 × 5分钟 = ¥0.075/集

---

#### Step 4: 字幕时间对齐（Whisper API）
```python
# OpenAI Whisper API
import whisper

model = whisper.load_model("large-v3")
result = model.transcribe(
  audio_file,
  language="zh",
  task="transcribe",
  word_timestamps=True
)

# 输出精确时间戳
{
  "segments": [
    {
      "start": 0.5,
      "end": 3.2,
      "text": "大家好，欢迎来到今天的播客。",
      "words": [
        {"word": "大家", "start": 0.5, "end": 1.0},
        {"word": "好", "start": 1.0, "end": 1.3}
      ]
    }
  ]
}
```

**成本**: $0.006/分钟 × 5分钟 = $0.03/集

---

#### Step 5: 拼音与翻译生成
```dart
// 拼音转换
import 'package:pinyin/pinyin.dart';

final pinyinText = PinyinHelper.getPinyin(chineseText, separator: ' ');

// 英文翻译（GPT-4 Turbo）
final translation = await OpenAI.complete(
  prompt: '将以下中文翻译成英文：$chineseText',
  model: 'gpt-4-turbo'
);
```

**成本**: $0.01/1k tokens × 5000 chars ≈ $0.05/集

---

#### Step 6: 封面图生成（DALL-E 3）
```python
# OpenAI DALL-E 3 API
response = openai.Image.create(
  model="dall-e-3",
  prompt=f"A minimalist podcast cover for Chinese learning, theme: {theme}, style: modern flat design, colors: blue and orange",
  size="1024x1024",
  quality="standard"
)

cover_url = response.data[0].url
```

**成本**: $0.04/张 (标准质量)

---

#### Step 7: 自动发布与QA
```dart
// 1. 上传音频到Supabase Storage
final audioPath = await _supabase.storage
    .from('media')
    .upload('podcasts/${contentId}.mp3', audioBytes);

// 2. 上传封面图
final coverPath = await _supabase.storage
    .from('media')
    .upload('covers/${contentId}.jpg', coverBytes);

// 3. 写入数据库
await _supabase.from('media_content').insert({
  'title': script['title'],
  'content_type': 'audio',
  'source_type': 'aigc',
  'hsk_level': 4,
  'media_url': audioPath,
  'cover_image_url': coverPath,
  'transcript': jsonEncode(transcript),
  'vocabulary_list': keywords,
  'status': 'pending'  // 等待人工审核
});

// 4. 发送审核通知
await sendReviewNotification(contentId);
```

---

### 成本分析

| 步骤 | 服务 | 单集成本 |
|------|------|---------|
| 脚本生成 | GPT-4o | $0.02 |
| TTS合成 | 火山引擎 | ¥0.075 ($0.01) |
| 时间对齐 | Whisper | $0.03 |
| 翻译 | GPT-4 Turbo | $0.05 |
| 封面图 | DALL-E 3 | $0.04 |
| **总计** | - | **$0.15 (¥1.08)** |

**vs 人工成本**:
- 人工录制: ¥500/小时 × 2小时 = ¥1000
- 人工剪辑: ¥200/集
- 人工翻译: ¥300/集
- **总计**: ¥1500/集

**成本节约**: 99.3% 💰

---

## UI/UX 设计

### 页面结构

#### PodcastPage (首页)
```
┌─────────────────────────────────────┐
│ 🎧 为你推荐                  [搜索]  │
├─────────────────────────────────────┤
│ ┌───────────────────────────────┐   │
│ │ [封面图]  春节习俗介绍        │   │
│ │ HSK 3 · 文化 · 15分钟        │   │
│ │ ⭐ 4.8 · 1.2k播放            │   │
│ └───────────────────────────────┘   │
│                                      │
│ 🔥 热门播客                          │
│ [横向滚动卡片...]                    │
│                                      │
│ 📚 继续学习                          │
│ [进度条卡片...]                      │
│                                      │
│ 🎯 分级练习                          │
│ [HSK 1-6] 按钮组                     │
└─────────────────────────────────────┘
```

---

#### PodcastDetailPage (播放页)
```
┌─────────────────────────────────────┐
│ [← 返回]        春节习俗介绍         │
├─────────────────────────────────────┤
│         [封面图 400x400]             │
│                                      │
│ ┌──────────────────────────────┐    │
│ │ ▶️ [进度条] 03:25 / 15:00    │    │
│ │ 🔄 0.75x | 1x | 1.25x | 1.5x │    │
│ └──────────────────────────────┘    │
│                                      │
│ 📝 字幕模式: [中文] [拼音] [英文]   │
│                                      │
│ ┌──────────────────────────────┐    │
│ │ 春节是中国最重要的传统节日。  │    │
│ │ chūn jié shì zhōng guó...    │    │
│ │ The Spring Festival is...    │    │
│ │                              │    │
│ │ [⏸️暂停] [🎤跟读] [💾保存]    │    │
│ └──────────────────────────────┘    │
│                                      │
│ 📚 生词本 (3个)                      │
│ [传统] [节日] [庆祝]                 │
└─────────────────────────────────────┘
```

---

#### 交互流程

**播放控制**:
```dart
// 点击句子 → 跳转到对应时间
onTapSegment(segment) {
  audioPlayer.seek(Duration(seconds: segment.start));
  highlightedSegmentId = segment.id;
}

// 长按词汇 → 显示定义弹窗
onLongPressWord(word) {
  showModalBottomSheet(
    context: context,
    builder: (context) => WordDefinitionSheet(word: word)
  );
}
```

**跟读功能**:
```dart
// 1. 录音
final recorder = AudioRecorder();
await recorder.start();

// 2. 播放对比
await audioPlayer.play(originalAudio);
await audioPlayer.play(userRecording);

// 3. 评分（调用语音识别API）
final score = await SpeechRecognition.evaluate(
  reference: segment.text,
  userAudio: userRecording
);
```

---

### Material Design 3适配

```dart
// PodcastCard Widget
Card(
  elevation: 0,
  color: Theme.of(context).colorScheme.surfaceContainer,
  child: Column(
    children: [
      Image.network(podcast.coverUrl),
      ListTile(
        title: Text(podcast.title),
        subtitle: Row(
          children: [
            Chip(
              label: Text('HSK ${podcast.level}'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
            SizedBox(width: 8),
            Text('${podcast.duration}分钟'),
          ],
        ),
      ),
    ],
  ),
)
```

---

## 技术实现方案

### Provider架构

**PodcastProvider**
```dart
class PodcastProvider extends ChangeNotifier {
  List<MediaContentModel> _recommendedPodcasts = [];
  MediaContentModel? _currentPlaying;
  UserMediaProgressModel? _currentProgress;
  
  // 获取推荐列表
  Future<void> fetchRecommendations(int userLevel) async {
    final data = await _supabase
        .from('media_content')
        .select()
        .eq('hsk_level', userLevel)
        .eq('status', 'approved')
        .order('view_count', ascending: false)
        .limit(10);
    
    _recommendedPodcasts = data.map((e) => MediaContentModel.fromJson(e)).toList();
    notifyListeners();
  }
  
  // 播放控制
  Future<void> playPodcast(MediaContentModel podcast) async {
    _currentPlaying = podcast;
    
    // 加载或创建进度记录
    _currentProgress = await _loadProgress(podcast.id);
    
    // 初始化音频播放器
    await _audioPlayer.setUrl(podcast.mediaUrl);
    await _audioPlayer.seek(Duration(seconds: _currentProgress.currentTime));
    await _audioPlayer.play();
    
    notifyListeners();
  }
  
  // 保存进度
  Future<void> saveProgress(double currentTime) async {
    await _supabase.from('user_media_progress').upsert({
      'user_id': _userId,
      'media_id': _currentPlaying!.id,
      'current_time': currentTime,
      'last_played_at': DateTime.now().toIso8601String(),
    });
  }
  
  // 保存生词
  Future<void> saveWord(String word, String context) async {
    await _supabase.from('user_saved_vocabulary').upsert({
      'user_id': _userId,
      'word': word,
      'source_media_id': _currentPlaying!.id,
      'source_context': context,
    });
  }
}
```

---

### 音频播放器集成

```dart
import 'package:just_audio/just_audio.dart';

class PodcastAudioPlayer {
  final AudioPlayer _player = AudioPlayer();
  List<TranscriptSegment> _segments = [];
  
  // 同步字幕高亮
  Stream<int?> get currentSegmentStream {
    return _player.positionStream.map((position) {
      final seconds = position.inMilliseconds / 1000;
      return _segments.indexWhere(
        (s) => s.start <= seconds && seconds < s.end
      );
    });
  }
  
  // 句子循环播放
  Future<void> loopSegment(TranscriptSegment segment) async {
    await _player.setClip(
      start: Duration(milliseconds: (segment.start * 1000).toInt()),
      end: Duration(milliseconds: (segment.end * 1000).toInt()),
    );
    await _player.setLoopMode(LoopMode.one);
    await _player.play();
  }
}
```

---

### 字幕渲染组件

```dart
class SubtitleWidget extends StatelessWidget {
  final TranscriptSegment segment;
  final bool showPinyin;
  final bool showTranslation;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 中文文本
          SelectableText(
            segment.text,
            style: Theme.of(context).textTheme.headlineSmall,
            onTap: () => _handleWordTap(context),
          ),
          
          // 拼音（可选）
          if (showPinyin) ...[
            SizedBox(height: 8),
            Text(
              segment.pinyin,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
          
          // 英文翻译（可选）
          if (showTranslation) ...[
            SizedBox(height: 8),
            Text(
              segment.translation,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }
  
  void _handleWordTap(BuildContext context) {
    // 分词 + 显示定义
  }
}
```

---

## 实施路线图

### Phase 1: MVP (v1.1 - Q1 2026)

**核心功能**:
- ✅ 数据库表创建与迁移
- ✅ 管理端上传CMS（简易版）
- ✅ 播放器UI（播放/暂停/进度条）
- ✅ 字幕显示（中文+拼音）
- ✅ 生词本保存
- ✅ 学习进度追踪

**内容规模**:
- 50集管理员内容（HSK 1-3为主）
- 开放UGC上传（限制100用户内测）

**技术栈**:
- Flutter: PodcastPage, PodcastDetailPage
- Supabase: 数据库 + Storage
- just_audio: 音频播放
- jieba_flutter: 中文分词

**里程碑**:
- Week 1-2: 数据库设计 + 迁移脚本
- Week 3-4: 播放器UI + 音频控制
- Week 5-6: 字幕同步 + 生词保存
- Week 7-8: 内部测试 + Bug修复

---

### Phase 2: AIGC集成 (v2.0 - Q2-Q3 2026)

**新增功能**:
- 🤖 GPT-4脚本生成
- 🎙️ 火山TTS批量合成
- 📊 用户反馈评分系统
- 🎯 智能推荐引擎

**内容规模**:
- 200集AIGC内容
- 每周新增10集

**成本控制**:
- 单集成本: ¥1.5 (含人工审核)
- 月度预算: ¥600 (400集/年)

**里程碑**:
- Month 1-2: OpenAI API集成
- Month 3: 自动化流水线搭建
- Month 4: 批量生成测试
- Month 5-6: 优化 + 扩容

---

### Phase 3: 个性化推荐 (v3.0 - Q4 2026)

**高级功能**:
- 🧠 基于能力指标的个性化内容生成
- 🗣️ 语音评分（发音准确度）
- 📈 学习路径规划
- 🏆 成就系统与排行榜

**技术升级**:
- 自建Coqui TTS服务器（降低成本）
- 推荐算法优化（协同过滤）
- 实时语音识别（Azure Speech）

---

## 附录

### 参考资源

**竞品研究**:
- ListenLeap: https://listenleap.app
- ChinesePod: https://chinesepod.com
- HelloChinese Podcast功能

**技术文档**:
- OpenAI Whisper API: https://platform.openai.com/docs/guides/speech-to-text
- 火山引擎TTS: https://www.volcengine.com/docs/6561
- just_audio Package: https://pub.dev/packages/just_audio

**法律参考**:
- DMCA Safe Harbor: 17 U.S.C. § 512
- Fair Use Guidelines: https://www.copyright.gov/fair-use/

---

## 下一步行动

1. **数据库迁移**: 编写SQL脚本，创建3张新表
2. **原型设计**: Figma设计播放器UI
3. **技术选型**: 确认音频播放器库（just_audio vs audioplayers）
4. **内容采购**: 联系中文学习博主，获取授权
5. **法律咨询**: 咨询知识产权律师，确认Fair Use策略

---

**📌 相关文档**:
- [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) - 项目架构
- [DATA_MODELS.md](./DATA_MODELS.md) - 数据模型
- [API_REFERENCE.md](./API_REFERENCE.md) - API文档
