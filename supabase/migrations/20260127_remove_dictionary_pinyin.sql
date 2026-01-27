-- =============================================
-- 删除 dictionary 表的 pinyin 字段
-- 创建时间: 2026-01-27
-- 原因: 多音字导致拼音已迁移到 translations 内部
-- =============================================

-- 1. 删除依赖 pinyin 字段的视图 popular_words
DROP VIEW IF EXISTS popular_words;

-- 2. 重建 popular_words 视图（不包含 pinyin 字段）
CREATE OR REPLACE VIEW popular_words AS
SELECT 
  word,
  hsk_level,
  frequency,
  translations
FROM dictionary
WHERE frequency > 0
ORDER BY frequency DESC
LIMIT 1000;

COMMENT ON VIEW popular_words IS '高频词汇视图（已移除pinyin字段，拼音现存储在translations内）';

-- 3. 删除 dictionary 表的 pinyin 字段
ALTER TABLE dictionary 
DROP COLUMN IF EXISTS pinyin;

-- 4. 验证数据完整性（可选，用于测试）
-- 检查 translations 中是否包含拼音信息
DO $$
DECLARE
  total_count INTEGER;
  with_pinyin_count INTEGER;
BEGIN
  -- 统计总词条数
  SELECT COUNT(*) INTO total_count FROM dictionary;
  
  -- 统计包含拼音信息的词条数（检查任意语言的 entries 是否有 pinyin 字段）
  SELECT COUNT(*) INTO with_pinyin_count
  FROM dictionary
  WHERE EXISTS (
    SELECT 1
    FROM jsonb_each(translations) AS t(lang, data)
    WHERE jsonb_typeof(data -> 'entries') = 'array'
      AND EXISTS (
        SELECT 1
        FROM jsonb_array_elements(data -> 'entries') AS entry
        WHERE entry ? 'pinyin'
      )
  );
  
  RAISE NOTICE '词典总词条数: %', total_count;
  RAISE NOTICE '包含拼音信息的词条数: %', with_pinyin_count;
  
  IF total_count > 0 AND with_pinyin_count = 0 THEN
    RAISE WARNING '⚠️ 警告: 所有词条的 translations 中都没有 pinyin 字段！';
    RAISE WARNING '建议检查数据迁移是否正确完成';
  END IF;
END $$;

-- 5. 更新相关注释
COMMENT ON TABLE dictionary IS '多语言词典表（拼音存储在 translations.{lang}.entries[].pinyin）';
COMMENT ON COLUMN dictionary.translations IS '多语言释义JSON: {"en": {"summary": "...", "entries": [{"pinyin": "...", "pos": "...", ...}]}, "zh": {...}}';

-- 完成
