-- ============================================================================
-- ToneUp App - Podcast Feature Database Migration
-- ============================================================================
-- Version: 1.0
-- Date: 2026-01-11
-- Description: 创建播客学习功能所需的数据表
-- ============================================================================

-- ============================================================================
-- 注意：播客功能复用现有的 research_core.content_tags 表
-- ============================================================================
-- content_tags 表已存在于 research_core schema，包含以下字段：
-- - id (smallint): 标签 ID
-- - tag (text): 标签名称
-- - category (text): 分类
-- - domain (tag_domain): 'topic' | 'culture'
-- - diff_level (integer): 难度等级
-- 
-- 播客内容将使用 topic_tag 和 culture_tag (TEXT 类型) 存储标签名称
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. 媒体内容主表 (media_content)
-- 用途：存储播客、视频等学习媒体的核心信息
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS media_content (
  id BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,  -- ⚠️ 使用 bigint 保持与其他表一致
  
  -- 基础信息
  title TEXT NOT NULL,                    -- 标题：春节习俗介绍
  description TEXT,                       -- 简介/摘要
  cover_image_url TEXT,                   -- 封面图 URL
  
  -- 媒体类型
  content_type TEXT NOT NULL CHECK (content_type IN ('audio', 'video')),
  source_type TEXT NOT NULL CHECK (source_type IN ('upload', 'youtube', 'bilibili', 'aigc')),
  
  -- 媒体资源
  media_url TEXT NOT NULL,                -- Supabase Storage 路径或外部 URL
  external_id TEXT,                       -- YouTube/Bilibili 视频ID
  duration_seconds INTEGER,               -- 时长（秒）
  
  -- 学习数据
  hsk_level INTEGER CHECK (hsk_level BETWEEN 1 AND 6), -- HSK等级 1-6
  difficulty_score FLOAT CHECK (difficulty_score BETWEEN 0 AND 100), -- 难度系数
  vocabulary_list TEXT[],                 -- 核心词汇数组 ['春节', '习俗']
  
  -- 标签（TEXT 类型，存储标签名称）
  topic_tag TEXT,                         -- 话题标签：日常生活、商务职场
  culture_tag TEXT,                       -- 文化标签：传统节日、历史人物
  
  -- 能力指标关联
  indicator_cats INTEGER[],               -- 关联的能力指标 ID 数组（如：[4, 5] 对应 listening, listeningSpeed）
  
  -- 字幕数据 (JSONB格式)
  transcript JSONB,                       -- 完整字幕，结构见下方注释
  
  -- AIGC 处理状态
  processing_status TEXT DEFAULT 'pending' CHECK (
    processing_status IN ('pending', 'processing', 'completed', 'failed')
  ),
  processing_error TEXT,                  -- 错误信息
  processed_at TIMESTAMP WITH TIME ZONE,  -- 处理完成时间
  
  -- 审核状态 (UGC内容)
  review_status TEXT DEFAULT 'approved' CHECK (
    review_status IN ('pending', 'approved', 'rejected')
  ),
  reviewed_by UUID REFERENCES auth.users(id),
  reviewed_at TIMESTAMP WITH TIME ZONE,
  rejection_reason TEXT,
  
  -- 统计数据
  view_count INTEGER DEFAULT 0,
  like_count INTEGER DEFAULT 0,
  bookmark_count INTEGER DEFAULT 0,
  
  -- 上传者信息
  uploaded_by UUID REFERENCES auth.users(id),
  
  -- 软删除
  deleted_at TIMESTAMP WITH TIME ZONE,    -- ⚠️ 添加软删除支持
  
  -- 元数据
  created_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'utc'::text),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'utc'::text),
  
  CONSTRAINT media_content_pkey PRIMARY KEY (id)
);

-- 索引
CREATE INDEX idx_media_hsk_level ON media_content(hsk_level);
CREATE INDEX idx_media_processing_status ON media_content(processing_status);
CREATE INDEX idx_media_review_status ON media_content(review_status);
CREATE INDEX idx_media_uploaded_by ON media_content(uploaded_by);
CREATE INDEX idx_media_created_at ON media_content(created_at DESC);

COMMENT ON TABLE media_content IS '播客/视频媒体内容主表';
COMMENT ON COLUMN media_content.transcript IS 'JSON格式字幕数据：{"segments": [{"id": 0, "start": 0.5, "end": 3.2, "text": "大家好", "pinyin": "dà jiā hǎo", "translation": "Hello everyone", "keywords": ["大家"]}]}';
COMMENT ON COLUMN media_content.processing_status IS '内容处理状态：pending=待处理, processing=处理中, completed=已完成, failed=失败';
COMMENT ON COLUMN media_content.source_type IS '来源类型：upload=本地上传, youtube=YouTube链接, bilibili=B站链接, aigc=AI生成';

-- 更新时间触发器
CREATE OR REPLACE FUNCTION update_media_content_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_media_content_updated_at
  BEFORE UPDATE ON media_content
  FOR EACH ROW
  EXECUTE FUNCTION update_media_content_updated_at();

-- ============================================================================
-- 注意：移除 media_content_tags 关联表
-- ============================================================================
-- 播客内容使用 media_content.topic_tag 和 media_content.culture_tag (TEXT)
-- 与现有的 user_materials 和 quizes 表保持一致的标签使用方式
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2. 用户学习进度表 (user_media_progress)
-- 用途：记录用户观看播客的进度、跟读练习、保存的生词
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_media_progress (
  id BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,  -- ⚠️ bigint 主键
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  media_id BIGINT NOT NULL REFERENCES media_content(id) ON DELETE CASCADE,  -- ⚠️ 引用 bigint
  
  -- 播放进度
  playback_position FLOAT DEFAULT 0,      -- 当前播放位置（秒）⚠️ 避免使用保留关键字 current_time
  completed BOOLEAN DEFAULT FALSE,        -- 是否完成
  completion_rate FLOAT DEFAULT 0 CHECK (completion_rate BETWEEN 0 AND 1), -- 完成率
  
  -- 学习统计
  play_count INTEGER DEFAULT 0,           -- 播放次数
  total_watch_time FLOAT DEFAULT 0,       -- 累计观看时长（秒）
  last_played_at TIMESTAMP,
  
  -- 跟读练习数据
  shadowing_attempts INTEGER DEFAULT 0,   -- 跟读次数
  shadowing_scores FLOAT[],               -- 每次跟读得分数组
  average_shadowing_score FLOAT,          -- 平均跟读得分
  
  -- 收藏状态
  is_bookmarked BOOLEAN DEFAULT FALSE,
  bookmarked_at TIMESTAMP,
  
  -- 软删除
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  -- 元数据
  created_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'utc'::text),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'utc'::text),
  
  CONSTRAINT user_media_progress_pkey PRIMARY KEY (id),
  UNIQUE(user_id, media_id)
);

-- 索引
CREATE INDEX idx_progress_user ON user_media_progress(user_id);
CREATE INDEX idx_progress_media ON user_media_progress(media_id);
CREATE INDEX idx_progress_bookmarked ON user_media_progress(user_id, is_bookmarked) WHERE is_bookmarked = TRUE;
CREATE INDEX idx_progress_last_played ON user_media_progress(user_id, last_played_at DESC);
CREATE INDEX idx_progress_completion ON user_media_progress(user_id, completed);

COMMENT ON TABLE user_media_progress IS '用户播客学习进度记录表';

-- 更新时间触发器
CREATE TRIGGER trigger_update_user_media_progress_updated_at
  BEFORE UPDATE ON user_media_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_media_content_updated_at();

-- ----------------------------------------------------------------------------
-- 3. 用户生词本表 (user_vocabulary)
-- 用途：全局生词本，支持播客学习和练习模块添加生词
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_vocabulary (
  id BIGINT GENERATED ALWAYS AS IDENTITY NOT NULL,  -- ⚠️ bigint 主键
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- 词汇信息
  word TEXT NOT NULL,                     -- 词汇：学习
  pinyin TEXT,                            -- 拼音：xué xí
  definition TEXT,                        -- 释义：to study, to learn
  example_sentence TEXT,                  -- 例句：我爱学习中文
  example_translation TEXT,               -- 例句翻译
  
  -- 来源追溯
  source_type TEXT NOT NULL CHECK (source_type IN ('media', 'practice', 'manual')),
  source_media_id BIGINT REFERENCES media_content(id) ON DELETE SET NULL,  -- ⚠️ bigint 引用
  source_practice_id BIGINT REFERENCES user_practices(id) ON DELETE SET NULL,  -- ⚠️ bigint 引用
  source_context TEXT,                    -- 原句上下文
  
  -- 复习数据
  review_count INTEGER DEFAULT 0,
  last_reviewed_at TIMESTAMP,
  next_review_at TIMESTAMP,               -- 间隔重复算法计算的下次复习时间
  mastery_level INTEGER DEFAULT 0 CHECK (mastery_level BETWEEN 0 AND 5), -- 掌握程度
  
  -- 标记
  is_starred BOOLEAN DEFAULT FALSE,       -- 重点标记
  notes TEXT,                             -- 用户笔记
  
  -- 软删除
  deleted_at TIMESTAMP WITH TIME ZONE,
  
  -- 元数据
  created_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'utc'::text),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT (now() AT TIME ZONE 'utc'::text),
  
  CONSTRAINT user_vocabulary_pkey PRIMARY KEY (id),
  UNIQUE(user_id, word)
);

-- 索引
CREATE INDEX idx_vocab_user ON user_vocabulary(user_id);
CREATE INDEX idx_vocab_source_media ON user_vocabulary(source_media_id) WHERE source_media_id IS NOT NULL;
CREATE INDEX idx_vocab_next_review ON user_vocabulary(user_id, next_review_at) WHERE next_review_at IS NOT NULL;
CREATE INDEX idx_vocab_mastery ON user_vocabulary(user_id, mastery_level);
CREATE INDEX idx_vocab_starred ON user_vocabulary(user_id, is_starred) WHERE is_starred = TRUE;

COMMENT ON TABLE user_vocabulary IS '用户全局生词本，支持播客和练习模块';
COMMENT ON COLUMN user_vocabulary.source_type IS '来源类型：media=播客媒体, practice=练习模块, manual=手动添加';
COMMENT ON COLUMN user_vocabulary.mastery_level IS '掌握程度：0=未学, 1=认识, 2=熟悉, 3=掌握, 4=熟练, 5=精通';

-- 更新时间触发器
CREATE TRIGGER trigger_update_user_vocabulary_updated_at
  BEFORE UPDATE ON user_vocabulary
  FOR EACH ROW
  EXECUTE FUNCTION update_media_content_updated_at();

-- ============================================================================
-- Row Level Security (RLS) 策略
-- ============================================================================

-- 启用 RLS
ALTER TABLE media_content ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_media_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_vocabulary ENABLE ROW LEVEL SECURITY;

-- ----------------------------------------------------------------------------
-- media_content RLS 策略
-- ----------------------------------------------------------------------------
-- 所有人可查看已审核通过的内容
CREATE POLICY "Anyone can view approved media"
  ON media_content FOR SELECT
  USING (review_status = 'approved');

-- 上传者可查看自己上传的内容（包括待审核）
CREATE POLICY "Users can view own uploads"
  ON media_content FOR SELECT
  USING (auth.uid() = uploaded_by);

-- 认证用户可上传媒体
CREATE POLICY "Authenticated users can upload media"
  ON media_content FOR INSERT
  WITH CHECK (auth.uid() = uploaded_by);

-- 上传者可更新自己的媒体（仅限待审核状态）
CREATE POLICY "Users can update own pending media"
  ON media_content FOR UPDATE
  USING (auth.uid() = uploaded_by AND review_status = 'pending')
  WITH CHECK (auth.uid() = uploaded_by);

-- 上传者可删除自己的媒体
CREATE POLICY "Users can delete own media"
  ON media_content FOR DELETE
  USING (auth.uid() = uploaded_by);



-- ----------------------------------------------------------------------------
-- user_media_progress RLS 策略
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view own progress"
  ON user_media_progress FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own progress"
  ON user_media_progress FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress"
  ON user_media_progress FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own progress"
  ON user_media_progress FOR DELETE
  USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- user_vocabulary RLS 策略
-- ----------------------------------------------------------------------------
CREATE POLICY "Users can view own vocabulary"
  ON user_vocabulary FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create own vocabulary"
  ON user_vocabulary FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own vocabulary"
  ON user_vocabulary FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own vocabulary"
  ON user_vocabulary FOR DELETE
  USING (auth.uid() = user_id);



-- ============================================================================
-- 辅助视图和函数
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 视图：已审核的媒体内容列表
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW approved_media_content AS
SELECT *
FROM media_content
WHERE review_status = 'approved'
  AND deleted_at IS NULL;

COMMENT ON VIEW approved_media_content IS '已审核通过且未删除的媒体内容列表';

-- ----------------------------------------------------------------------------
-- 函数：更新媒体统计数据
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION increment_media_view_count(media_uuid UUID)
RETURNS void AS $$
BEGIN
  UPDATE media_content
  SET view_count = view_count + 1
  WHERE id = media_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_media_like_count(media_uuid UUID)
RETURNS void AS $$
BEGIN
  UPDATE media_content
  SET like_count = like_count + 1
  WHERE id = media_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION increment_media_bookmark_count(media_uuid UUID, increment_value INTEGER)
RETURNS void AS $$
BEGIN
  UPDATE media_content
  SET bookmark_count = GREATEST(0, bookmark_count + increment_value)
  WHERE id = media_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 初始化示例数据（可选，测试用）
-- ============================================================================

-- 插入示例媒体内容（需要先有 auth.users 数据）
-- INSERT INTO media_content (
--   title, description, content_type, source_type, media_url, 
--   hsk_level, difficulty_score, duration_seconds,
--   transcript, processing_status, review_status
-- ) VALUES (
--   '春节习俗介绍',
--   '通过视频了解中国传统节日春节的各种习俗',
--   'video',
--   'upload',
--   'media/podcasts/spring-festival-intro.mp4',
--   3,
--   45.5,
--   180,
--   '{"segments": [{"id": 0, "start": 0, "end": 5, "text": "大家好，今天我们来聊聊春节。", "pinyin": "dà jiā hǎo, jīn tiān wǒ men lái liáo liao chūn jié.", "translation": "Hello everyone, today we will talk about Spring Festival.", "keywords": ["春节"]}]}'::jsonb,
--   'completed',
--   'approved'
-- );

COMMENT ON SCHEMA public IS 'ToneUp App - Podcast Feature Tables Created on 2026-01-11';
