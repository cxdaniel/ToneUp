# 扣子词典工作流 Edge Function

## 功能说明

此Edge Function实现了**智能词典查询和缓存**：

1. **接收客户端请求**：词语 + 目标语言
2. **调用扣子AI工作流**：获取高质量翻译
3. **自动保存到数据库**：缓存结果，避免重复调用
4. **返回结构化数据**：拼音、释义、例句、HSK等级

**架构优势**：
- ✅ 客户端逻辑简化（只需查询数据库 + 调用Edge Function）
- ✅ 数据一致性保证（Edge Function统一保存）
- ✅ 减少API调用成本（自动缓存到云端数据库）
- ✅ 支持多语言翻译（en, zh, ja, ko, es, fr, de）

## 部署步骤

### 1. 安装Supabase CLI (如未安装)

```bash
brew install supabase/tap/supabase
```

### 2. 登录Supabase

```bash
supabase login
```

### 3. 链接到您的项目

```bash
supabase link --project-ref kixonwnuivnjqlraydmz
```

### 4. 设置环境变量

```bash
# 扣子API密钥 (从扣子平台获取)
supabase secrets set COZE_API_KEY=your_coze_api_key_here

# 扣子词典工作流ID (从扣子平台工作流详情页获取)
supabase secrets set COZE_WORKFLOW_ID_DICTIONARY=your_workflow_id_here
```

### 5. 部署函数

```bash
supabase functions deploy translate-word
```

### 6. 测试函数

```bash
# 获取项目的anon key
ANON_KEY=$(supabase status | grep "anon key" | awk '{print $3}')

# 测试调用
curl -i --location --request POST \
  'https://kixonwnuivnjqlraydmz.supabase.co/functions/v1/translate-word' \
  --header "Authorization: Bearer $ANON_KEY" \
  --header 'Content-Type: application/json' \
  --data '{
    "word": "你好",
    "target_language": "en",
    "context": "日常打招呼"
  }'
```

## 本地测试

### 1. 创建本地环境变量文件

```bash
# 创建 .env.local 文件
cat > supabase/.env.local << EOF
COZE_API_KEY=your_coze_api_key_here
COZE_WORKFLOW_ID_DICTIONARY=your_workflow_id_here
EOF
```

### 2. 启动本地Supabase

```bash
supabase start
```

### 3. 运行函数

```bash
supabase functions serve translate-word --env-file supabase/.env.local
```

### 4. 测试本地函数

```bash
curl -i --location --request POST 'http://localhost:54321/functions/v1/translate-word' \
  --header 'Authorization: Bearer YOUR_LOCAL_ANON_KEY' \
  --header 'Content-Type: application/json' \
  --data '{
    "word": "学习",
    "target_language": "en"
  }'
```

## 预期响应格式

**成功响应 (200):**

```json
{
  "pinyin": "nǐ hǎo",
  "summary": "hello; hi",
  "hsk_level": 1,
  "entries": [
    {
      "pos": "interjection",
      "definitions": ["hello", "hi", "how do you do"],
      "examples": [
        "你好,很高兴认识你。 - Hello, nice to meet you.",
        "你好吗? - How are you?"
      ]
    }
  ]
}
```

**错误响应 (500):**

```json
{
  "error": "Missing required parameters: word, target_language",
  "timestamp": "2026-01-27T10:30:00.000Z"
}
```

## 故障排查

### 问题: 函数返回500错误

**检查步骤:**
1. 确认环境变量已设置: `supabase secrets list`
2. 查看函数日志: `supabase functions logs translate-word`
3. 验证扣子API密钥有效性

### 问题: 扣子工作流返回数据格式不匹配

**解决方法:**
1. 用Postman直接测试扣子工作流API,确认输出格式
2. 修改 `index.ts` 中的解析逻辑 (workflowOutput部分)
3. 重新部署: `supabase functions deploy translate-word`

### 问题: CORS错误

**解决方法:**
确认 `corsHeaders` 配置正确,包含:
- `Access-Control-Allow-Origin: *`
- `Access-Control-Allow-Headers: authorization, x-client-info, apikey, content-type`

## 监控与日志

### 查看实时日志

```bash
supabase functions logs translate-word --follow
```

### 查看调用统计

访问Supabase Dashboard:
1. 进入项目: https://app.supabase.com/project/kixonwnuivnjqlraydmz
2. 导航到: Functions → translate-word
3. 查看: Invocations / Errors / Response Time

## 更新函数

修改代码后重新部署:

```bash
supabase functions deploy translate-word
```

不需要重新设置环境变量,secrets会保留。
