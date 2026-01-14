-- ============================================
-- Migration: 添加字级别时间信息字段
-- 功能: 为media_content表添加word_timings字段，用于存储字级别的时间戳信息
-- 格式: 紧凑数组 {"segmentId": [["字", startMs], ...]}
-- 日期: 2026-01-12
-- ============================================

-- 添加word_timings字段
ALTER TABLE media_content 
ADD COLUMN IF NOT EXISTS word_timings JSONB;

-- 添加注释
COMMENT ON COLUMN media_content.word_timings IS '字级别时间信息，用于播放器字幕高亮同步。格式: {"1": [["今", 160], ["天", 320]], "2": [...]}';

-- 创建GIN索引以优化JSONB查询性能
CREATE INDEX IF NOT EXISTS idx_media_content_word_timings 
ON media_content USING GIN (word_timings);

-- 验证更新
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'media_content' AND column_name = 'word_timings';
