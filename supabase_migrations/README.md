# Supabase 数据库迁移指南

## 📋 播客功能数据表说明

### 迁移文件
- `01_podcast_tables.sql` - 播客功能完整数据表创建脚本

### 数据表概览

#### 1️⃣ **media_tags** (标签表)
- **用途**: 灵活的多维度标签系统
- **分类**: 
  - `topic` - 话题标签（日常生活、商务职场、旅游等）
  - `culture` - 文化标签（传统节日、历史人物、饮食文化等）
  - `scenario` - 场景标签（对话、新闻、访谈等）
- **特点**: 预设了常用标签，可后续扩展

#### 2️⃣ **media_content** (媒体内容主表)
- **用途**: 存储播客/视频的核心信息
- **支持的来源类型**:
  - `upload` - 本地上传到 Supabase Storage
  - `youtube` - YouTube 视频链接
  - `bilibili` - B站视频链接
  - `aigc` - AI 生成的内容
- **关键字段**:
  - `transcript` (JSONB) - 字幕数据，包含分段、拼音、翻译
  - `processing_status` - 跟踪 AIGC 任务状态
  - `review_status` - 内容审核状态（UGC场景）
  - `vocabulary_list` - 核心词汇数组

#### 3️⃣ **media_content_tags** (关联表)
- **用途**: 多对多关系，一个媒体可关联多个标签
- **使用场景**: 支持按多个维度筛选内容

#### 4️⃣ **user_media_progress** (学习进度表)
- **用途**: 记录用户观看进度和学习数据
- **核心功能**:
  - 播放进度保存（断点续播）
  - 跟读练习得分记录
  - 收藏功能
  - 学习统计（播放次数、观看时长）

#### 5️⃣ **user_vocabulary** (全局生词本)
- **用途**: 统一管理所有来源的生词
- **来源类型**:
  - `media` - 从播客添加
  - `practice` - 从练习模块添加
  - `manual` - 手动添加
- **高级功能**:
  - 间隔重复复习（`next_review_at`）
  - 掌握程度分级（0-5级）
  - 重点标记和笔记

---

## 🚀 执行迁移步骤

### 方法一：Supabase Dashboard（推荐）
1. 打开 [Supabase Dashboard](https://supabase.com/dashboard)
2. 选择你的项目：`kixonwnuivnjqlraydmz`
3. 进入 **SQL Editor**
4. 新建查询，粘贴 `01_podcast_tables.sql` 的全部内容
5. 点击 **Run** 执行
6. 检查是否有错误提示

### 方法二：Supabase CLI
```bash
# 1. 安装 Supabase CLI（如果未安装）
brew install supabase/tap/supabase

# 2. 登录
supabase login

# 3. 链接到远程项目
supabase link --project-ref kixonwnuivnjqlraydmz

# 4. 执行迁移
supabase db push
```

---

## ✅ 验证迁移成功

执行以下 SQL 查询，检查表是否创建成功：

```sql
-- 查看所有新创建的表
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'media_tags', 
    'media_content', 
    'media_content_tags', 
    'user_media_progress', 
    'user_vocabulary'
  );

-- 查看预设的标签数据
SELECT * FROM media_tags ORDER BY category, sort_order;

-- 检查 RLS 策略
SELECT schemaname, tablename, policyname 
FROM pg_policies 
WHERE tablename LIKE 'media%' OR tablename = 'user_vocabulary';
```

---

## 📊 字幕数据结构 (transcript JSONB)

### 标准格式
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
    },
    {
      "id": 1,
      "start": 3.5,
      "end": 7.8,
      "text": "今天我们来学习中文的声调。",
      "pinyin": "jīn tiān wǒ men lái xué xí zhōng wén de shēng diào.",
      "translation": "Today we will learn Chinese tones.",
      "keywords": ["今天", "学习", "声调"]
    }
  ]
}
```

### 字段说明
- `id`: 片段序号（从0开始）
- `start` / `end`: 时间戳（秒，支持小数）
- `text`: 中文字幕
- `pinyin`: 拼音标注（带声调）
- `translation`: 英文翻译
- `keywords`: 关键词数组（用于生词本推荐）

---

## 🔐 权限策略 (RLS)

### media_content
- ✅ 所有人可查看已审核通过的内容
- ✅ 上传者可查看自己上传的内容（包括待审核）
- ✅ 认证用户可上传新内容
- ✅ 上传者可更新/删除自己的内容

### user_media_progress
- ✅ 用户只能访问自己的学习进度

### user_vocabulary
- ✅ 用户只能访问自己的生词本

### media_tags
- ✅ 所有人可查看标签（公开数据）

---

## 🛠 常用查询示例

### 按标签筛选媒体
```sql
-- 查找所有"商务职场"相关的视频
SELECT mc.* 
FROM media_content mc
JOIN media_content_tags mct ON mc.id = mct.media_id
JOIN media_tags mt ON mct.tag_id = mt.id
WHERE mt.name = '商务职场' 
  AND mc.review_status = 'approved';
```

### 获取用户学习中的播客
```sql
-- 查找用户未完成的播客
SELECT mc.title, ump.completion_rate, ump.current_time
FROM user_media_progress ump
JOIN media_content mc ON ump.media_id = mc.id
WHERE ump.user_id = 'your-user-id'
  AND ump.completed = FALSE
ORDER BY ump.last_played_at DESC;
```

### 查询待复习的生词
```sql
-- 获取今天需要复习的生词
SELECT word, pinyin, definition
FROM user_vocabulary
WHERE user_id = 'your-user-id'
  AND next_review_at <= NOW()
ORDER BY next_review_at;
```

### 使用视图查询媒体（带标签）
```sql
-- 直接使用预设视图
SELECT id, title, hsk_level, tags
FROM media_content_with_tags
WHERE hsk_level = 3
LIMIT 10;
```

---

## 🔄 内容生成时机设计

根据你的需求，设计了双模式支持：

### 模式一：添加时自动生成（推荐）
**流程**:
```
用户上传媒体 → 创建 media_content 记录（processing_status = 'pending'）
               ↓
         后台任务队列触发 AIGC
               ↓
         生成字幕（ASR → 分词 → 翻译）
               ↓
         更新 transcript 字段（processing_status = 'completed'）
```

**优点**: 用户无需等待，首次使用时内容已就绪  
**实现**: 使用 Supabase Edge Functions 或 Coze 工作流

### 模式二：使用时按需生成
**流程**:
```
用户点击播放 → 检查 processing_status
               ↓
         如果 = 'pending'，显示"正在生成字幕..."
               ↓
         触发 AIGC 任务，返回任务 ID
               ↓
         前端轮询任务状态，完成后刷新
```

**优点**: 节省计算资源，仅生成用户需要的内容  
**缺点**: 首次播放需等待

### 推荐方案
**Phase 1**: 模式二（降低成本，验证功能）  
**Phase 2**: 模式一（提升用户体验，引入任务队列）

---

## 📝 下一步开发任务

### Flutter 端实现
1. ✅ 创建数据模型类（`MediaContentModel`, `UserVocabularyModel` 等）
2. ✅ 实现 Supabase CRUD 服务（`MediaService`, `VocabularyService`）
3. ✅ 创建 Provider 管理状态（`MediaProvider`, `VocabularyProvider`）
4. ✅ 实现播客列表页面（带标签筛选）
5. ✅ 实现播放器页面（字幕同步、跟读录音）
6. ✅ 集成生词本功能

### 后端 AIGC 集成
1. ⚙️ 设计 ASR（语音转文字）服务（Whisper API 或 火山引擎）
2. ⚙️ 设计分词和拼音标注服务（已有 JiebaSegmenter）
3. ⚙️ 设计翻译服务（GPT-4 或专业翻译 API）
4. ⚙️ 创建 Supabase Edge Function 或 Coze 工作流编排

---

## 🐛 故障排查

### 常见问题

**Q1: 执行脚本时提示权限错误**  
A: 确保你的 Supabase 用户有 `CREATE TABLE` 权限，使用项目管理员账号登录

**Q2: RLS 策略导致无法查询数据**  
A: 检查 `auth.uid()` 是否返回正确的用户 ID，确保已登录

**Q3: 外键约束错误**  
A: 确保 `user_practices` 表已存在（生词本表引用了它），如未创建则先注释该外键

**Q4: JSONB 字段查询慢**  
A: 为 `transcript` 字段创建 GIN 索引：
```sql
CREATE INDEX idx_transcript_gin ON media_content USING GIN (transcript);
```

---

## 📧 技术支持

如有问题，请参考：
- Supabase 官方文档: https://supabase.com/docs
- ToneUp 项目文档: `docs/PROJECT_OVERVIEW.md`
- 播客功能设计: `docs/PODCAST_FEATURE_DESIGN.md`
