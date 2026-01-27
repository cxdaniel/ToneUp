# Coze AI 工作流配置指南 - 多语言支持

## 概述
本文档说明如何在 Coze AI 平台上配置三个工作流，以支持多语言（英、中、日、韩、西、法、德）题目生成。

---

## 📋 需要配置的工作流

### 1. COZE_WORKFLOW_GENEXAM (生成评测题)
**Edge Function**: `generate_evalute_exams`  
**工作流ID**: `${COZE_WORKFLOW_GENEXAM}`

#### 输入参数（已实现）
```typescript
{
  act_data: Array<{
    indicator: string,      // 能力指标描述
    activity_title: string, // 活动标题
    quiz_template: string,  // 题目模板
    material: string,       // 学习材料（HSK汉字/词汇/句子）
    material_type: string,  // 材料类型
    level: number,          // HSK等级
    lang: string            // ✅ 用户母语（en/zh/ja/ko/es/fr/de）
  }>
}
```

#### 输出格式
```typescript
Array<{
  material: string,   // 原始材料
  question: string,   // 题目（使用 lang 指定的语言）
  options: string[],  // 选项数组（使用 lang 指定的语言）
  explain: string     // 解析（使用 lang 指定的语言）
}>
```

#### 配置要求
1. **添加输入节点**: 确保工作流接受 `lang` 参数（字符串类型）
2. **提示词模板修改**:
   ```
   请根据以下材料生成 HSK 练习题：
   
   材料: {material}
   材料类型: {material_type}
   HSK等级: {level}
   能力指标: {indicator}
   活动标题: {activity_title}
   题目模板: {quiz_template}
   
   ⚠️ 重要: 请使用 {lang_name} 生成题目、选项和解析。
   - 如果 lang='en'，使用英语
   - 如果 lang='zh'，使用中文
   - 如果 lang='ja'，使用日语
   - 如果 lang='ko'，使用韩语
   - 如果 lang='es'，使用西班牙语
   - 如果 lang='fr'，使用法语
   - 如果 lang='de'，使用德语
   
   输出JSON格式：
   {
     "material": "原始材料",
     "question": "题干（{lang_name}）",
     "options": ["选项1（{lang_name}）", "选项2", "选项3", "选项4"],
     "explain": "解析（{lang_name}）"
   }
   ```

3. **语言映射节点**（可选优化）:
   ```javascript
   // 在工作流中添加代码节点，将 lang 代码转换为语言名称
   const langMap = {
     'en': 'English',
     'zh': '中文',
     'ja': '日本語',
     'ko': '한국어',
     'es': 'Español',
     'fr': 'Français',
     'de': 'Deutsch'
   };
   const lang_name = langMap[input.lang] || 'English';
   ```

---

### 2. COZE_WORKFLOW_GETQUIZ (生成练习题)
**Edge Function**: `get_activity_instances`  
**工作流ID**: `${COZE_WORKFLOW_GETQUIZ}`

#### 输入参数（已实现）
```typescript
{
  quiz_data: Array<{
    id: number,
    quiz_template: string,
    material: string,
    material_type: string,
    activity_title: string,
    indicator: string,
    topic_tag: string,
    culture_tag: string,
    time_cost: number,
    level: number,
    lang: string  // ✅ 从数据库读取（由 create-plan 设置）
  }>
}
```

#### 输出格式
```typescript
Array<{
  material: string,
  question: string,   // 使用 lang 指定的语言
  options: string[],  // 使用 lang 指定的语言
  explain: string     // 使用 lang 指定的语言
}>
```

#### 配置要求
**与 COZE_WORKFLOW_GENEXAM 相同**：
- 添加 `lang` 输入节点
- 修改提示词以支持多语言
- （可选）添加语言映射节点

**关键区别**:
- `quiz_data` 是数组，需要批量处理
- 每个 quiz 可能有不同的 `lang` 值（理论上，实践中通常相同）

---

### 3. COZE_WORKFLOW_ID (生成学习计划材料)
**Edge Function**: `create-plan`  
**工作流ID**: `${COZE_WORKFLOW_ID}`

#### 当前状态分析
**Edge Function 不直接将 `native_language` 传给 Coze**：
```typescript
// create-plan/index.ts Line 46
const { user_id, inds, dur = 60, acts = null, native_language = 'en' } = await req.json();
const lang = native_language;

// 但在调用 _callCozeWorkflow 时：
const cozeOutput = await _callCozeWorkflow(materialNeeds);

// materialNeeds 没有包含 lang
const materialNeeds = {
  level: currentLevel,
  focusIndicators: focusIndicators.map((ind) => ind.indicator),
  materialQuantities,
  needReviews,
  exists
};
```

#### 是否需要配置？
**两种情况**:

**情况A: Coze 生成的材料不需要多语言**
- 如果 `cozeOutput` 只生成 HSK 原始材料（汉字/词汇/句子），不生成翻译或解析
- **无需修改** Coze 工作流
- `lang` 仅用于标记数据库记录，后续由 `get_activity_instances` 生成对应语言题目

**情况B: Coze 生成的材料需要多语言**（如包含翻译、注释）
- 需要修改 `_callCozeWorkflow` 调用，传入 `lang`:
  ```typescript
  const cozeOutput = await _callCozeWorkflow({
    ...materialNeeds,
    lang: lang  // 添加语言参数
  });
  ```
- Coze 工作流需添加 `lang` 输入节点
- 提示词需调整（根据 `lang` 生成翻译/注释）

**建议**: 先按情况A运行，如果需要材料本身包含多语言内容，再按情况B修改。

---

## 🧪 测试验证

### 测试步骤
1. **部署 Edge Functions**:
   ```bash
   supabase functions deploy generate_evalute_exams
   supabase functions deploy get_activity_instances
   supabase functions deploy create-plan
   ```

2. **测试评测题生成**（英语）:
   ```bash
   curl -X POST \
     https://YOUR_PROJECT.supabase.co/functions/v1/generate_evalute_exams \
     -H "Authorization: Bearer YOUR_ANON_KEY" \
     -H "Content-Type: application/json" \
     -d '{
       "inds": [1, 2],
       "acts": [101, 102],
       "n": 5,
       "lang": "en"
     }'
   ```

3. **测试评测题生成**（中文）:
   ```bash
   # 修改上述请求中的 "lang": "zh"
   ```

4. **测试学习计划生成**:
   ```bash
   curl -X POST \
     https://YOUR_PROJECT.supabase.co/functions/v1/create-plan \
     -H "Authorization: Bearer YOUR_SESSION_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "user_id": "YOUR_USER_ID",
       "inds": [1, 2, 3],
       "dur": 60,
       "native_language": "ja"
     }'
   ```

5. **验证数据库**:
   ```sql
   -- 检查 quizes 表 lang 字段
   SELECT id, lang, question FROM quizes ORDER BY id DESC LIMIT 10;
   
   -- 检查 evaluation 表 lang 字段
   SELECT id, lang, question FROM evaluation ORDER BY id DESC LIMIT 10;
   ```

### 验证清单
- [ ] 英语题目生成正确（question, options, explain 均为英语）
- [ ] 中文题目生成正确
- [ ] 日语题目生成正确
- [ ] 韩语题目生成正确
- [ ] 西班牙语题目生成正确
- [ ] 法语题目生成正确
- [ ] 德语题目生成正确
- [ ] 数据库 `lang` 字段正确保存
- [ ] `get_activity_instances` 正确读取并使用 `lang`

---

## 📊 数据流总结

```
用户设置母语 (ProfileModel.nativeLanguage = 'ja')
    ↓
创建学习计划 (DataService.generatePlanWithProgress)
    ↓
create-plan Edge Function (接收 native_language)
    ↓
保存 quizes.lang = 'ja', user_practices.lang = 'ja'
    ↓
用户开始练习
    ↓
get_activity_instances Edge Function (读取 quizes.lang)
    ↓
调用 Coze: quiz_data[].lang = 'ja'
    ↓
Coze 生成日语题目
    ↓
更新 quizes.question/options/explain（日语内容）
    ↓
客户端显示日语题目
```

---

## 🚨 常见问题

### Q1: Coze 工作流如何识别 `lang` 参数？
**A**: 在 Coze 平台上编辑工作流，添加"输入节点"（Input Node），定义参数名为 `lang`，类型为 `string`。

### Q2: 提示词中如何使用 `lang` 参数？
**A**: 使用 Coze 的变量语法 `{lang}` 或 `{input.lang}`，具体语法参考 Coze 平台文档。

### Q3: 如何处理 Coze 不支持的语言？
**A**: 在工作流中添加默认值逻辑：
```javascript
const supportedLangs = ['en', 'zh', 'ja', 'ko', 'es', 'fr', 'de'];
const finalLang = supportedLangs.includes(input.lang) ? input.lang : 'en';
```

### Q4: 批量处理时，每个 quiz 的 lang 不同怎么办？
**A**: 当前实现中，一个用户的所有 quiz 使用相同的 `lang`（来自用户 Profile）。如需支持混合语言，需修改 `create-plan` 逻辑，为每个 quiz 单独指定 `lang`。

---

## 📝 后续改进建议

1. **性能优化**: 如果 Coze API 支持，可批量请求不同语言的题目（当前是逐个请求）
2. **缓存机制**: 缓存已生成的题目，避免重复调用 Coze（按 material + lang 缓存）
3. **A/B 测试**: 对比不同语言题目的学习效果
4. **多语言混合**: 支持用户在一个学习计划中使用多种语言（高级功能）

---

**配置完成后，请运行测试验证清单中的所有项目。**
