# 播客功能后端实现总结

> **完成日期**: 2026-01-11  
> **状态**: ✅ 数据层完成，待实现 UI 层

---

## ✅ 已完成的工作

### 1. 数据库设计 (Supabase)

#### 创建的数据表
| 表名 | 主键 | 用途 | 状态 |
|------|------|------|------|
| `media_content` | bigint | 播客/视频主表 | ✅ 已创建 |
| `user_media_progress` | bigint | 学习进度追踪 | ✅ 已创建 |
| `user_vocabulary` | bigint | 全局生词本 | ✅ 已创建 |

#### 核心设计决策
- ✅ 复用现有 `research_core.content_tags` 标签系统
- ✅ 使用 `topic_tag TEXT` 和 `culture_tag TEXT`（与 user_materials 一致）
- ✅ 添加 `indicator_cats INTEGER[]` 关联 15 维能力指标
- ✅ 主键使用 `BIGINT GENERATED ALWAYS AS IDENTITY`
- ✅ 所有表支持软删除（`deleted_at` 字段）
- ✅ 完整的 RLS 权限策略

#### SQL 文件位置
- `supabase_migrations/01_podcast_tables.sql` - 创建脚本
- `supabase_migrations/current_schema.sql` - 现有架构文档
- `supabase_migrations/README.md` - 使用指南

---

### 2. Flutter 数据模型

#### 创建的 Model 类
| 文件 | 类名 | 字段数 | 状态 |
|------|------|--------|------|
| `media_content_model.dart` | `MediaContentModel` | 30+ | ✅ 已生成 |
| | `TranscriptData` | 1 | ✅ 已生成 |
| | `TranscriptSegment` | 7 | ✅ 已生成 |
| `user_media_progress_model.dart` | `UserMediaProgressModel` | 18 | ✅ 已生成 |
| `user_vocabulary_model.dart` | `UserVocabularyModel` | 22 | ✅ 已生成 |

#### 关键特性
- ✅ 使用 `json_annotation` 自动序列化
- ✅ 计算属性（`isApproved`, `formattedDuration` 等）
- ✅ 业务逻辑方法（`updateProgress`, `recordReview` 等）
- ✅ 与现有模型风格保持一致

---

### 3. Service 服务层

#### 创建的 Service 类
| 文件 | 类名 | 方法数 | 用途 |
|------|------|--------|------|
| `media_service.dart` | `MediaService` | 11 | 媒体内容 CRUD |
| `media_progress_service.dart` | `MediaProgressService` | 8 | 学习进度管理 |
| `vocabulary_service.dart` | `VocabularyService` | 12 | 生词本管理 |

#### MediaService 核心功能
```dart
// 查询
- getApprovedMedia()         // 获取已审核媒体列表
- getRecommendedMedia()      // 根据能力指标推荐
- getMediaById()             // 获取详情
- searchMedia()              // 搜索
- getPopularMedia()          // 热门排行

// 创建
- createMedia()              // 上传新媒体

// 更新
- updateTranscript()         // 更新字幕
- incrementViewCount()       // 增加观看次数
- incrementLikeCount()       // 增加点赞
- updateBookmarkCount()      // 更新收藏数

// 删除
- deleteMedia()              // 软删除
```

#### MediaProgressService 核心功能
```dart
// 查询
- getProgress()              // 获取特定媒体进度
- getRecentProgress()        // 最近播放
- getBookmarkedMedia()       // 收藏列表
- getInProgressMedia()       // 未完成列表

// 更新
- updateProgress()           // 更新播放进度
- addShadowingScore()        // 添加跟读得分
- toggleBookmark()           // 切换收藏

// 删除
- deleteProgress()           // 删除进度
```

#### VocabularyService 核心功能
```dart
// 查询
- getAllVocabulary()         // 所有生词
- getDueForReview()          // 待复习生词
- getStarredVocabulary()     // 重点标记
- getVocabularyBySource()    // 按来源筛选
- getVocabularyFromMedia()   // 特定播客的生词
- checkWordExists()          // 检查词汇是否存在

// 创建
- addVocabulary()            // 添加生词

// 更新
- recordReview()             // 记录复习（间隔重复算法）
- toggleStar()               // 切换重点标记
- updateNotes()              // 更新笔记

// 删除
- deleteVocabulary()         // 删除生词
- batchDeleteVocabulary()    // 批量删除
```

---

## 📊 数据流设计

### 播客学习流程
```
1. 用户浏览播客列表
   ↓ MediaService.getApprovedMedia()
   
2. 选择播客并播放
   ↓ MediaService.incrementViewCount()
   ↓ MediaProgressService.updateProgress() (定时保存进度)
   
3. 点击字幕中的生词
   ↓ VocabularyService.addVocabulary(sourceType: 'media')
   
4. 跟读练习
   ↓ MediaProgressService.addShadowingScore()
   
5. 收藏播客
   ↓ MediaProgressService.toggleBookmark()
   ↓ MediaService.updateBookmarkCount()
```

### 生词复习流程
```
1. 查询待复习生词
   ↓ VocabularyService.getDueForReview()
   
2. 用户复习（答对/答错）
   ↓ VocabularyService.recordReview(correct: true/false)
   
3. 自动计算下次复习时间（间隔重复算法）
   - 掌握程度 0-5 级
   - 复习间隔：1天 → 3天 → 7天 → 14天 → 30天 → 90天
```

---

## 🔑 关键技术点

### 1. 字幕数据结构 (JSONB)
```json
{
  "segments": [
    {
      "id": 0,
      "start": 0.5,
      "end": 3.2,
      "text": "大家好，欢迎来到我的频道。",
      "pinyin": "dà jiā hǎo, huān yíng lái dào wǒ de pín dào.",
      "translation": "Hello everyone, welcome to my channel.",
      "keywords": ["大家", "欢迎", "频道"]
    }
  ]
}
```

### 2. 能力指标关联
```dart
// 媒体内容关联指标
media_content.indicator_cats = [4, 5]; // listening, listeningSpeed

// 根据用户目标推荐
final userTargets = [4, 5, 7]; // 用户想提升的指标
final recommended = await MediaService().getRecommendedMedia(
  indicatorIds: userTargets,
);
```

### 3. 间隔重复算法
```dart
// 简化的 SM-2 算法实现
void recordReview({required bool correct}) {
  if (correct) {
    masteryLevel++; // 提升掌握程度
    final intervals = [1, 3, 7, 14, 30, 90];
    nextReviewAt = DateTime.now().add(Duration(days: intervals[masteryLevel]));
  } else {
    masteryLevel--; // 降低掌握程度
    nextReviewAt = DateTime.now().add(Duration(days: 1));
  }
}
```

### 4. RLS 权限策略
```sql
-- 示例：用户只能查看已审核通过的媒体
CREATE POLICY "Anyone can view approved media"
  ON media_content FOR SELECT
  USING (review_status = 'approved' AND deleted_at IS NULL);

-- 用户只能访问自己的学习进度
CREATE POLICY "Users can view own progress"
  ON user_media_progress FOR SELECT
  USING (auth.uid() = user_id AND deleted_at IS NULL);
```

---

## 📁 文件清单

### 数据库 SQL (supabase_migrations/)
- [x] `01_podcast_tables.sql` - 数据表创建脚本
- [x] `current_schema.sql` - 现有架构文档
- [x] `README.md` - 使用指南

### Model 类 (lib/models/)
- [x] `media_content_model.dart`
- [x] `user_media_progress_model.dart`
- [x] `user_vocabulary_model.dart`
- [x] 对应的 `.g.dart` 生成文件

### Service 类 (lib/services/)
- [x] `media_service.dart`
- [x] `media_progress_service.dart`
- [x] `vocabulary_service.dart`

---

## 🚧 下一步开发任务

### Phase 1: Provider 状态管理
- [ ] `MediaProvider` - 媒体列表、筛选、搜索
- [ ] `MediaPlayerProvider` - 播放器状态、进度同步
- [ ] `VocabularyProvider` - 生词本管理、复习队列

### Phase 2: UI 实现
- [ ] 播客列表页 (带标签筛选、HSK 等级筛选)
- [ ] 播客详情页 (封面、简介、开始播放)
- [ ] 播放器页面 (音视频播放、字幕同步、进度保存)
- [ ] 字幕交互 (点击查词、添加生词)
- [ ] 跟读练习界面 (录音、对比、评分)
- [ ] 生词本页面 (列表、复习、统计)

### Phase 3: AIGC 集成
- [ ] ASR 服务（语音转文字）
- [ ] 分词和拼音标注（JiebaSegmenter 已有）
- [ ] 翻译服务（GPT-4 或专业 API）
- [ ] Supabase Edge Function 编排
- [ ] Coze 工作流调用（可选）

---

## 🐛 已知问题与注意事项

### 1. 数据库函数未创建
以下 RPC 函数在 Service 中被调用，但尚未在数据库中创建：
```sql
-- 需要在 Supabase 中手动创建
CREATE OR REPLACE FUNCTION increment_media_view_count(media_uuid BIGINT)
RETURNS void AS $$
BEGIN
  UPDATE media_content SET view_count = view_count + 1 WHERE id = media_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 类似的还有 increment_media_like_count, increment_media_bookmark_count
```

**临时解决方案**: Service 中这些函数调用失败不会抛出异常，不影响主流程。

### 2. 保留关键字问题已修复
- ❌ `current_time` → ✅ `playback_position`

### 3. 软删除查询
所有查询都应添加 `.is_('deleted_at', null)` 过滤条件。

---

## 📖 使用示例

### 示例 1: 获取推荐播客
```dart
final mediaService = MediaService();

// 根据用户目标指标推荐
final userTargets = [4, 5]; // 听懂句子、听力速度
final recommended = await mediaService.getRecommendedMedia(
  indicatorIds: userTargets,
  hskLevel: 3,
  limit: 10,
);
```

### 示例 2: 播放并保存进度
```dart
final progressService = MediaProgressService();

// 每 5 秒保存一次进度
Timer.periodic(Duration(seconds: 5), (timer) async {
  await progressService.updateProgress(
    mediaId: currentMediaId,
    position: audioPlayer.position.inSeconds.toDouble(),
    totalDuration: audioPlayer.duration!.inSeconds.toDouble(),
  );
});
```

### 示例 3: 添加生词
```dart
final vocabService = VocabularyService();

// 从播客添加生词
await vocabService.addVocabulary(
  word: '学习',
  pinyin: 'xué xí',
  definition: 'to study, to learn',
  sourceType: 'media',
  sourceMediaId: currentMediaId,
  sourceContext: '我爱学习中文。',
);
```

---

## 🎯 性能优化建议

1. **分页加载**: `getApprovedMedia()` 已支持 limit/offset
2. **缓存策略**: 使用 Provider 缓存媒体列表
3. **索引优化**: 数据库已创建关键索引
4. **批量操作**: `batchDeleteVocabulary()` 支持批量删除

---

## ✅ 验证清单

- [x] 数据表在 Supabase 成功创建
- [x] Model 类通过 `build_runner` 生成
- [x] Service 类编译无错误
- [ ] RPC 函数在数据库中创建（待补充）
- [ ] Provider 集成测试（下一步）
- [ ] UI 页面实现（下一步）

---

**总结**: 播客功能的数据层架构已完整搭建，包括数据库表、Model 类、Service 类。下一步可以开始实现 Provider 状态管理和 UI 界面。
