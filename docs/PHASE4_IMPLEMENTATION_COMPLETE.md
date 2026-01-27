# Phase 4 实施完成报告 - Coze AI 工作流配置

## 📅 实施时间
**开始时间**: 2026年1月28日  
**完成时间**: 2026年1月28日  
**阶段**: Phase 4 - Coze AI 工作流配置

---

## ✅ 实施内容

### 1. Edge Functions 代码审查

#### 1.1 generate_evalute_exams ✅
**文件**: `supabase/functions/generate_evalute_exams/index.ts`

**已实现功能**:
- ✅ 接收 `lang` 参数（Line 46）
- ✅ 将 `lang` 包含在 `act_data` 中传给 Coze（通过 quiz template）
- ✅ 保存 `lang` 到 `evaluation` 表（Line 77）

**代码片段**:
```typescript
const { inds, acts = null, n = 10, lang = 'en' } = await req.json();

const evaluations = targets.map((item, i) => ({
  level: item.indicator.level,
  indicator_id: item.indicator.id,
  activity_id: item.activity.id,
  stem: quizess[i].material,
  question: quizess[i].question,
  options: quizess[i].options,
  explain: quizess[i].explain,
  lang,  // ✅ 保存语言标识
}));
```

#### 1.2 get_activity_instances ✅
**文件**: `supabase/functions/get_activity_instances/index.ts`

**已实现功能**:
- ✅ 从数据库读取 `quizes.lang`（Line 68-81）
- ✅ 将 `lang` 包含在 `quiz_data` 数组中传给 Coze（Line 80）
- ✅ 不需要客户端传递 `lang` 参数（从数据库读取）

**代码片段**:
```typescript
const quiz_data = mergeData.map((quiz) => {
  return {
    id: quiz.id,
    quiz_template: quiz.activity.quiz_template,
    material: quiz.material,
    material_type: quiz.material_type,
    activity_title: quiz.activity.activity_title,
    indicator: quiz.indicator.indicator,
    topic_tag: quiz.topic_tag,
    culture_tag: quiz.culture_tag,
    time_cost: quiz.activity.time_cost,
    level: quiz.level,
    lang: quiz.lang  // ✅ 从数据库读取
  };
});

const quizes = await callCozeWorkflow({
  quiz_data  // ✅ 传给 Coze，包含 lang 字段
});
```

#### 1.3 create-plan ✅ 🔧
**文件**: `supabase/functions/create-plan/index.ts`

**修复内容**:
- ✅ 修复参数名不一致问题（`native_language` vs `lang`）
- ✅ 接收 `native_language` 参数，转换为 `lang` 变量（Line 46-47）
- ✅ 传递 `lang` 到 `_saveQuizesData` 和 `_savePracticesData`（Line 178, 183）

**修改前**:
```typescript
const { user_id, inds, dur = 60, acts = null, lang = 'en' } = await req.json();
```

**修改后**:
```typescript
const { user_id, inds, dur = 60, acts = null, native_language = 'en' } = await req.json();
const lang = native_language; // 统一使用 lang 变量名
```

**保存逻辑**:
```typescript
// Line 175-184
const saved_quizes = await _saveQuizesData({
  planData,
  cozeOutput,
  lang: lang  // ✅ 传递语言参数
});

const saved_practices = await _savePracticesData({
  planData,
  saved_quizes,
  lang: lang  // ✅ 传递语言参数
});
```

---

### 2. 创建配置文档

**文件**: `docs/COZE_WORKFLOW_CONFIGURATION.md`

**文档内容**:
1. **三个工作流的详细配置指南**
   - COZE_WORKFLOW_GENEXAM（生成评测题）
   - COZE_WORKFLOW_GETQUIZ（生成练习题）
   - COZE_WORKFLOW_ID（生成学习计划材料）

2. **每个工作流的输入/输出格式**
   - 参数结构
   - 数据类型
   - 语言字段说明

3. **提示词模板示例**
   - 多语言判断逻辑
   - 语言映射代码
   - JSON 输出格式

4. **测试验证步骤**
   - curl 命令示例
   - 数据库验证 SQL
   - 7种语言测试清单

5. **数据流总结**
   - 从用户设置到题目显示的完整流程

6. **常见问题 Q&A**
   - Coze 平台配置方法
   - 提示词语法
   - 错误处理

---

## 🔍 发现的问题与修复

### 问题1: create-plan 参数名不一致
**描述**: 客户端传 `native_language`，Edge Function 接收 `lang`

**影响**: 导致语言参数无法正确传递

**修复**:
```typescript
// 修改 supabase/functions/create-plan/index.ts Line 46-47
const { user_id, inds, dur = 60, acts = null, native_language = 'en' } = await req.json();
const lang = native_language; // 统一使用 lang 变量名
```

**验证**: ✅ 参数名统一，后续代码使用 `lang` 变量

---

### 问题2: create-plan 是否需要将 lang 传给 Coze？
**分析**: 当前 `_callCozeWorkflow` 调用不包含 `lang` 参数

**两种情况**:
- **情况A**: Coze 只生成 HSK 原始材料（汉字/词汇），不需要多语言 → **无需修改**
- **情况B**: Coze 生成的材料包含翻译/注释，需要多语言 → **需要传递 lang**

**当前处理**: 保持情况A（材料本身不翻译），后续如需情况B可参考文档修改

**文档**: 已在 `COZE_WORKFLOW_CONFIGURATION.md` 说明两种情况及修改方法

---

## 📊 修改统计

| 类型 | 数量 | 文件 |
|------|------|------|
| Edge Functions 修改 | 1 | `create-plan/index.ts` |
| 新增文档 | 1 | `COZE_WORKFLOW_CONFIGURATION.md` |
| 代码行数（修改） | 2 | 参数接收部分 |
| 文档行数（新增） | ~300 | 配置指南 |

---

## 🎯 完成状态

### Phase 4 任务清单
- [x] 检查 Edge Functions 的 Coze AI 调用是否正确传递 lang 参数
  - [x] generate_evalute_exams: ✅ 已正确实现
  - [x] get_activity_instances: ✅ 已正确实现（从数据库读取）
  - [x] create-plan: ✅ 已修复参数名问题
- [x] 修复 create-plan 参数名不一致问题
- [x] 创建 Coze AI 工作流配置指南
  - [x] COZE_WORKFLOW_GENEXAM 配置说明
  - [x] COZE_WORKFLOW_GETQUIZ 配置说明
  - [x] COZE_WORKFLOW_ID 配置说明（含两种情况分析）
  - [x] 提示词模板示例
  - [x] 测试验证步骤
  - [x] 常见问题 Q&A
- [x] 创建 Phase 4 实施文档

---

## 🚀 下一步行动

### Phase 5: 测试与部署

#### 5.1 部署 Edge Functions
```bash
# 部署修改后的 create-plan
supabase functions deploy create-plan

# 确认其他 Edge Functions 已部署
supabase functions deploy generate_evalute_exams
supabase functions deploy get_activity_instances
```

#### 5.2 部署数据库迁移
```bash
# 应用 lang 字段迁移
supabase db push

# 或手动执行 SQL
psql -h YOUR_DB_HOST -U postgres -d postgres -f supabase/migrations/20260127_add_language_fields_to_quizzes.sql
psql -h YOUR_DB_HOST -U postgres -d postgres -f supabase/migrations/20260128_update_random_evaluation_function.sql
```

#### 5.3 Coze AI 工作流配置
**参考文档**: `docs/COZE_WORKFLOW_CONFIGURATION.md`

1. 登录 Coze AI 平台
2. 编辑 COZE_WORKFLOW_GENEXAM 工作流
   - 添加 `lang` 输入节点
   - 修改提示词模板（使用 {lang} 变量）
   - 测试生成英语/中文题目
3. 编辑 COZE_WORKFLOW_GETQUIZ 工作流
   - 添加 `lang` 输入节点（数组中每个元素的 lang）
   - 修改提示词模板
   - 测试批量生成
4. （可选）编辑 COZE_WORKFLOW_ID 工作流
   - 如需材料翻译，添加 `lang` 输入节点
   - 修改提示词

#### 5.4 客户端测试
1. **创建学习计划测试**
   ```dart
   // 测试不同语言
   await DataService().generatePlanWithProgress(
     userId: currentUserId,
     inds: [1, 2, 3],
     dur: 60,
     nativeLanguage: 'ja',  // 测试日语
   );
   ```

2. **练习题生成测试**
   - 检查生成的题目是否为日语
   - 验证 `quizes.lang` 字段是否为 'ja'

3. **评测题测试**
   ```dart
   // 测试不同语言
   await DataService().fetchEvaluationQuizes(
     level: 3,
     lang: 'ko',  // 测试韩语
   );
   ```

#### 5.5 验证清单
- [ ] 数据库迁移成功（lang 字段存在且类型正确）
- [ ] Edge Functions 部署成功
- [ ] Coze 工作流配置完成
- [ ] 英语题目生成正确
- [ ] 中文题目生成正确
- [ ] 日语题目生成正确
- [ ] 韩语题目生成正确
- [ ] 西班牙语题目生成正确
- [ ] 法语题目生成正确
- [ ] 德语题目生成正确
- [ ] 数据库 lang 字段正确保存
- [ ] 客户端显示正确语言题目

---

## 📈 项目整体进度

| Phase | 名称 | 状态 | 完成时间 |
|-------|------|------|----------|
| Phase 1 | 数据库 + Edge Functions | ✅ 完成 | 2026-01-27 |
| Phase 2 | 客户端模型 | ✅ 完成 | 2026-01-27 |
| Phase 3 | UI 层集成 | ✅ 完成 | 2026-01-28 |
| **Phase 4** | **Coze AI 工作流配置** | ✅ **完成** | **2026-01-28** |
| Phase 5 | 测试与部署 | ⏳ 待进行 | - |

---

## 📝 技术备忘

### Edge Function 参数传递规范
1. **客户端 → Edge Function**: 使用业务语义命名（如 `native_language`）
2. **Edge Function 内部**: 统一使用简洁变量名（如 `lang`）
3. **Edge Function → Coze**: 根据 Coze 工作流定义的输入参数名

### 数据库字段命名规范
- 使用 snake_case: `native_language`, `lang`
- 使用 enum 类型提高数据一致性
- 设置合理的默认值（`DEFAULT 'en'::lang`）

### Coze AI 工作流设计原则
- 明确输入输出格式（使用 JSON Schema）
- 提示词中显式说明语言要求
- 添加错误处理和默认值逻辑

---

**Phase 4 实施完成，代码层面已准备就绪。接下来需在 Coze 平台配置工作流，并进行完整测试。**
