# 多语言设置使用指南

## 概述
ToneUp App 使用统一的语言代码系统，存储在用户配置文件的 `nativeLanguage` 字段中。

## 语言代码定义

### LanguageType 枚举 (推荐使用)

**位置**: `lib/models/enumerated_types.dart`

```dart
enum LanguageType {
  @JsonValue('en') english,
  @JsonValue('zh') chinese,
  @JsonValue('ja') japanese,
  @JsonValue('ko') korean,
  @JsonValue('es') spanish,
  @JsonValue('fr') french,
  @JsonValue('de') german;
  
  String get code => 'en' | 'zh' | 'ja' | 'ko' | 'es' | 'fr' | 'de';
  String get displayName => 'English' | '中文' | '日本語' | '한국어' | 'Español' | 'Français' | 'Deutsch';
}
```

### ProfileModel 字段
```dart
@JsonKey(name: "native_language")
String? nativeLanguage; // 存储语言代码字符串
```

### 支持的语言代码

| 枚举值 | 代码 | 语言 | 本地化名称 | 默认 |
|--------|------|------|-----------|------|
| `LanguageType.english` | `en` | 英语 | English | ✅ |
| `LanguageType.chinese` | `zh` | 中文 | 中文 | |
| `LanguageType.japanese` | `ja` | 日语 | 日本語 | |
| `LanguageType.korean` | `ko` | 韩语 | 한국어 | |
| `LanguageType.spanish` | `es` | 西班牙语 | Español | |
| `LanguageType.french` | `fr` | 法语 | Français | |
| `LanguageType.german` | `de` | 德语 | Deutsch | |

**默认值**: `'en'` (对应 `LanguageType.english`)

## 使用场景

### 1. 词典翻译

**方式一：使用枚举 (推荐)**:
```dart
import 'package:toneup_app/models/enumerated_types.dart';

final profile = context.read<ProfileProvider>().profile;
final languageCode = profile?.nativeLanguage ?? LanguageType.english.code;

// 或从字符串转换为枚举
final languageType = LanguageType.fromCode(profile?.nativeLanguage ?? 'en');
final languageCode = languageType.code;
```

**方式二：直接使用字符串**:
```dart
final profile = context.read<ProfileProvider>().profile;
final language = profile?.nativeLanguage ?? 'en';
```

**调用词典服务**:
```dart
final wordDetail = await SimpleDictionaryService().getWordDetail(
  word: '你好',
  language: languageCode,  // 使用语言代码
  contextTranslation: '上下文',
);
```

**扣子工作流接口**:
```dart
final result = await CozeApiService().translate(
  word: '学习',
  targetLanguage: language,  // 对应 ProfileModel.nativeLanguage
  context: '教育场景',
);
```

### 2. 练习题生成

**生成学习计划**:
```dart
final profile = context.read<ProfileProvider>().profile;

DataService().generatePlanWithProgress(
  userId: userId,
  inds: [1, 2, 3],
  dur: 60,
  acts: ['reading', 'listening'],
  nativeLanguage: profile?.nativeLanguage ?? 'en', // 传递用户母语
);
```

**扣子工作流会根据语言生成对应翻译**:
- `en` → 生成英文翻译的练习题
- `ja` → 生成日文翻译的练习题
- `ko` → 生成韩文翻译的练习题

### 3. 播客字幕翻译

```dart
// 播客播放器中获取用户语言设置
final profile = context.read<ProfileProvider>().profile;
final language = profile?.nativeLanguage ?? 'en';

// 查询词语详情时使用
final wordDetail = await _dictionaryService.getWordDetail(
  word: clickedWord,
  language: language,
  contextTranslation: segment.translation,
);
```

## 数据库存储

### profiles 表
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY,
  native_language TEXT DEFAULT 'en',
  ...
);
```

### 修改用户语言偏好
```dart
await Supabase.instance.client
  .from('profiles')
  .update({'native_language': 'ja'})
  .eq('id', userId);
```

## 扣子工作流集成

### 词典工作流 (translate-word)

**输入参数**:
```json
{
  "word": "你好",
  "target_language": "en",  // 对应 ProfileModel.nativeLanguage
  "context": "打招呼场景"
}
```

**输出**:
```json
{
  "pinyin": "nǐ hǎo",
  "summary": "hello; hi",
  "entries": [...]
}
```

### 学习计划工作流 (create-plan)

**输入参数**:
```json
{
  "user_id": "uuid",
  "inds": [1, 2, 3],
**方式一：使用枚举 (类型安全)**
```dart
import 'package:toneup_app/models/enumerated_types.dart';

// 1. 从ProfileProvider获取语言设置
final profile = context.read<ProfileProvider>().profile;

// 2. 转换为枚举并获取代码
final languageType = LanguageType.fromCode(profile?.nativeLanguage ?? 'en');
final languageCode = languageType.code;

// 3. 传递给服务方法
final result = await someService.method(
  language: languageCode,
);

// 4. 显示给用户
Text('当前语言: ${languageType.displayName}');
```

**方式二：直接使用字符串 (简单场景)**
  "dur": 60,
  "acts": ["reading"],
  "native_language": "en"  // 新增：用户母语设置
}
```

**用途**: 扣子工作流根据语言生成对应翻译的材料和练习题

## 最佳实践

### ✅ 正确做法

```dart
// 1. 从ProfileProvider获取语言设置
final profile = context.read<ProfileProvider>().profile;
final language = profile?.nativeLanguage ?? 'en';
**使用枚举验证**:
```dart
import 'package:toneup_app/models/enumerated_types.dart';

// 自动验证并提供默认值
final languageType = LanguageType.fromCode(profile?.nativeLanguage ?? 'en');
final languageCode = languageType.code; // 保证是有效的语言代码
```

**手动验证字符串**:

// 2. 传递给服务方法
final result = await someService.method(
  language: language,
);
```

### ❌ 错误做法

```dart
// 硬编码语言
final result = await someService.method(
  language: 'en',  // ❌ 应该使用用户设置
);

// 不提供默认值
final language = profile?.nativeLanguage; // ❌ 可能为null
```

### 防御性编程

```dart
// 始终提供默认值
final language = profile?.nativeLanguage ?? 'en';

// 验证语言代码
final validLanguages = ['en', 'zh', 'ja', 'ko', 'es', 'fr', 'de'];
final language = validLanguages.contains(profile?.nativeLanguage)
    ? profile!.nativeLanguage!
    : 'en';
```

## 更新检查清单

当添加新的多语言功能时，确保：

- [ ] 从 `ProfileProvider.profile.nativeLanguage` 获取语言设置
- [ ] 提供默认值 `'en'`
- [ ] 传递给相关服务方法（词典、练习题等）
- [ ] 更新扣子工作流以支持新语言
- [ ] 测试所有支持的语言代码

## 相关文档

- [DICTIONARY_DATA_STRUCTURE.md](./DICTIONARY_DATA_STRUCTURE.md) - 词典数据结构
- [DATA_MODELS.md](./DATA_MODELS.md) - ProfileModel 完整定义
- [COZE_DICTIONARY_GUIDE.md](./COZE_DICTIONARY_GUIDE.md) - 扣子词典集成

---

**维护**: ToneUp 开发团队  
**更新**: 2026-01-27
