# MDX 离线词典使用指南

## 📚 什么是 MDX 词典？

MDX (MDict) 是最流行的离线词典格式，支持：
- ✅ 完整的词典数据（拼音、词性、例句、用法等）
- ✅ HTML格式渲染（支持复杂排版）
- ✅ 多语言支持（汉英、汉日、汉韩等）
- ✅ 专业词典资源（现代汉语词典、新华字典、CC-CEDICT等）

**⚠️ 重要**：ToneUp是中文学习APP，需要下载**汉英词典**（Chinese→English），而不是英汉词典！

## 🎯 快速开始（5分钟配置）

### 步骤1：下载词典文件

**推荐词典资源站**：

1. **FreeMDict**（国际）
   - 网址：https://freemdict.com/
   - 搜索关键词：**"Chinese English"** 或 **"汉英"**
   - 推荐下载：
     * **CC-CEDICT** (Chinese-English Dictionary) - 免费开源，12万词条
     * **现代汉语词典** (Modern Chinese Dictionary) - 权威，带英文释义
     * **新华字典 English** - 基础汉字学习

2. **掌上百科**（国内，需翻墙）
   - 网址：https://www.pdawiki.com/forum/
   - 需注册账号
   - 搜索：**"汉英"** 或 **"Chinese-English"**
   - 推荐词典：
     * **新时代汉英大词典** - 专业级
     * **外研社汉英词典** - 学习型

3. **MDict官方资源**
   - 网址：https://www.mdict.cn/
   - 词典质量参差不齐，建议先用FreeMDict

**文件格式**：
- `.mdx` - 词典主文件（必需）
- `.mdd` - 媒体文件（可选，包含图片/音频）

### 步骤2：放置词典文件

1. 在项目根目录创建词典目录：
```bash
mkdir -p assets/dictionaries
```

2. 将下载的 `.mdx` 文件复制到该目录：
```bash
# 示例
assets/
  dictionaries/
    cedict.mdx                # CC-CEDICT 汉英词典（推荐入门）
    modern-chinese.mdx        # 现代汉语词典
    xinhua-english.mdx        # 新华字典英文版
```

### 步骤3：配置 pubspec.yaml

确保词典目录在 `pubspec.yaml` 的 assets 配置中：

```yaml
flutter:
  assets:
    # ... 其他 assets
    - assets/dictionaries/
```

### 步骤4：运行应用

```bash
flutter pub get
flutter run
```

应用启动时会自动加载词典，查看日志：
```
📚 开始加载MDX词典...
📖 开始加载词典: cedict
✅ 词典加载成功: cedict (120000 词条)
🎉 MDX词典服务初始化完成，已加载 1 个词典
```

**测试查询**：
- 查询"你好" → 应返回 "hello; hi"
- 查询"学习" → 应返回 "to study; to learn"

## 📖 推荐词典列表

### 汉英词典（必备）

| 词典名称 | 文件大小 | 词条数 | 特点 | 下载优先级 |
|---------|---------|-------|------|----------|
| **CC-CEDICT** | ~8MB | 120,000 | 免费开源，更新活跃 | ⭐⭐⭐⭐⭐ |
| **新时代汉英大词典** | ~150MB | 200,000+ | 最权威，例句丰富 | ⭐⭐⭐⭐⭐ |
| **外研社现代汉英词典** | ~80MB | 150,000 | 学习型词典，搭配详细 | ⭐⭐⭐⭐ |
| **新华字典（英文版）** | ~20MB | 20,000 | 基础汉字，适合初学者 | ⭐⭐⭐⭐ |

### 专项词典（可选）

| 词典名称 | 用途 | 推荐场景 |
|---------|------|---------|
| **成语词典（英文版）** | 成语解释 | 高级学习 |
| **现代汉语分类词典** | 分类词汇 | 主题学习 |
| **汉语常用词用法词典** | 词语搭配 | 写作练习 |

## 🔧 高级配置

### 自定义加载词典

修改 `lib/main.dart` 中的初始化逻辑：

```dart
Future<void> _initializeMdxDictionaries() async {
  final mdxService = MdxDictionaryService();
  
  // 自定义词典列表
  final dictionaries = [
    'assets/dictionaries/cedict.mdx',           // CC-CEDICT 汉英词典
    'assets/dictionaries/modern-chinese.mdx',   // 现代汉语词典
  ];
  
  await mdxService.initialize(dictionaries);
}
```

### 动态选择词典

```dart
import 'package:toneup_app/services/mdx_dictionary_service.dart';

// 查询特定词典
final mdxService = MdxDictionaryService();
final result = await mdxService.lookup(
  '你好',  // 查询中文词
  dictionaryName: 'cedict',
);
// 返回: "hello; hi; how are you"

// 查询所有已加载词典（按顺序）
final result = await mdxService.lookup('学习');
// 返回: "to study; to learn; learning"

// 获取已加载词典列表
final dicts = mdxService.getLoadedDictionaries();
print('已加载: $dicts'); // ['cedict', 'modern-chinese']
```

### 词典信息查询

```dart
final info = mdxService.getDictionaryInfo('cedict');
print(info);
// {
//   'name': 'cedict',
//   'entryCount': 120000,
//   'description': 'CC-CEDICT Chinese-English Dictionary',
//   'encoding': 'UTF-8'
// }
```

## 🎨 HTML渲染

MDX词典返回的是HTML格式内容，使用 `flutter_html` 渲染：

```dart
import 'package:flutter_html/flutter_html.dart';

// 在UI中显示词典内容
Html(
  data: dictionaryHtmlContent,
  style: {
    'body': Style(fontSize: FontSize(16)),
    '.def': Style(color: Colors.blue),
  },
)
```

## 📊 性能优化

### 缓存策略

ToneUp 使用四级缓存：
```
L1: 内存缓存（最快）
  ↓ 未命中
L2: SQLite本地缓存
  ↓ 未命中
L3: Supabase云端缓存
  ↓ 未命中
L4: MDX离线词典（本地查询）
  ↓
保存到 L3 → L2 → L1
```

首次查询后，词条会自动缓存，后续查询秒级响应。

### 启动优化

词典加载在后台进行，不阻塞应用启动：
```dart
// main.dart
_initializeMdxDictionaries(); // 异步加载，不await
runApp(const MyApp());
```

### 内存管理

大型词典（150MB+）加载后占用内存约 50-100MB，建议：
- 移动端：最多加载 2-3 个词典
- 桌面端：可加载 5+ 个词典

释放资源：
```dart
MdxDictionaryService().dispose();
```

## 🐛 常见问题

### Q1: 启动时提示"未找到MDX词典文件"

**原因**：词典文件未放置在正确位置或 `pubspec.yaml` 未配置

**解决**：
1. 检查文件路径：`assets/dictionaries/*.mdx`
2. 运行 `flutter clean && flutter pub get`
3. 查看 `pubspec.yaml` 是否包含 `- assets/dictionaries/`

### Q2: 查询时返回 null

**可能原因**：
1. 词典未加载完成（启动后立即查询）
2. 词条不存在
3. 查询词格式问题（MDX通常小写）

**解决**：
```dart
// 检查词典状态
if (MdxDictionaryService().isInitialized) {
  final result = await mdxService.lookup('hello');
}
```

### Q3: 词典加载速度慢

**正常耗时**：
- 小型词典（20MB）：1-2秒
- 中型词典（100MB）：3-5秒
- 大型词典（200MB+）：5-10秒

**优化建议**：
- 使用较小的词典文件
- 词典加载后台进行（不阻塞UI）

### Q4: HTML内容显示异常

**原因**：词典HTML包含特殊样式/脚本

**解决**：
```dart
Html(
  data: htmlContent,
  customRenders: {
    tagMatcher('script'): CustomRender.widget(
      widget: (context, buildChildren) => const SizedBox.shrink(),
    ),
  },
)
```

## 📱 移动端特殊配置

### iOS 配置

词典文件过大可能导致编译失败，需调整：

`ios/Runner/Info.plist`：
```xml
<key>CFBundleResourceRules</key>
<dict>
  <key>.*</key>
  <true/>
</dict>
```

### Android 配置

大文件可能需要启用压缩：

`android/app/build.gradle`：
```gradle
android {
    aaptOptions {
        noCompress "mdx", "mdd"
    }
}
```

## 🚀 扩展功能

### 添加新语言支持

下载对应语言的MDX词典即可：
- **汉日词典**：现代汉日词典
- **汉韩词典**：汉韩词典
- **汉德词典**：汉德大词典
- **汉法词典**：汉法词典

**注意**：针对不同母语用户，可加载对应的汉语-目标语言词典

### 自制MDX词典

使用 **MdxBuilder** 工具：
1. 准备 CSV/TXT 词条数据
2. 使用 MdxBuilder 转换为 `.mdx` 格式
3. 放入 `assets/dictionaries/` 即可使用

工具下载：https://www.pdawiki.com/forum/thread-11710-1-1.html

## 📚 参考资源

- **MDict官网**：https://www.mdict.cn/
- **FreeMDict词典库**：https://freemdict.com/
- **掌上百科论坛**：https://www.pdawiki.com/
- **dict_reader文档**：https://pub.dev/packages/dict_reader

## 💡 最佳实践

1. **优先使用轻量级词典**
   - 开发阶段：使用 CC-CEDICT（8MB）快速测试
   - 生产环境：根据用户反馈添加更专业词典

2. **按需加载**
   - 默认加载1个核心汉英词典
   - 提供设置界面让用户选择多语言词典（汉日、汉韩等）

3. **定期更新**
   - CC-CEDICT 每月更新，关注 GitHub releases
   - 其他词典每年检查更新

4. **结合在线API**
   - MDX词典未覆盖的词条使用在线API补充
   - 网络流行语、新词优先使用有道API
   - 专业术语可用MDX专业词典

---

**需要帮助？**
- 查看日志：搜索 `📚` emoji 查看词典加载状态
- 提交Issue：https://github.com/your-repo/issues
- 加入社区：词典配置问题可在社区讨论
