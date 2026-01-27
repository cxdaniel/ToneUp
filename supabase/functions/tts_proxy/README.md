# TTS Proxy - 语音合成代理接口

## 功能说明

代理火山引擎（VolcTTS）的语音合成服务，提供智能缓存功能，大幅降低 TTS API 调用成本和响应延迟。

**核心特性**：
- ✅ 智能缓存：相同文本+音色的音频自动缓存
- ✅ Supabase Storage：使用云端存储作为缓存层
- ✅ 零重复调用：已缓存内容直接返回，节省成本
- ✅ 自动失败重试：代理火山 TTS API

## 接口信息

**端点**: `POST /tts_proxy`

**请求体**:
```json
{
  "request": {
    "text": "你好，欢迎学习中文！"
  },
  "audio": {
    "voice_type": "zh_female_qingxin"
  }
}
```

**参数说明**:
| 参数 | 类型 | 必填 | 说明 |
|-----|------|-----|------|
| request.text | string | ✅ | 要合成的文本 |
| audio.voice_type | string | ❌ | 音色类型（默认: default） |

## 响应格式

**Content-Type**: `audio/mpeg`

直接返回 MP3 音频文件的二进制数据。

## 缓存机制

### 1. 缓存键生成
```typescript
function hashKey(text: string, voiceType: string) {
  const data = `${voiceType}|${text}`;
  const hash = SHA1(data);
  return hash; // 例如: "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3"
}
```

### 2. 缓存路径
```
Supabase Storage Bucket: tts_cache/
路径格式: {voice_type}/{hash}.mp3

示例:
- zh_female_qingxin/a94a8fe5ccb19ba61c4c0873d391e987982fbbd3.mp3
- en_male_deep/f3b8c90812b...mp3
```

### 3. 缓存查询流程
```typescript
// 1. 计算缓存键
const key = await hashKey(text, voiceType);
const filePath = `${voiceType}/${key}.mp3`;

// 2. 尝试从 Supabase Storage 读取
const { data: cachedFile } = await supabase.storage
  .from('tts_cache')
  .download(filePath);

if (cachedFile) {
  console.log('🎯 缓存命中');
  return cachedFile; // 直接返回，耗时 ~100ms
}

// 3. 缓存未命中 → 调用火山 API
const audioData = await callVolcTTS(text, voiceType);

// 4. 保存到缓存
await supabase.storage
  .from('tts_cache')
  .upload(filePath, audioData, { upsert: true });

return audioData;
```

## 火山引擎 TTS API

### 请求格式
```json
{
  "app": {
    "appid": "YOUR_APPID",
    "token": "YOUR_TOKEN",
    "cluster": "volcano_tts"
  },
  "user": {
    "uid": "user_123"
  },
  "audio": {
    "voice_type": "zh_female_qingxin",
    "encoding": "mp3",
    "speed_ratio": 1.0,
    "volume_ratio": 1.0,
    "pitch_ratio": 1.0
  },
  "request": {
    "reqid": "uuid",
    "text": "你好，欢迎学习中文！",
    "text_type": "plain",
    "operation": "query"
  }
}
```

### API 端点
```
POST https://openspeech.bytedance.com/api/v1/tts
Authorization: Bearer;{VOLC_TOKEN}
```

## 音色类型

### 中文音色
| voice_type | 说明 | 适用场景 |
|-----------|------|---------|
| zh_female_qingxin | 清新女声 | 日常对话、句子朗读 |
| zh_male_chunhou | 醇厚男声 | 段落朗读、文章阅读 |
| zh_female_tianmei | 甜美女声 | 儿童学习、轻松内容 |
| zh_male_qingsong | 轻松男声 | 对话练习、口语训练 |

### 英文音色
| voice_type | 说明 | 适用场景 |
|-----------|------|---------|
| en_female_young | 年轻女声 | 日常对话 |
| en_male_deep | 深沉男声 | 正式内容 |

### 默认音色
如果未指定 `voice_type`，使用 `default`（系统默认音色）。

## 性能优化

### 缓存命中（快速路径）
```
用户请求 → 计算哈希 → 查询缓存 → 返回音频
                ↓           ↓
            ~1ms        ~100ms
                总耗时 ~100ms
```

### 缓存未命中（完整路径）
```
用户请求 → 计算哈希 → 查询缓存（miss） → 调用火山API → 保存缓存 → 返回音频
                ↓                          ↓                      ↓
            ~1ms                      ~1-3s                  ~200ms
                              总耗时 ~1-3s（仅首次）
```

### 缓存效果
| 场景 | 未缓存 | 已缓存 | 提升 |
|-----|--------|--------|------|
| 单次请求 | ~2s | ~100ms | **20x** |
| 100次重复 | ~200s | ~10s | **20x** |
| 成本 | $1.00 | $0.05 | **节省95%** |

## 使用场景

### 1. 句子朗读
```dart
Future<void> playAudio(String sentence) async {
  final response = await Supabase.instance.client.functions.invoke(
    'tts_proxy',
    body: {
      'request': {'text': sentence},
      'audio': {'voice_type': 'zh_female_qingxin'},
    },
  );

  final audioBytes = response.data as Uint8List;
  await audioPlayer.playBytes(audioBytes);
}
```

### 2. 批量预加载
```dart
// 预加载当天计划的所有句子音频
Future<void> preloadPlanAudio(List<String> sentences) async {
  for (final sentence in sentences) {
    await Supabase.instance.client.functions.invoke(
      'tts_proxy',
      body: {
        'request': {'text': sentence},
        'audio': {'voice_type': 'zh_female_qingxin'},
      },
    );
  }
  // 所有音频已缓存，后续播放无需等待
}
```

### 3. 多音色对比
```dart
// 让用户选择喜欢的音色
final voiceTypes = [
  'zh_female_qingxin',
  'zh_male_chunhou',
  'zh_female_tianmei'
];

for (final voiceType in voiceTypes) {
  final audioBytes = await getTTSAudio(text, voiceType);
  playAudioSample(voiceType, audioBytes);
}
```

## 缓存管理

### 查看缓存统计
```sql
SELECT 
  bucket_id,
  COUNT(*) as file_count,
  SUM(metadata->>'size')::bigint / 1024 / 1024 as total_mb
FROM storage.objects
WHERE bucket_id = 'tts_cache'
GROUP BY bucket_id;
```

### 清理旧缓存
```sql
-- 删除30天前的缓存
DELETE FROM storage.objects
WHERE 
  bucket_id = 'tts_cache' 
  AND created_at < NOW() - INTERVAL '30 days';
```

### 手动清空缓存（慎用）
```sql
DELETE FROM storage.objects WHERE bucket_id = 'tts_cache';
```

## Supabase Storage 配置

### 创建 Bucket
```sql
INSERT INTO storage.buckets (id, name, public)
VALUES ('tts_cache', 'tts_cache', true);
```

### 设置访问策略
```sql
-- 允许所有人读取
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'tts_cache');

-- 只允许 Edge Function 写入
CREATE POLICY "Edge Function write access"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'tts_cache'
  AND auth.role() = 'service_role'
);
```

## 错误处理

### 火山 API 调用失败
```typescript
try {
  const volcRes = await fetch(VOLC_API_URL, {...});
  if (!volcRes.ok) {
    throw new Error(`火山API错误: ${volcRes.status}`);
  }
} catch (error) {
  console.error('❌ TTS Proxy Error:', error);
  return new Response(
    JSON.stringify({ error: error.message }),
    { status: 500 }
  );
}
```

### Storage 写入失败
```typescript
try {
  await supabase.storage
    .from('tts_cache')
    .upload(filePath, audioData);
} catch (error) {
  // 仍然返回音频给用户，只是未缓存
  console.error('缓存失败（不影响用户）:', error);
}
```

## 成本分析

### 火山 TTS 定价（示例）
- 按字符计费：¥0.001/字符
- 100字句子 = ¥0.1
- 1000次重复播放 = ¥100（无缓存）

### 使用 TTS Proxy 后
- 首次合成：¥0.1
- 后续999次：¥0（缓存命中）
- **总成本：¥0.1**（节省99.9%）

### Supabase Storage 成本
- 存储：$0.021/GB/月
- 带宽：$0.09/GB
- 10000个MP3文件（约500MB）≈ $0.01/月

**结论**：缓存带来的成本节省远超 Storage 开销。

## 环境变量

```bash
SUPABASE_URL=https://xxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=xxx
VOLC_TOKEN=xxx      # 火山引擎 Token
VOLC_APPID=xxx      # 火山引擎 AppID
```

## 调试

### 查看日志
```bash
supabase functions logs tts_proxy --tail
```

### 测试缓存
```bash
# 首次请求（应调用火山API）
curl -X POST \
  'https://xxx.supabase.co/functions/v1/tts_proxy' \
  -H "Authorization: Bearer YOUR_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "request": {"text": "测试句子"},
    "audio": {"voice_type": "zh_female_qingxin"}
  }' \
  --output test1.mp3

# 第二次请求（应从缓存读取）
curl -X POST \
  'https://xxx.supabase.co/functions/v1/tts_proxy' \
  -H "Authorization: Bearer YOUR_KEY" \
  -H 'Content-Type: application/json' \
  -d '{
    "request": {"text": "测试句子"},
    "audio": {"voice_type": "zh_female_qingxin"}
  }' \
  --output test2.mp3

# test1.mp3 和 test2.mp3 应完全相同
# 查看日志应显示 "🎯 从 Supabase 缓存读取"
```

## 相关文档

- [火山引擎TTS文档](https://www.volcengine.com/docs/6561/79822)
- [Supabase Storage文档](https://supabase.com/docs/guides/storage)
- [ToneUp音频服务架构](../../docs/PROJECT_OVERVIEW.md#音频服务)

## 版本历史

- **v1.0** (2026-01-27): 初始版本，支持智能缓存
