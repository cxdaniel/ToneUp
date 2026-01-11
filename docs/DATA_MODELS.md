# ToneUp App - 数据模型快速参考

> **文档版本**: v1.0  
> **更新日期**: 2026年1月11日  
> **用途**: 快速查找所有数据模型、枚举类型、数据表结构

---

## 📑 目录

- [枚举类型 (Enums)](#枚举类型-enums)
- [核心数据模型 (Models)](#核心数据模型-models)
- [数据库表结构 (Database Tables)](#数据库表结构-database-tables)
- [视图与RPC函数](#视图与rpc函数)

---

## 枚举类型 (Enums)

### IndicatorCategory (能力指标分类)
15种中文学习能力维度，用于评估用户的学习进度和生成个性化计划。

```dart
enum IndicatorCategory {
  charsRecognition,    // 辨认汉字
  wordRecognition,     // 辨认词汇
  grammar,             // 掌握语法
  listening,           // 听懂句子
  listeningSpeed,      // 听力速度
  syllable,            // 掌握音节
  expression,          // 口语表达
  comprehension,       // 文本理解
  readingSpeed,        // 阅读速度
  readingSkill,        // 阅读技能
  typingSpeed,         // 抄写速度
  writing,             // 汉字书写
  writingNorms,        // 书写规范
  writtenWriting,      // 书面写作
  translation          // 文本翻译
}
```

**数据库映射**: `indicator_cats` (INTEGER[]) → 存储指标ID数组

**使用场景**:
- 生成学习计划时选择目标指标
- 练习活动关联的能力维度
- 用户能力评估记录

---

### MaterialContentType (学习材料类型)
7种学习素材内容类型，定义练习题目的素材来源。

```dart
enum MaterialContentType {
  character,   // 单字: 你, 我, 他
  word,        // 词汇: 学习, 努力, 快乐
  sentence,    // 句子: 我爱学中文
  dialog,      // 对话: A:你好 B:你好
  paragraph,   // 段落: 长篇文章
  syllable,    // 音节: ni, hao, ma
  grammar      // 语法: 把字句, 被字句
}
```

**数据库映射**: `material_type` (TEXT[]) → 存储类型字符串数组

**关联表**: 
- `user_materials` - 包含 chars, words, sentences 等字段
- `activities` - 每个活动支持的材料类型

---

### QuizTemplate (练习模板)
9种交互式练习题型，定义用户答题方式。

```dart
enum QuizTemplate {
  textToText,      // 看文选文: 选择题
  textToVoice,     // 看文选音: 听音辨义
  voiceToText,     // 听音选文: 听力理解
  leftToRight,     // 左右配对: 词汇匹配
  multiToMulti,    // 多项填多空: 完形填空
  orderAndJoin,    // 连词成句: 句子排序
  recordOfExample, // 复述例句: 口语录音
  tracOfExample,   // 描红写字: 汉字临摹
  typeOfText       // 键盘输入: 拼写练习
}
```

**数据库映射**: `quiz_template` (TEXT)

**UI组件映射**:
- `SelectionQuizWidget` → textToText/textToVoice/voiceToText
- `MatchingQuizWidget` → leftToRight
- `ClozeQuizWidget` → multiToMulti
- `SortQuizWidget` → orderAndJoin
- `RecordQuizWidget` → recordOfExample
- `TracingQuizWidget` → tracOfExample
- `TypingQuizWidget` → typeOfText

---

### QuizType (题型分类)
7种题目类型，描述答题交互模式。

```dart
enum QuizType {
  choice,    // 选择题: 单选/多选
  matching,  // 配对题: 连线匹配
  cloze,     // 选择填空: 下拉选项
  sorted,    // 选词拼句: 拖拽排序
  recoding,  // 复述录音: 语音输入
  tracing,   // 汉字描红: 手写输入
  typing     // 文本输入: 键盘输入
}
```

**数据库映射**: `quiz_type` (TEXT)

---

### PlanStatus (计划状态)
用户学习计划的生命周期状态。

```dart
enum PlanStatus {
  active,    // 进行中
  pending,   // 待激活
  done,      // 已完成
  reactive   // 重新激活
}
```

**数据库映射**: `status` (TEXT) in `user_weekly_plans`

**状态转换**:
```
pending → active (激活计划)
active → done (完成所有练习)
active → reactive (重新开始)
done → reactive (回顾练习)
```

---

### SubscriptionStatus (订阅状态)
用户订阅的当前状态，影响Pro功能权限。

```dart
enum SubscriptionStatus {
  free,      // 免费用户
  trial,     // 试用期 (7天)
  active,    // 付费活跃
  cancelled, // 已取消 (仍在有效期内)
  expired    // 已过期
}
```

**数据库映射**: `status` (TEXT) in `subscriptions`

**计算属性**:
- `isPro` = (status == active OR trial) AND expiresAt > now()
- `trialDaysLeft` = trialEndAt - now()

---

### SubscriptionTier (订阅套餐)
订阅产品的定价层级。

```dart
enum SubscriptionTier {
  monthly,   // 月度订阅: ¥18/月
  annual     // 年度订阅: ¥128/年
}
```

**关联产品ID**:
- `monthly` → `toneup_monthly_sub`
- `annual` → `toneup_annually_sub`

---

### PurposeType (学习目的)
用户学习中文的动机，用于个性化推荐。

```dart
enum PurposeType {
  interest, // 兴趣爱好
  work,     // 职业需求
  travel,   // 旅行交流
  exam,     // 考试准备 (HSK等)
  life      // 生活实用
}
```

**数据库映射**: `purpose` (TEXT) in `profiles`

---

## 核心数据模型 (Models)

### ProfileModel
用户个人档案，存储基础信息和学习统计。

```dart
class ProfileModel {
  final String id;                    // UUID (auth.users)
  String? nickname;                   // 昵称
  int? planDurationMinutes;           // 每日学习时长偏好
  int? exp;                           // 总经验值
  int? streakDays;                    // 连续学习天数
  int? level;                         // 当前HSK等级 (1-6)
  int? plans;                         // 完成计划数
  int? practices;                     // 完成练习数
  int? characters;                    // 学过汉字数
  int? words;                         // 学过词汇数
  int? sentences;                     // 学过句子数
  int? grammars;                      // 学过语法点数
  PurposeType? purpose;               // 学习目的
  DateTime? createdAt;
  DateTime? updatedAt;
  String? avatar;                     // 头像URL
}
```

**数据库表**: `profiles`  
**视图**: `active_profiles` (过滤已删除用户)

**关键业务逻辑**:
- `exp` 累积 → 检查升级条件 (ProfileProvider.checkLevelUpgrade)
- `level` 升级 → 解锁新的学习材料
- `streakDays` → 显示学习徽章

---

### SubscriptionModel
订阅状态数据，控制Pro功能访问权限。

```dart
class SubscriptionModel {
  final String id;
  final String userId;
  final String? revenueCatCustomerId;
  final String? revenueCatEntitlementId;
  
  final SubscriptionStatus status;
  final SubscriptionTier? tier;
  
  final DateTime? trialStartAt;
  final DateTime? trialEndAt;
  final DateTime? subscriptionStartAt;
  final DateTime? subscriptionEndAt;
  final DateTime? cancelledAt;
  
  final String? platform;              // 'ios' | 'android' | 'web'
  final String? productId;             // RevenueCat产品ID
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // 计算属性
  bool get isActive { /* ... */ }
  bool get isPro { /* ... */ }
  int? get trialDaysLeft { /* ... */ }
}
```

**数据库表**: `subscriptions`

**数据同步流程**:
```
RevenueCat Purchase → Webhook → Supabase subscriptions → 
SubscriptionProvider轮询 → UI更新
```

**权限检查**:
```dart
if (!SubscriptionProvider().isPro) {
  return UpgradePrompt();
}
```

---

### UserWeeklyPlanModel
用户每周学习计划，包含多个练习活动。

```dart
class UserWeeklyPlanModel {
  final String id;
  final String userId;
  final DateTime startDate;
  final DateTime endDate;
  final PlanStatus status;
  final int totalExp;                  // 计划总经验值
  final List<String> practices;        // 练习ID数组
  final List<int> targetInds;          // 目标指标ID数组
  final DateTime createdAt;
  
  // 关联数据 (非数据库字段)
  List<UserPracticeModel>? practiceData;
}
```

**数据库表**: `user_weekly_plans`  
**视图**: `active_user_weekly_plans` (只返回active/reactive状态)

**业务规则**:
- 一个用户同时只能有1个active计划
- 计划包含7天练习，每天1-3个practice
- 完成所有practice后，status变为done

---

### UserPracticeModel
单个练习活动，包含多道题目。

```dart
class UserPracticeModel {
  final String id;
  final String userId;
  final String planId;
  final String activityId;             // 关联activities表
  final String status;                 // 'not_started' | 'in_progress' | 'completed'
  final int? score;                    // 得分
  final double? completionRate;        // 完成率 (0-1)
  final List<Map<String, dynamic>> quizzes; // 题目数据数组
  final DateTime createdAt;
  
  // 关联数据
  ActivityModel? activity;
}
```

**数据库表**: `user_practices`  
**视图**: `active_user_practices`

**题目结构 (quizzes字段)**:
```json
[
  {
    "id": "quiz_123",
    "type": "choice",
    "question": "选择正确的拼音",
    "options": ["nǐ", "ní", "nì"],
    "correctAnswer": 0,
    "userAnswer": null,
    "isCorrect": null
  }
]
```

---

### ActivityModel
练习活动模板，定义题型和材料要求。

```dart
class ActivityModel {
  final String id;
  final QuizTemplate quizTemplate;
  final QuizType quizType;
  final List<MaterialContentType> materialType;
  final List<int> indicatorCats;       // 关联的能力指标ID
  final String title;                  // 如: "汉字识别训练"
  final String? description;
}
```

**数据库表**: `activities`

**使用场景**:
- Edge Function根据指标选择合适的活动
- PracticePage根据activity加载对应UI组件

---

### UserMaterialsModel
学习材料数据，按HSK等级和标签组织。

```dart
class UserMaterialsModel {
  final String id;
  final int level;                     // HSK 1-6
  final int? topicTag;                 // 话题标签ID
  final int? cultureTag;               // 文化标签ID
  
  final List<String> chars;            // 汉字: ["你", "我"]
  final List<String> words;            // 词汇: ["学习", "努力"]
  final List<String> syllables;        // 音节: ["ni3", "hao3"]
  final List<String> grammars;         // 语法: ["把字句"]
  final List<String> sentences;        // 句子
  final List<String> paragraphs;       // 段落
  final List<Map<String, dynamic>> dialogs; // 对话
  
  final DateTime createdAt;
}
```

**数据库表**: `user_materials`

**材料选择逻辑** (Edge Function: create-plan):
```sql
SELECT * FROM user_materials
WHERE level = user.hsk_level
  AND id NOT IN (已学过的材料)
ORDER BY RANDOM()
LIMIT 10
```

---

### UserScoreRecordModel
用户答题得分记录，用于能力评估。

```dart
class UserScoreRecordModel {
  final String id;
  final String userId;
  final String practiceId;
  final String planId;
  final int score;                     // 实际得分
  final int maxScore;                  // 满分
  final int expGained;                 // 获得经验值
  final DateTime completedAt;
}
```

**数据库表**: `user_score_records`

**经验值计算**:
```dart
expGained = (score / maxScore) * 100 * difficultyMultiplier
```

---

### UserAbilityHistoryModel
用户能力评估历史，追踪15个指标的变化。

```dart
class UserAbilityHistoryModel {
  final String id;
  final String userId;
  final int indicatorId;               // 关联indicators表
  final double abilityScore;           // 能力值 (0-100)
  final DateTime measuredAt;
}
```

**数据库表**: `user_ability_history`

**能力评估触发**:
- 完成练习后 → 更新相关指标的abilityScore
- 用于生成能力雷达图
- 升级条件: 所有指标平均值 >= 80

---

### IndicatorModel
能力指标定义表，描述15种学习维度。

```dart
class IndicatorModel {
  final int id;
  final IndicatorCategory category;
  final String name;                   // 如: "辨认汉字"
  final String? description;
  final int hskLevel;                  // 适用等级
}
```

**数据库表**: `indicators`

---

## 数据库表结构 (Database Tables)

### 完整表清单

| 表名 | 用途 | 关键字段 |
|------|------|----------|
| `profiles` | 用户档案 | id, nickname, level, exp, avatar |
| `subscriptions` | 订阅状态 | user_id, status, tier, expires_at |
| `user_weekly_plans` | 学习计划 | user_id, status, practices[], target_inds[] |
| `user_practices` | 练习活动 | plan_id, activity_id, quizzes[], score |
| `user_materials` | 学习材料 | level, topic_tag, chars[], words[] |
| `activities` | 活动模板 | quiz_template, material_type[], indicator_cats[] |
| `indicators` | 能力指标 | category, name, hsk_level |
| `user_score_records` | 得分记录 | practice_id, score, exp_gained |
| `user_ability_history` | 能力评估 | indicator_id, ability_score |
| `user_event_records` | 行为日志 | event_type, event_data |
| `images` (Storage) | 用户头像 | bucket: images/avatars/{user_id} |

### 表关系图

```
auth.users (Supabase Auth)
    ↓ (1:1)
profiles
    ↓ (1:1)
subscriptions
    ↓ (1:N)
user_weekly_plans
    ↓ (1:N)
user_practices ──→ activities (模板)
    ↓                 ↓
user_score_records   indicators
    ↓
user_ability_history
```

### 关键约束与索引

**外键约束**:
```sql
-- profiles
ALTER TABLE profiles 
  ADD CONSTRAINT fk_user 
  FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- subscriptions
ALTER TABLE subscriptions 
  ADD CONSTRAINT fk_user 
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- user_weekly_plans
CREATE INDEX idx_plans_user_status 
  ON user_weekly_plans(user_id, status);

-- user_practices
CREATE INDEX idx_practices_plan 
  ON user_practices(plan_id);
```

**RLS (Row Level Security) 策略**:
```sql
-- profiles: 只能查看和修改自己的档案
CREATE POLICY "Users can view own profile" 
  ON profiles FOR SELECT 
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" 
  ON profiles FOR UPDATE 
  USING (auth.uid() = id);

-- 类似策略应用于所有用户数据表
```

---

## 视图与RPC函数

### 数据库视图

**`active_profiles`**
```sql
CREATE VIEW active_profiles AS
SELECT * FROM profiles
WHERE deleted_at IS NULL;
```

**`active_user_weekly_plans`**
```sql
CREATE VIEW active_user_weekly_plans AS
SELECT * FROM user_weekly_plans
WHERE status IN ('active', 'reactive', 'pending');
```

**`active_user_practices`**
```sql
CREATE VIEW active_user_practices AS
SELECT * FROM user_practices
WHERE status IN ('not_started', 'in_progress');
```

**`active_quizes`** (Quiz数据视图)
```sql
-- 待补充具体定义
```

### RPC函数

**`activate_weekly_plan(plan_id UUID)`**
```sql
-- 功能: 激活指定计划，将其他active计划设为expired
-- 返回: 更新后的计划数据
CREATE OR REPLACE FUNCTION activate_weekly_plan(plan_id UUID)
RETURNS user_weekly_plans AS $$
BEGIN
  -- 将当前用户的其他active计划设为expired
  UPDATE user_weekly_plans
  SET status = 'expired'
  WHERE user_id = (SELECT user_id FROM user_weekly_plans WHERE id = plan_id)
    AND status = 'active'
    AND id != plan_id;
  
  -- 激活目标计划
  UPDATE user_weekly_plans
  SET status = 'active'
  WHERE id = plan_id;
  
  RETURN (SELECT * FROM user_weekly_plans WHERE id = plan_id);
END;
$$ LANGUAGE plpgsql;
```

**调用示例**:
```dart
final result = await _supabase.rpc('activate_weekly_plan', params: {
  'plan_id': planId,
});
```

---

## 数据查询示例

### 获取用户当前活跃计划及练习
```dart
final plan = await _supabase
    .from('active_user_weekly_plans')
    .select()
    .eq('user_id', userId)
    .eq('status', 'active')
    .single();

final practices = await _supabase
    .from('active_user_practices')
    .select()
    .inFilter('id', plan['practices']);
```

### 查询用户能力雷达图数据
```dart
final abilities = await _supabase
    .from('user_ability_history')
    .select('indicator_id, ability_score')
    .eq('user_id', userId)
    .order('measured_at', ascending: false)
    .limit(15); // 最新的15个指标

// 按indicator_id去重，保留最新记录
```

### 统计用户学习数据
```dart
final stats = await _supabase.rpc('get_user_stats', params: {
  'user_id': userId,
});

// 返回: { total_exp, completed_plans, completed_practices, streak_days }
```

---

## 模型转换工具

### JSON序列化
所有模型使用 `json_serializable` 自动生成序列化代码：

```dart
// 生成命令
flutter pub run build_runner build --delete-conflicting-outputs

// 使用示例
final profile = ProfileModel.fromJson(json);
final jsonData = profile.toJson();
```

### 枚举转换
```dart
// String → Enum
final status = PlanStatus.values.byName('active');

// Enum → String
final statusStr = PlanStatus.active.name;

// JSON映射 (使用 @JsonValue)
final type = MaterialContentType.word; // → "word"
```

---

## 附录: 数据验证规则

### 字段长度限制
- `nickname`: 1-20字符
- `avatar`: URL格式，最大2MB
- `password`: 最小8字符（Auth层验证）

### 数值范围
- `hsk_level`: 1-6
- `ability_score`: 0-100
- `completion_rate`: 0-1
- `exp`: >= 0

### 必填字段
- ProfileModel: `id`
- SubscriptionModel: `id`, `userId`, `status`
- UserWeeklyPlanModel: `id`, `userId`, `startDate`, `endDate`

---

**📌 提示**: 
- 所有模型定义见 `lib/models/` 目录
- 枚举定义见 `lib/models/enumerated_types.dart`
- 数据库迁移脚本应存放在 `supabase/migrations/` (待创建)
- 使用 Supabase Studio 可视化管理数据表

**相关文档**:
- [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) - 项目全局架构
- [API_REFERENCE.md](./API_REFERENCE.md) - API接口文档
