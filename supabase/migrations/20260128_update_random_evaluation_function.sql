-- =============================================
-- 更新 random_evaluation 函数以支持语言参数
-- 创建时间: 2026-01-28
-- 目的: 在评测题目查询中添加语言过滤
-- =============================================

-- 删除旧函数（如果存在）
DROP FUNCTION IF EXISTS research_core.random_evaluation(INT, INT);

-- 创建新函数，添加 lang_input 参数
CREATE OR REPLACE FUNCTION research_core.random_evaluation(
  level_input INT,
  n INT,
  lang_input lang DEFAULT 'en'::lang
) 
RETURNS SETOF research_core.evaluation AS $$
BEGIN
  RETURN QUERY
  SELECT *
  FROM research_core.evaluation
  WHERE level = level_input
    AND lang = lang_input
  ORDER BY RANDOM()
  LIMIT n;
END;
$$ LANGUAGE plpgsql;

-- 添加函数注释
COMMENT ON FUNCTION research_core.random_evaluation(INT, INT, lang) IS '随机获取指定等级和语言的评测题目';

-- 完成
