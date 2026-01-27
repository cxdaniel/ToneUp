-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE research_core.activities (
  id integer NOT NULL DEFAULT nextval('research_core.activities_id_seq'::regclass),
  activity_title text NOT NULL,
  quiz_type USER-DEFINED NOT NULL DEFAULT '选择题'::quiz_type,
  material_type ARRAY NOT NULL,
  time_cost integer DEFAULT 30,
  created_at timestamp with time zone DEFAULT (now() AT TIME ZONE 'utc'::text),
  indicator_cats ARRAY NOT NULL,
  quiz_template USER-DEFINED,
  available smallint NOT NULL DEFAULT '0'::smallint,
  CONSTRAINT activities_pkey PRIMARY KEY (id)
);
CREATE TABLE research_core.char_pinyin (
  char text,
  pinyin text
);
CREATE TABLE research_core.character_syllables (
  character_id integer NOT NULL,
  syllable_id integer NOT NULL,
  is_primary boolean DEFAULT false,
  CONSTRAINT character_syllables_pkey PRIMARY KEY (character_id, syllable_id),
  CONSTRAINT character_syllables_syllable_id_fkey FOREIGN KEY (syllable_id) REFERENCES research_core.syllables(id),
  CONSTRAINT character_syllables_character_id_fkey FOREIGN KEY (character_id) REFERENCES research_core.characters(id)
);
CREATE TABLE research_core.characters (
  id integer NOT NULL DEFAULT nextval('research_core.characters_id_seq'::regclass),
  char character varying NOT NULL UNIQUE,
  radical character varying NOT NULL,
  level integer CHECK (level >= 1 AND level <= 10),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT characters_pkey PRIMARY KEY (id)
);
CREATE TABLE research_core.content_tags (
  id smallint NOT NULL UNIQUE,
  tag text NOT NULL UNIQUE,
  category text,
  diff_level integer DEFAULT 0,
  tag_level integer DEFAULT 1,
  domain USER-DEFINED NOT NULL DEFAULT 'topic'::tag_domain,
  CONSTRAINT content_tags_pkey PRIMARY KEY (id)
);
CREATE TABLE research_core.evaluation (
  id bigint GENERATED ALWAYS AS IDENTITY NOT NULL,
  created_at timestamp with time zone NOT NULL DEFAULT (now() AT TIME ZONE 'utc'::text),
  indicator_id integer,
  activity_id integer,
  level smallint DEFAULT '1'::smallint,
  stem jsonb,
  question text,
  options jsonb,
  explain text,
  CONSTRAINT evaluation_pkey PRIMARY KEY (id),
  CONSTRAINT evaluation_indicator_id_fkey FOREIGN KEY (indicator_id) REFERENCES research_core.indicators(id),
  CONSTRAINT evaluation_activity_id_fkey FOREIGN KEY (activity_id) REFERENCES research_core.activities(id)
);
CREATE TABLE research_core.grammars (
  id integer NOT NULL DEFAULT nextval('research_core.grammars_id_seq'::regclass),
  category character varying NOT NULL,
  sub_category character varying,
  sub_sub_category character varying,
  rule_name character varying NOT NULL,
  description text,
  level integer CHECK (level >= 1 AND level <= 10),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT grammars_pkey PRIMARY KEY (id)
);
CREATE TABLE research_core.indicators (
  id integer NOT NULL DEFAULT nextval('research_core.indicators_id_seq'::regclass),
  indicator text NOT NULL,
  level integer NOT NULL CHECK (level >= 1 AND level <= 9),
  category USER-DEFINED NOT NULL,
  skill_group USER-DEFINED NOT NULL,
  weight numeric DEFAULT 1.0 CHECK (weight >= 0::numeric AND weight <= 1::numeric),
  created_at timestamp without time zone DEFAULT now(),
  material_types ARRAY,
  minimum smallint DEFAULT '30'::smallint,
  CONSTRAINT indicators_pkey PRIMARY KEY (id)
);
CREATE TABLE research_core.syllables (
  id integer NOT NULL DEFAULT nextval('research_core.syllables_id_seq'::regclass),
  pinyin character varying NOT NULL UNIQUE,
  pinyin_without_tone character varying,
  tone integer CHECK (tone >= 0 AND tone <= 4),
  initial character varying,
  final character varying,
  level integer CHECK (level >= 1 AND level <= 10),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT syllables_pkey PRIMARY KEY (id)
);
CREATE TABLE research_core.words (
  id integer NOT NULL DEFAULT nextval('research_core.words_id_seq'::regclass),
  word character varying NOT NULL UNIQUE,
  part_of_speech character varying,
  level integer CHECK (level >= 1 AND level <= 10),
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT words_pkey PRIMARY KEY (id)
);