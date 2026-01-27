# nativeLanguage 集成完整分析报告

**日期**: 2026-01-27  
**范围**: 练习题、测评题的多语言支持

---

## 📊 当前状态分析

### 1. 数据库层面 - 缺失语言字段

#### ❌ `public.quizes` 表
```sql
CREATE TABLE public.quizes (
  id bigint,
  indicator_id integer,
  activity_id integer,
  level smallint,
  topic_tag text,
  material text,
  material_type USER-DEFINED,
  stem jsonb,
  question text,        -- ❌ 问题文本（硬编码英文）
  options jsonb,        -- ❌ 选项（硬编码英文）
  explain text,         -- ❌ 解释（硬编码英文）
  -- ❌ 缺少 target_language 字段
);
```

**问题**：
- 题目、选项、解释都是纯文本，无语言标识
- 无法存储同一题目的多语言版本
- 无法根据用户母语筛选题目

---

#### ❌ `research_core.evaluation` 表
```sql
CREATE TABLE research_core.evaluation (
  id bigint,
  indicator_id integer,
  activity_id integer,
  level smallint,
  stem jsonb,
  question text,        -- ❌ 测评问题（硬编码英文）
  options jsonb,        -- ❌ 选项（硬编码英文）
  explain text,         -- ❌ 解释（硬编码英文）
  -- ❌ 缺少 target_language 字段
);
```

**问题**：同 `quizes` 表

---

#### ❌ `public.user_practices` 表
```sql
CREATE TABLE public.user_practices (
  id bigint,
  quizes ARRAY,         -- 存储 quiz IDs
  score numeric,
  -- ❌ 没有记录用户当时使用的语言
);
```

**问题**：无法知道用户练习时使用的是哪种语言

---

### 2. Edge Function 层面 - 未传递语言参数

#### ❌ `generate_evalute_exams/index.ts`
**当前调用 Coze**:
```typescript
const quizess = await callCozeWorkflow({
  act_data  // ❌ 未包含 target_language
});
```

**问题**：
- Coze AI 生成题目时没有语言上下文
- 默认生成英文题目
- 无法根据用户母语定制

---

#### ❌ `get_activity_instances/index.ts`
**当前调用 Coze**:
```typescript
const quizes = await callCozeWorkflow({
  quiz_data  // ❌ 未包含 target_language
});
```

**问题**：同上

---

### 3. 客户端模型层面

#### ✅ `QuizesModle` - 已有基础结构，需扩展
```dart
class QuizesModle {
  String? question;     // 题目文本
  List<Map>? options;   // 选项
  String? explain;      // 解释
  // ❌ 缺少 targetLanguage 字段
}
```

---

## 🎯 完整解决方案

### 阶段 1：数据库迁移（必须）

#### 1.1 修改 `quizes` 表
```sql
-- 添加目标语言字段
ALTER TABLE public.quizes 
ADD COLUMN IF NOT EXISTS target_language TEXT DEFAULT 'en';

-- 添加索引优化查询
CREATE INDEX IF NOT EXISTS idx_quizes_target_language 
ON public.quizes(target_language);

-- 添加注释
COMMENT ON COLUMN public.quizes.target_language IS 
'题目目标语言：en(英文), zh(中文), ja(日语), ko(韩语), es(西班牙语), fr(法语), de(德语)';
```

#### 1.2 修改 `evaluation` 表
```sql
-- 添加目标语言字段
ALTER TABLE research_core.evaluation 
ADD COLUMN IF NOT EXISTS target_language TEXT DEFAULT 'en';

-- 添加索引
CREATE INDEX IF NOT EXISTS idx_evaluation_target_language 
ON research_core.evaluation(target_language);

-- 添加注释
COMMENT ON COLUMN research_core.evaluation.target_language IS 
'测评题目标语言：对应 ProfileModel.nativeLanguage';
```

#### 1.3 修改 `user_practices` 表
```sql
-- 添加练习时使用的语言
ALTER TABLE public.user_practices 
ADD COLUMN IF NOT EXISTS practice_language TEXT DEFAULT 'en';

-- 添加注释
COMMENT ON COLUMN public.user_practices.practice_language IS 
'用户练习时使用的语言（记录历史状态）';
```

---

### 阶段 2：Edge Function 修改

#### 2.1 `generate_evalute_exams/index.ts`

**修改请求参数**:
```typescript
Deno.serve(async (req) => {
  const { 
    inds, 
    count = 10, 
    acts = null,
    target_language = 'en'  // ← 新增：目标语言
  } = await req.json();
  
  // ...
  
  // 调用 Coze 时传递语言
  const quizess = await callCozeWorkflow({
    act_data,
    target_language  // ← 传递给 Coze
  });
  
  // 保存时包含语言
  const evaluations = targets.map((item, i) => ({
    // ... 其他字段
    target_language  // ← 保存到数据库
  }));
});
```

**修改 Coze 调用**:
```typescript
async function callCozeWorkflow(input) {
  const response = await fetch("https://api.coze.cn/v1/workflow/run", {
    method: "POST",
    headers: {
      "Authorization": `Bearer ${COZE_TOKEN}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      workflow_id: COZE_WORKFLOW_ID,
      parameters: {
        ...input,
        target_language: input.target_language  // ← 传递语言参数
      }
    })
  });
}
```

---

#### 2.2 `get_activity_instances/index.ts`

**修改请求参数**:
```typescript
Deno.serve(async (req) => {
  const { 
    ids,
    target_language = 'en'  // ← 新增
  } = await req.json();
  
  // 查询时过滤语言
  const { data, error } = await supabase
    .from('quizes')
    .select()
    .in('id', validIds)
    .eq('target_language', target_language);  // ← 过滤语言
  
  // ...
  
  // 调用 Coze 生成时传递语言
  const quizes = await callCozeWorkflow({
    quiz_data,
    target_language  // ← 传递语言
  });
  
  // 更新时包含语言
  await updateQuizzesSimple(quizes, withoutQuiz, target_language);
});
```

---

### 阶段 3：客户端模型修改

#### 3.1 `QuizesModle` 添加字段
```dart
@JsonSerializable()
class QuizesModle {
  // ... 现有字段
  
  @JsonKey(name: "target_language")
  String? targetLanguage;  // ← 新增：题目目标语言
  
  QuizesModle({
    // ... 现有参数
    this.targetLanguage = 'en',
  });
}
```

#### 3.2 `UserPracticeModel` 添加字段
```dart
@JsonSerializable()
class UserPracticeModel {
  // ... 现有字段
  
  @JsonKey(name: "practice_language")
  String? practiceLanguage;  // ← 新增：练习时使用的语言
  
  UserPracticeModel({
    // ... 现有参数
    this.practiceLanguage = 'en',
  });
}
```

#### 3.3 重新生成序列化代码
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

### 阶段 4：客户端调用修改

#### 4.1 `DataService` - 生成题目
```dart
Future<List<QuizesModle>> generateQuizesContent(
  List<int> data, {
  String? targetLanguage,  // ← 新增参数
}) async {
  final profile = ProfileProvider().profile;
  final language = targetLanguage ?? profile?.nativeLanguage ?? 'en';
  
  final response = await Supabase.instance.client.functions.invoke(
    'get_activity_instances',
    body: {
      'ids': jsonEncode(data),
      'target_language': language,  // ← 传递语言
    },
  );
  
  // ...
}
```

#### 4.2 `DataService` - 生成测评题
```dart
Future<void> generateEvaluationExams({
  required List<int> indicators,
  int count = 10,
  String? targetLanguage,  // ← 新增参数
}) async {
  final profile = ProfileProvider().profile;
  final language = targetLanguage ?? profile?.nativeLanguage ?? 'en';
  
  final response = await Supabase.instance.client.functions.invoke(
    'generate_evalute_exams',
    body: {
      'inds': indicators,
      'count': count,
      'target_language': language,  // ← 传递语言
    },
  );
  
  // ...
}
```

#### 4.3 保存练习记录时包含语言
```dart
Future<void> savePracticeResult({
  required List<int> quizIds,
  required double score,
}) async {
  final profile = ProfileProvider().profile;
  
  await Supabase.instance.client.from('user_practices').insert({
    'quizes': quizIds,
    'score': score,
    'practice_language': profile?.nativeLanguage ?? 'en',  // ← 记录语言
  });
}
```

---

### 阶段 5：Coze Workflow 配置

#### 5.1 更新 Workflow 输入参数

**`COZE_WORKFLOW_GENEXAM` (生成练习题)**:
```json
{
  "act_data": [...],
  "target_language": "en"  // ← 新增输入
}
```

**Workflow 内部逻辑**:
- 根据 `target_language` 生成对应语言的题目
- 问题、选项、解释都用目标语言
- 保持材料（material）为中文

#### 5.2 示例 Prompt 调整
```
你是一个中文学习题目生成器。
根据以下信息生成练习题：
- 能力指标: {{indicator}}
- 材料: {{material}}
- 题目类型: {{quiz_type}}
- **目标语言**: {{target_language}}  ← 新增

要求：
1. 题目文本(question)使用 {{target_language}} 语言
2. 所有选项使用 {{target_language}} 语言
3. 解释使用 {{target_language}} 语言
4. 材料保持中文
```

---

## 📋 实施计划

### 优先级 1（核心功能）- 2小时
1. ✅ **数据库迁移** (30分钟)
   - 添加 `target_language` 字段到 3 张表
   - 创建索引
   - 运行迁移脚本

2. ✅ **Edge Function 修改** (45分钟)
   - 修改 `generate_evalute_exams/index.ts`
   - 修改 `get_activity_instances/index.ts`
   - 测试 Edge Function

3. ✅ **客户端模型修改** (30分钟)
   - 更新 `QuizesModle`
   - 更新 `UserPracticeModel`
   - 重新生成序列化代码

4. ✅ **客户端调用修改** (15分钟)
   - 更新 `DataService` 方法
   - 传递用户母语参数

---

### 优先级 2（Coze 配置）- 1小时
5. ✅ **Coze Workflow 更新** (30分钟)
   - 更新 Workflow 输入参数
   - 调整 Prompt 模板
   - 测试多语言生成

6. ✅ **数据清理** (30分钟)
   - 更新现有题目的 `target_language` 为 'en'
   - 验证数据一致性

---

### 优先级 3（完善功能）- 2小时
7. ✅ **语言切换逻辑** (1小时)
   - 用户切换母语后，重新生成题目
   - 缓存不同语言的题目版本

8. ✅ **UI 提示优化** (1小时)
   - 显示题目语言标签
   - 语言不匹配时提示用户

---

## 🎯 最小可行方案（MVP）

如果只做核心功能（2小时）：

### 方案 A：仅新生成题目支持多语言
- ✅ 数据库添加字段（默认 'en'）
- ✅ Edge Function 接受 `target_language` 参数
- ✅ 客户端传递用户母语
- ❌ 不修改已有题目
- ❌ 不修改 Coze Workflow（继续生成英文）

**效果**：
- 新用户可以获得母语题目
- 老题目仍然是英文
- 可以后续逐步迁移

### 方案 B：完整多语言支持（推荐）
- 按照上述优先级 1 + 2 完成
- 需要 3 小时
- 立即支持 7 种语言

---

## 🔍 潜在风险

### 1. Coze Workflow 性能
**问题**：不同语言的 Prompt 可能导致生成速度/质量差异

**解决**：
- 针对每种语言优化 Prompt
- 监控生成质量，建立评分机制

### 2. 已有题目迁移
**问题**：数据库中已有大量英文题目

**解决**：
- 批量更新 `target_language` 为 'en'
- 考虑使用翻译 API 批量生成其他语言版本

### 3. 缓存策略
**问题**：相同题目的不同语言版本占用更多存储

**解决**：
- 按需生成（用户请求时才生成对应语言）
- 定期清理低频语言的题目

---

## ✅ 验收标准

### 功能验收
- [ ] 用户设置母语为"日语"后，生成的题目为日文
- [ ] 同一题目可以生成多语言版本（不同 `target_language`）
- [ ] 练习记录包含当时使用的语言
- [ ] Edge Function 正确传递语言参数给 Coze

### 性能验收
- [ ] 题目生成时间增加 < 10%
- [ ] 数据库查询延迟 < 100ms
- [ ] Coze 调用成功率 > 95%

### 数据验收
- [ ] `quizes.target_language` 字段有效性 100%
- [ ] 新生成题目的语言与用户母语一致性 > 98%
- [ ] 练习记录的语言标记准确性 100%

---

## 📝 后续优化建议

1. **智能语言回退**
   - 用户母语题目不存在时，回退到英文
   - 显示"该题目暂无您的母语版本"提示

2. **题目翻译功能**
   - 允许管理员批量翻译已有题目
   - 用户可贡献题目翻译

3. **语言质量评分**
   - 用户可评价题目翻译质量
   - 低分题目触发人工审核

4. **A/B 测试**
   - 测试不同语言的题目对学习效果的影响
   - 优化 Prompt 提高题目质量

---

**报告生成时间**: 2026-01-27  
**预计完成时间**: 优先级 1 (2小时) / 完整方案 (5小时)
