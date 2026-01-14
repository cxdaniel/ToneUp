-- ============================================================================
-- ToneUp App - Current Supabase Database Schema
-- ============================================================================
-- 导出日期: 2026-01-11
-- 项目: kixonwnuivnjqlraydmz.supabase.co
-- 说明: 此 schema 用于理解现有数据库结构，不可直接执行（表顺序和约束可能无效）
-- ============================================================================

-- ============================================================================
-- SCHEMA: research_core
-- 用途: 静态研究数据和资源（汉字、词汇、语法、活动模板等）
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 活动模板表 (activities)
-- 用途: 定义可用的练习活动类型和配置
-- ----------------------------------------------------------------------------
CREATE TABLE research_core.activities (
  id integer NOT NULL DEFAULT nextval('research_core.activities_id_seq'::regclass),
  activity_title text NOT NULL,              -- 活动标题：看图识字、听音辨义
  quiz_type USER-DEFINED NOT NULL DEFAULT '选择题'::quiz_type, -- 题型枚举
  material_type ARRAY NOT NULL,              -- 素材类型数组：[character, word, sentence]
  time_cost integer DEFAULT 30,              -- 预计耗时（秒）
  created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
  indicator_cats ARRAY NOT NULL,             -- 关联的能力指标 ID 数组
  quiz_template USER-DEFINED,                -- 练习模板枚举：看文选文、听音选文等
  available smallint NOT NULL DEFAULT '0'::smallint, -- 是否可用：0=不可用, 1=可用
  CONSTRAINT activities_pkey PRIMARY KEY (id)
);

-- ----------------------------------------------------------------------------
-- 汉字表 (characters)
-- 用途: HSK 汉字库，包含部首和等级信息
-- ----------------------------------------------------------------------------
CREATE TABLE research_core.characters (
  id integer NOT NULL DEFAULT nextval('research_core.characters_id_seq'::regclass),
  char character varying NOT NULL UNIQUE,    -- 汉字：学
  radical character varying NOT NULL,        -- 部首：子
  level integer CHECK (level >= 1 AND level <= 10), -- HSK 等级
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT characters_pkey PRIMARY KEY (id)
);

-- ----------------------------------------------------------------------------
-- 音节表 (syllables)
-- 用途: 拼音音节库，包含声母韵母和声调
-- ----------------------------------------------------------------------------
CREATE TABLE research_core.syllables (
  id integer NOT NULL DEFAULT nextval('research_core.syllables_id_seq'::regclass),
  pinyin character varying NOT NULL UNIQUE,  -- 拼音：xué
  pinyin_without_tone character varying,     -- 无声调拼音：xue
  tone integer CHECK (tone >= 0 AND tone <= 4), -- 声调：0=轻声, 1-4=四声
  initial character varying,                 -- 声母：x
  final character varying,                   -- 韵母：ue
  level integer CHECK (level >= 1 AND level <= 10),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT syllables_pkey PRIMARY KEY (id)
);

-- ----------------------------------------------------------------------------
-- 汉字音节关联表 (character_syllables)
-- 用途: 多对多关系，一个汉字可能有多个读音
-- ----------------------------------------------------------------------------
CREATE TABLE research_core.character_syllables (
  character_id integer NOT NULL,
  syllable_id integer NOT NULL,
  is_primary boolean DEFAULT false,          -- 是否为主要读音
  CONSTRAINT character_syllables_pkey PRIMARY KEY (character_id, syllable_id),
  CONSTRAINT character_syllables_syllable_id_fkey FOREIGN KEY (syllable_id) REFERENCES research_core.syllables(id),
  CONSTRAINT character_syllables_character_id_fkey FOREIGN KEY (character_id) REFERENCES research_core.characters(id)
);

-- ----------------------------------------------------------------------------
-- 词汇表 (words)
-- 用途: HSK 词汇库
-- ----------------------------------------------------------------------------
CREATE TABLE research_core.words (
  id integer NOT NULL DEFAULT nextval('research_core.words_id_seq'::regclass),
  word character varying NOT NULL UNIQUE,    -- 词汇：学习
  part_of_speech character varying,          -- 词性：动词
  level integer CHECK (level >= 1 AND level <= 10),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT words_pkey PRIMARY KEY (id)
);

-- ----------------------------------------------------------------------------
-- 语法表 (grammars)
-- 用途: 中文语法点库
-- ----------------------------------------------------------------------------
CREATE TABLE research_core.grammars (
  id integer NOT NULL DEFAULT nextval('research_core.grammars_id_seq'::regclass),
  category character varying NOT NULL,       -- 语法类别：句型、时态
  sub_category character varying,            -- 子类别
  sub_sub_category character varying,        -- 子子类别
  rule_name character varying NOT NULL,      -- 语法点名称：把字句
  description text,                          -- 语法说明
  level integer CHECK (level >= 1 AND level <= 10),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT grammars_pkey PRIMARY KEY (id)
);

-- ----------------------------------------------------------------------------
-- 能力指标表 (indicators)
-- 用途: 15 维学习能力指标定义
-- ----------------------------------------------------------------------------
CREATE TABLE research_core.indicators (
  id integer NOT NULL DEFAULT nextval('research_core.indicators_id_seq'::regclass),
  indicator text NOT NULL,                   -- 指标名称：辨认汉字、听懂句子
  level integer NOT NULL CHECK (level >= 1 AND level <= 9), -- 指标难度等级
  category USER-DEFINED NOT NULL,            -- 指标类别枚举：charsRecognition, listening 等
  skill_group USER-DEFINED NOT NULL,         -- 技能组枚举：认、听、说、读、写、译
  weight numeric DEFAULT 1.0 CHECK (weight >= 0::numeric AND weight <= 1::numeric), -- 权重
  created_at timestamp without time zone DEFAULT now(),
  material_types ARRAY,                      -- 支持的素材类型
  minimum smallint DEFAULT '30'::smallint,   -- 最小练习量
  CONSTRAINT indicators_pkey PRIMARY KEY (id)
);

-- ----------------------------------------------------------------------------
-- 内容标签表 (content_tags)
-- 用途: 多维度内容标签系统（话题、文化等）
-- ----------------------------------------------------------------------------
CREATE TABLE research_core.content_tags (
  id smallint NOT NULL UNIQUE,
  tag text NOT NULL UNIQUE,                  -- 标签名称：春节、商务、旅游
  category text,                             -- 标签类别
  diff_level integer DEFAULT 0,              -- 难度等级
  tag_level integer DEFAULT 1,               -- 标签层级
  domain USER-DEFINED NOT NULL DEFAULT 'topic'::tag_domain, -- 标签域：topic/culture
  CONSTRAINT content_tags_pkey PRIMARY KEY (id)
);

-- ----------------------------------------------------------------------------
-- 评估题目表 (evaluation)
-- 用途: 能力评估测试题库
-- ----------------------------------------------------------------------------
CREATE TABLE research_core.evaluation (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc'::text),
  indicator_id integer,                      -- 关联指标 ID
  activity_id integer,                       -- 关联活动 ID
  level smallint DEFAULT '1'::smallint,      -- 题目难度等级
  stem jsonb,                                -- 题干数据（JSON）
  question text,                             -- 问题文本
  options jsonb,                             -- 选项数据（JSON）
  explain text,                              -- 答案解析
  CONSTRAINT evaluation_pkey PRIMARY KEY (id),
  CONSTRAINT evaluation_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES research_core.indicators(id),
  CONSTRAINT evaluation_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES research_core.activities(id)
);

-- ----------------------------------------------------------------------------
-- 汉字拼音映射表 (char_pinyin)
-- 用途: 快速查询汉字对应的拼音
-- ----------------------------------------------------------------------------
CREATE TABLE research_core.char_pinyin (
  char text,                                 -- 汉字
  pinyin text                                -- 拼音
);

-- ============================================================================
-- SCHEMA: public
-- 用途: 用户数据和应用业务逻辑
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 用户档案表 (profiles)
-- 用途: 存储用户基础信息和学习统计数据
-- ----------------------------------------------------------------------------
CREATE TABLE public.profiles (
  id uuid NOT NULL,                          -- 用户 UUID（引用 auth.users）
  nickname text,                             -- 昵称
  level smallint DEFAULT 1,                  -- 当前 HSK 等级
  streak_days smallint DEFAULT '0'::smallint, -- 连续学习天数
  words integer DEFAULT 0,                   -- 学过词汇数
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now(),
  plan_duration_minutes integer DEFAULT 50,  -- 每日学习时长偏好（分钟）
  exp smallint DEFAULT '0'::smallint,        -- 经验值
  sentences integer DEFAULT 0,               -- 学过句子数
  grammars integer DEFAULT 0,                -- 学过语法点数
  plans smallint DEFAULT '0'::smallint,      -- 完成计划数
  practices integer DEFAULT 0,               -- 完成练习数
  characters smallint DEFAULT '0'::smallint, -- 学过汉字数
  purpose USER-DEFINED,                      -- 学习目的枚举：interest/work/travel/exam/life
  avatar text,                               -- 头像 URL
  deleted_at timestamp with time zone,       -- 软删除时间
  email text,                                -- 邮箱
  CONSTRAINT profiles_pkey PRIMARY KEY (id),
  CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id)
);

-- ----------------------------------------------------------------------------
-- 订阅管理表 (subscriptions)
-- 用途: 用户订阅状态，与 RevenueCat 同步
-- ----------------------------------------------------------------------------
CREATE TABLE public.subscriptions (
  id uuid NOT NULL DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL UNIQUE,
  revenue_cat_customer_id text UNIQUE,       -- RevenueCat 客户 ID
  revenue_cat_entitlement_id text,           -- RevenueCat 权益 ID
  status text NOT NULL DEFAULT 'free'::text, -- 订阅状态：free/trial/active/cancelled/expired
  tier text,                                 -- 订阅层级：monthly/yearly/lifetime
  trial_start_at timestamp with time zone,   -- 试用开始时间
  trial_end_at timestamp with time zone,     -- 试用结束时间
  subscription_start_at timestamp with time zone,
  subscription_end_at timestamp with time zone,
  cancelled_at timestamp with time zone,
  platform text,                             -- 平台：ios/android/web
  product_id text,                           -- 产品 ID
  created_at timestamp with time zone DEFAULT now(),
  updated_at timestamp with time zone DEFAULT now(),
  CONSTRAINT subscriptions_pkey PRIMARY KEY (id),
  CONSTRAINT subscriptions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- ----------------------------------------------------------------------------
-- 用户学习材料表 (user_materials)
-- 用途: 存储每周学习计划生成的学习材料快照
-- ----------------------------------------------------------------------------
CREATE TABLE public.user_materials (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL UNIQUE, -- ⚠️ 主键为 bigint
  created_at timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc'::text),
  user_id uuid,
  level integer,                             -- HSK 等级
  chars jsonb,                               -- 汉字数组（JSON）
  chars_review jsonb,                        -- 复习汉字数组
  words jsonb,                               -- 词汇数组（JSON）
  words_review jsonb,                        -- 复习词汇数组
  syllables jsonb,                           -- 音节数组（JSON）
  grammars jsonb,                            -- 语法数组（JSON）
  sentences jsonb,                           -- 句子数组（JSON）
  dialogs jsonb,                             -- 对话数组（JSON）
  paragraphs jsonb,                          -- 段落数组（JSON）
  topic_title text,                          -- 主题标题
  topic_tag text,                            -- ⚠️ 话题标签（TEXT 类型，不是 INTEGER）
  culture_tag text,                          -- ⚠️ 文化标签（TEXT 类型）
  deleted_at timestamp with time zone,       -- 软删除时间
  CONSTRAINT user_materials_pkey PRIMARY KEY (id),
  CONSTRAINT user_materials_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- ----------------------------------------------------------------------------
-- 用户学习计划表 (user_weekly_plans)
-- 用途: 每周学习计划，包含目标指标和练习
-- ----------------------------------------------------------------------------
CREATE TABLE public.user_weekly_plans (
  id bigint NOT NULL DEFAULT nextval('user_weekly_plans_id_seq'::regclass), -- ⚠️ bigint
  user_id uuid NOT NULL,
  start_date date NOT NULL,                  -- 计划开始日期
  end_date date,                             -- 计划结束日期
  target_indicators ARRAY,                   -- 目标指标 ID 数组
  progress numeric DEFAULT 0,                -- 完成进度（0-1）
  status text DEFAULT 'active'::text,        -- 计划状态：active/pending/done/reactive
  created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
  material_snapshot jsonb,                   -- 学习材料快照（JSON）
  target_material bigint,                    -- 关联的 user_materials.id
  topic_title text,                          -- 主题标题
  level integer,                             -- HSK 等级
  practices ARRAY,                           -- 练习 ID 数组
  deleted_at timestamp with time zone,       -- 软删除时间
  CONSTRAINT user_weekly_plans_pkey PRIMARY KEY (id),
  CONSTRAINT user_weekly_plans_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT user_weekly_plans_target_material_fkey FOREIGN KEY (target_material) REFERENCES public.user_materials(id)
);

-- ----------------------------------------------------------------------------
-- 用户练习记录表 (user_practices)
-- 用途: 记录用户完成的练习活动
-- ----------------------------------------------------------------------------
CREATE TABLE public.user_practices (
  id bigint NOT NULL DEFAULT nextval('user_activity_results_id_seq'::regclass), -- ⚠️ bigint
  quizes ARRAY NOT NULL,                     -- 题目 ID 数组
  score numeric CHECK (score >= 0::numeric AND score <= 1::numeric), -- 得分（0-1）
  created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
  count integer DEFAULT 0,                   -- 练习次数
  update_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
  status smallint DEFAULT '0'::smallint,     -- 状态：0=未开始, 1=进行中, 2=已完成
  deleted_at timestamp with time zone,       -- 软删除时间
  CONSTRAINT user_practices_pkey PRIMARY KEY (id)
);

-- ----------------------------------------------------------------------------
-- 题目表 (quizes)
-- 用途: 练习题目库（动态生成或预设）
-- ----------------------------------------------------------------------------
CREATE TABLE public.quizes (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc'::text),
  indicator_id integer,                      -- 关联指标 ID
  activity_id integer,                       -- 关联活动 ID
  level smallint,                            -- 题目难度等级
  topic_tag text,                            -- ⚠️ 话题标签（TEXT）
  material text,                             -- 素材内容
  material_type USER-DEFINED,                -- 素材类型枚举
  stem jsonb,                                -- 题干数据（JSON）
  question text,                             -- 问题文本
  options jsonb,                             -- 选项数据（JSON）
  explain text,                              -- 答案解析
  culture_tag text,                          -- ⚠️ 文化标签（TEXT）
  deleted_at timestamp with time zone,       -- 软删除时间
  CONSTRAINT quizes_pkey PRIMARY KEY (id),
  CONSTRAINT quizes_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES research_core.activities(id),
  CONSTRAINT quizes_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES research_core.indicators(id)
);

-- ----------------------------------------------------------------------------
-- 用户能力历史表 (user_ability_history)
-- 用途: 追踪用户各项能力指标的变化历史
-- ----------------------------------------------------------------------------
CREATE TABLE public.user_ability_history (
  id bigint NOT NULL DEFAULT nextval('user_ability_history_id_seq'::regclass),
  user_id uuid NOT NULL,
  indicator_id integer NOT NULL,             -- 能力指标 ID
  score numeric NOT NULL CHECK (score >= 0::numeric AND score <= 1::numeric), -- 评分
  created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
  CONSTRAINT user_ability_history_pkey PRIMARY KEY (id),
  CONSTRAINT user_ability_history_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id),
  CONSTRAINT user_ability_history_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES research_core.indicators(id)
);

-- ----------------------------------------------------------------------------
-- 用户活动实例表 (user_activity_instances)
-- 用途: 记录生成的活动实例（材料 + 题目）
-- ----------------------------------------------------------------------------
CREATE TABLE public.user_activity_instances (
  id bigint NOT NULL DEFAULT nextval('user_activity_instances_id_seq'::regclass),
  activity_id integer NOT NULL,
  indicator_id integer,
  materials jsonb,                           -- 活动使用的材料（JSON）
  created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
  quiz jsonb,                                -- 生成的题目（JSON）
  CONSTRAINT user_activity_instances_pkey PRIMARY KEY (id),
  CONSTRAINT user_activity_instances_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES research_core.activities(id),
  CONSTRAINT user_activity_instances_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES research_core.indicators(id)
);

-- ----------------------------------------------------------------------------
-- 用户事件记录表 (user_event_records)
-- 用途: 记录用户操作事件（用于分析和统计）
-- ----------------------------------------------------------------------------
CREATE TABLE public.user_event_records (
  id bigint NOT NULL DEFAULT nextval('user_events_id_seq'::regclass),
  user_id uuid NOT NULL,
  category USER-DEFINED NOT NULL DEFAULT 'activity_record'::event_category, -- 事件类别枚举
  event_title text,                          -- 事件标题
  event_detail jsonb DEFAULT '{}'::jsonb,    -- 事件详情（JSON）
  created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
  CONSTRAINT user_event_records_pkey PRIMARY KEY (id),
  CONSTRAINT user_event_records_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- ----------------------------------------------------------------------------
-- 用户分数记录表 (user_score_records)
-- 用途: 记录各类评分和成绩
-- ----------------------------------------------------------------------------
CREATE TABLE public.user_score_records (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc'::text),
  category text NOT NULL,                    -- 分类
  item text,                                 -- 评分项目
  score numeric,                             -- 分数
  user_id uuid NOT NULL,
  CONSTRAINT user_score_records_pkey PRIMARY KEY (id),
  CONSTRAINT user_score_records_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id)
);

-- ============================================================================
-- 关键设计规范总结
-- ============================================================================

-- 【主键类型】
-- - research_core 表: integer (序列生成)
-- - public 用户数据表: bigint 或 uuid
-- - user_materials.id: bigint GENERATED ALWAYS AS IDENTITY
-- - user_practices.id: bigint
-- - user_weekly_plans.id: bigint

-- 【标签系统】
-- - content_tags 表: id (smallint), tag (text), domain (USER-DEFINED: topic/culture)
-- - user_materials 使用: topic_tag (text), culture_tag (text) - 存储标签名称而非 ID
-- - quizes 使用: topic_tag (text), culture_tag (text)

-- 【枚举类型 (USER-DEFINED)】
-- - quiz_type: 选择题、配对题、选择填空、选词拼句、复述录音、汉字描红、文本输入
-- - quiz_template: 看文选文、看文选音、听音选文、左右配对、多项填多空、连词成句、复述例句、描红写字、键盘输入
-- - material_type: character, word, sentence, dialog, paragraph, syllable, grammar
-- - indicator_category: 15 种能力指标（辨认汉字、听懂句子等）
-- - skill_group: 认、听、说、读、写、译
-- - tag_domain: topic, culture
-- - event_category: activity_record 等
-- - purpose: interest, work, travel, exam, life

-- 【软删除】
-- - 多个表使用 deleted_at 字段实现软删除
-- - 查询时需过滤 WHERE deleted_at IS NULL

-- 【JSONB 字段使用】
-- - user_materials: chars, words, syllables, grammars, sentences, dialogs, paragraphs
-- - user_weekly_plans: material_snapshot
-- - quizes/evaluation: stem, options
-- - user_activity_instances: materials, quiz
-- - user_event_records: event_detail
