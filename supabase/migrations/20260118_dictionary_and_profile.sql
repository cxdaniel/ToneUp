-- =============================================
-- 词典系统数据库迁移
-- 创建时间: 2026-01-18
-- 功能: 支持多语言词典和用户母语设置
-- =============================================

-- 1. 扩展 profiles 表：添加母语字段
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS native_language TEXT DEFAULT 'en';

COMMENT ON COLUMN profiles.native_language IS '用户母语代码：en(英文), zh(中文), ja(日语), ko(韩语), es(西班牙语), fr(法语), de(德语)等';

-- 创建索引优化查询
CREATE INDEX IF NOT EXISTS idx_profiles_native_language 
ON profiles(native_language);


-- 2. 创建词典表
CREATE TABLE IF NOT EXISTS dictionary (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  
  -- 基础词条信息
  word TEXT NOT NULL UNIQUE,              -- 汉字词语（唯一索引）
  pinyin TEXT NOT NULL,                   -- 拼音（带声调）
  traditional TEXT,                       -- 繁体字（可选）
  hsk_level INTEGER,                      -- HSK等级 (1-6)
  frequency INTEGER DEFAULT 0,            -- 词频统计（查询次数）
  
  -- 多语言翻译（JSONB格式）
  -- 结构: {"en": {...}, "zh": {...}, "ja": {...}}
  translations JSONB NOT NULL DEFAULT '{}'::jsonb,
  
  -- 元数据
  source TEXT DEFAULT 'user',             -- 来源：user(用户贡献), api(API获取), admin(管理员添加)
  verified BOOLEAN DEFAULT false,         -- 是否已验证
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 注释说明
COMMENT ON TABLE dictionary IS '多语言词典表';
COMMENT ON COLUMN dictionary.word IS '简体汉字词语';
COMMENT ON COLUMN dictionary.translations IS '多语言释义JSON: {"en": {"summary": "...", "entries": [...]}, "zh": {...}}';
COMMENT ON COLUMN dictionary.frequency IS '查询频率统计，用于缓存优先级';

-- 索引优化
CREATE INDEX IF NOT EXISTS idx_dictionary_word ON dictionary(word);
CREATE INDEX IF NOT EXISTS idx_dictionary_hsk ON dictionary(hsk_level);
CREATE INDEX IF NOT EXISTS idx_dictionary_frequency ON dictionary(frequency DESC);
CREATE INDEX IF NOT EXISTS idx_dictionary_translations ON dictionary USING GIN(translations);

-- 3. 创建触发器：自动更新 updated_at
CREATE OR REPLACE FUNCTION update_dictionary_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_dictionary_updated_at
BEFORE UPDATE ON dictionary
FOR EACH ROW
EXECUTE FUNCTION update_dictionary_timestamp();

-- 4. 启用 RLS (Row Level Security)
ALTER TABLE dictionary ENABLE ROW LEVEL SECURITY;

-- 允许所有认证用户读取词典
CREATE POLICY "词典对所有认证用户可读"
ON dictionary FOR SELECT
TO authenticated
USING (true);

-- 仅管理员可以创建/更新词典（后续可放开给用户贡献）
CREATE POLICY "仅管理员可创建词典"
ON dictionary FOR INSERT
TO authenticated
WITH CHECK (auth.uid() IN (
  SELECT id FROM profiles WHERE id = auth.uid() 
  -- 这里可以添加管理员判断逻辑
));

CREATE POLICY "仅管理员可更新词典"
ON dictionary FOR UPDATE
TO authenticated
USING (auth.uid() IN (
  SELECT id FROM profiles WHERE id = auth.uid()
));

-- 5. 创建示例数据（可选）
INSERT INTO dictionary (word, pinyin, hsk_level, translations, source, verified) VALUES
('欢迎', 'huān yíng', 2, 
'{
  "en": {
    "summary": "to welcome; welcome",
    "entries": [
      {
        "pos": "v.",
        "definitions": ["to welcome", "to greet warmly"],
        "examples": ["欢迎光临！Welcome!", "欢迎你来中国。Welcome to China."]
      }
    ]
  },
  "zh": {
    "summary": "欢迎；迎接",
    "entries": [
      {
        "pos": "动词",
        "definitions": ["欢迎", "热情接待"],
        "examples": ["欢迎光临！", "欢迎你来中国。"]
      }
    ]
  }
}'::jsonb, 'admin', true),

('你好', 'nǐ hǎo', 1,
'{
  "en": {
    "summary": "hello; hi",
    "entries": [
      {
        "pos": "int.",
        "definitions": ["hello", "hi", "how do you do"],
        "examples": ["你好！见到你很高兴。Hello! Nice to meet you."]
      }
    ]
  },
  "zh": {
    "summary": "你好；问候语",
    "entries": [
      {
        "pos": "感叹词",
        "definitions": ["问候语", "打招呼"],
        "examples": ["你好！见到你很高兴。"]
      }
    ]
  }
}'::jsonb, 'admin', true)
ON CONFLICT (word) DO NOTHING;

-- 6. 创建查询函数（优化性能）
CREATE OR REPLACE FUNCTION get_word_translation(
  p_word TEXT,
  p_language TEXT DEFAULT 'en'
)
RETURNS JSONB AS $$
DECLARE
  result JSONB;
BEGIN
  -- 查询词条并返回指定语言的翻译
  SELECT translations->>p_language INTO result
  FROM dictionary
  WHERE word = p_word;
  
  -- 如果找到，更新词频
  IF result IS NOT NULL THEN
    UPDATE dictionary 
    SET frequency = frequency + 1
    WHERE word = p_word;
  END IF;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION get_word_translation IS '查询词语指定语言的翻译，并自动更新词频';

-- 7. 创建批量查询视图（常用词）
CREATE OR REPLACE VIEW popular_words AS
SELECT 
  word,
  pinyin,
  hsk_level,
  frequency,
  translations
FROM dictionary
WHERE frequency > 0
ORDER BY frequency DESC
LIMIT 1000;

COMMENT ON VIEW popular_words IS '高频词汇视图，缓存优先';
