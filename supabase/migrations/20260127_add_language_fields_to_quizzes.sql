-- =============================================
-- 为练习题和测评题添加语言字段支持
-- 创建时间: 2026-01-27
-- 目的: 支持多语言题目生成和存储
-- =============================================

-- 1. 为 public.quizes 表添加 lang 字段（使用 enum 类型）
-- 先删除旧的 lang 列（如果存在）
ALTER TABLE public.quizes 
DROP COLUMN IF EXISTS lang;

-- 重新添加 lang 列（enum 类型，默认值 'en'）
ALTER TABLE public.quizes 
ADD COLUMN lang lang DEFAULT 'en'::lang NOT NULL;

-- 添加索引优化查询性能
CREATE INDEX IF NOT EXISTS idx_quizes_lang 
ON public.quizes(lang);

-- 添加列注释
COMMENT ON COLUMN public.quizes.lang IS '题目语言代码：对应用户的 ProfileModel.nativeLanguage';

-- 2. 为 research_core.evaluation 表添加 lang 字段（使用 enum 类型）
-- 先删除旧的 lang 列（如果存在）
ALTER TABLE research_core.evaluation 
DROP COLUMN IF EXISTS lang;

-- 重新添加 lang 列（enum 类型，默认值 'en'）
ALTER TABLE research_core.evaluation 
ADD COLUMN lang lang DEFAULT 'en'::lang NOT NULL;

-- 添加索引
CREATE INDEX IF NOT EXISTS idx_evaluation_lang 
ON research_core.evaluation(lang);

-- 添加列注释
COMMENT ON COLUMN research_core.evaluation.lang IS '测评题语言代码：对应用户的 ProfileModel.nativeLanguage，用于生成用户母语的测评题目';

-- 3. 为 public.user_practices 表添加 lang 字段（使用 enum 类型）
-- 先删除旧的 lang 列（如果存在）
ALTER TABLE public.user_practices 
DROP COLUMN IF EXISTS lang;

-- 重新添加 lang 列（enum 类型，默认值 'en'）
ALTER TABLE public.user_practices 
ADD COLUMN lang lang DEFAULT 'en'::lang NOT NULL;

-- 添加索引（用于统计分析）
CREATE INDEX IF NOT EXISTS idx_user_practices_lang 
ON public.user_practices(lang);

-- 添加列注释
COMMENT ON COLUMN public.user_practices.lang IS '练习时使用的语言（记录历史状态，用于数据分析和学习效果评估）';

-- 4. 数据验证（输出统计信息）
DO $$
DECLARE
  quizes_count INTEGER;
  evaluation_count INTEGER;
  practices_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO quizes_count FROM public.quizes;
  SELECT COUNT(*) INTO evaluation_count FROM research_core.evaluation;
  SELECT COUNT(*) INTO practices_count FROM public.user_practices;
  
  RAISE NOTICE '数据库迁移完成统计:';
  RAISE NOTICE '- public.quizes 表总记录数: %', quizes_count;
  RAISE NOTICE '- research_core.evaluation 表总记录数: %', evaluation_count;
  RAISE NOTICE '- public.user_practices 表总记录数: %', practices_count;
  RAISE NOTICE '所有现有记录的 lang 字段已设为 "en"';
END $$;

-- 完成
