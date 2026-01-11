# ToneUp App - 项目全局文档

> **文档版本**: v1.0  
> **更新日期**: 2026年1月11日  
> **文档用途**: 为AI助手和新开发者快速理解项目架构、数据结构、业务逻辑提供完整参考

---

## 📋 目录

- [项目概述](#项目概述)
- [核心产品定位](#核心产品定位)
- [技术架构](#技术架构)
- [数据库结构](#数据库结构)
- [核心业务模型](#核心业务模型)
- [用户体验流程](#用户体验流程)
- [商业化策略](#商业化策略)
- [开发路线图](#开发路线图)

---

## 项目概述

### 基本信息
- **项目名称**: ToneUp - 中文学习应用
- **版本**: 1.0.0+2
- **核心技术栈**: Flutter 3.35.2 + Supabase + RevenueCat
- **支持平台**: iOS / Android / Web
- **最低SDK**: iOS 13+ / Android 21+ / Web (现代浏览器)

### 技术栈详情
```yaml
Flutter SDK: 3.35.2
Dart: 3.9.0
UI Framework: Material Design 3
Backend: Supabase (PostgreSQL + Auth + Storage + Edge Functions)
Subscription: RevenueCat (iOS/Android IAP)
State Management: Provider Pattern
Routing: go_router 16.2.1
TTS Engine: 火山引擎 (VolcTTS)
Chinese Segmentation: JiebaSegmenter
```

### 核心依赖包
```yaml
# 后端服务
supabase_flutter: ^2.10.3
purchases_flutter: ^9.9.9

# 状态管理
provider: ^6.1.5+1

# 路由导航
go_router: ^16.2.1

# 第三方登录
google_sign_in: ^7.2.0
sign_in_with_apple: ^7.0.1

# 音频处理
just_audio: ^0.10.5
flutter_tts: ^4.2.3
audio_waveforms: ^1.3.0

# 中文处理
jieba_flutter: ^0.2.0
pinyin: ^3.3.0

# UI组件
carousel_slider: ^5.1.1
flutter_markdown: ^0.7.4+1
segmented_progress_bar: ^1.0.0
```

---

## 核心产品定位

### 学习系统架构

#### HSK分级体系
ToneUp基于HSK（汉语水平考试）标准将学习内容分为6个难度等级：
- **HSK 1**: 入门级（150个基础汉字）
- **HSK 2**: 初级（300个常用汉字）
- **HSK 3**: 进阶（600个汉字）
- **HSK 4**: 中级（1200个汉字）
- **HSK 5**: 高级（2500个汉字）
- **HSK 6**: 精通（5000+汉字）

#### 15维度能力指标系统
每个学习材料都通过15种指标维度进行标注和评估（详见 `enumerated_types.dart`）：

**识别能力（Recognition）**
1. `charsRecognition` - 汉字识别能力
2. `wordRecognition` - 词汇识别能力

**读写能力（Literacy）**
3. `charsReading` - 汉字阅读
4. `charsWriting` - 汉字书写
5. `wordsReading` - 词汇阅读
6. `wordsWriting` - 词汇拼写

**语言结构（Structure）**
7. `wordsBuilding` - 词汇构建
8. `grammar` - 语法理解

**听说能力（Communication）**
9. `listening` - 听力理解
10. `speaking` - 口语表达

**拼音系统（Pinyin）**
11. `pinyinRecognition` - 拼音识别
12. `pinyinReading` - 拼音阅读
13. `pinyinWriting` - 拼音拼写

**综合能力（Advanced）**
14. `sentenceReading` - 句子阅读
15. `translation` - 翻译能力

#### 材料内容分类
学习材料分为7种类型（`MaterialContentType`）：
- `character` - 单字练习
- `word` - 词汇练习
- `sentence` - 句子练习
- `dialog` - 对话练习
- `paragraph` - 段落阅读
- `syllable` - 音节练习
- `grammar` - 语法练习

#### 练习模式（9种Quiz模板）
- `selectionQuiz` - 选择题
- `fillQuiz` - 填空题
- `correctQuiz` - 改错题
- `listenQuiz` - 听力题
- `matchQuiz` - 匹配题
- `speakQuiz` - 口语练习
- `readQuiz` - 阅读题
- `writeQuiz` - 书写题
- `evalQuiz` - 综合评测

### 学习内容标签系统
- **难度标签**: `level` (HSK 1-6)
- **话题标签**: `topic_tag` (整数ID，关联话题分类如日常生活、商务、旅游等)
- **文化标签**: `culture_tag` (整数ID，关联文化主题如节日、历史、饮食等)

---

## 技术架构

### 应用架构图
```
┌─────────────────────────────────────────────┐
│              Flutter App (前端)               │
├─────────────────────────────────────────────┤
│  UI Layer                                   │
│  ├─ Pages (HomePage, PlanPage, Profile等)   │
│  ├─ Components (PremiumFeatureGate等)       │
│  └─ Theme (Material Design 3)               │
├─────────────────────────────────────────────┤
│  State Management (Provider Pattern)        │
│  ├─ ProfileProvider (用户信息)               │
│  ├─ SubscriptionProvider (订阅状态)          │
│  ├─ PlanProvider (学习计划)                  │
│  ├─ QuizProvider (练习状态)                  │
│  └─ TTSProvider (语音播放，3级缓存)           │
├─────────────────────────────────────────────┤
│  Business Logic Layer (Services)            │
│  ├─ DataService (Supabase CRUD)            │
│  ├─ RevenueCatService (订阅管理)            │
│  ├─ NativeAuthService (原生登录)            │
│  ├─ OAuthService (Web OAuth)               │
│  └─ VolcTTS (语音合成)                      │
└─────────────────────────────────────────────┘
           ↓ HTTP / WebSocket
┌─────────────────────────────────────────────┐
│           Supabase Backend                  │
│  ├─ PostgreSQL (数据存储)                    │
│  ├─ Auth (认证系统)                          │
│  ├─ Storage (图片/音频)                      │
│  ├─ Edge Functions (计划生成等)              │
│  └─ Realtime (订阅状态同步)                  │
└─────────────────────────────────────────────┘
           ↓ Webhook
┌─────────────────────────────────────────────┐
│           RevenueCat (仅移动端)              │
│  ├─ iOS: App Store IAP                      │
│  └─ Android: Google Play Billing            │
└─────────────────────────────────────────────┘
```

### Provider状态管理架构

#### Provider生命周期规范
```dart
class ExampleProvider extends ChangeNotifier {
  bool _disposed = false;
  StreamSubscription? _authSubscription;
  
  // 构造函数：初始化 + 监听auth变化
  ExampleProvider() {
    _authSubscription = Supabase.instance.client.auth
        .onAuthStateChange.listen(_handleAuthChange);
    initialize();
  }
  
  // 初始化方法
  Future<void> initialize() async {
    // 业务逻辑初始化
  }
  
  // Auth状态监听器
  void _handleAuthChange(AuthState state) {
    if (state.event == AuthChangeEvent.signedIn) {
      onUserSign(true);
    } else if (state.event == AuthChangeEvent.signedOut) {
      onUserSign(false);
    }
  }
  
  // 登录/登出处理
  void onUserSign(bool isSignedIn) {
    if (isSignedIn) {
      // 加载用户数据
    } else {
      // 清理数据
    }
    notifyListeners();
  }
  
  // 释放资源
  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
  
  // 安全更新状态
  void _safeNotify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
```

#### 关键Provider职责

**ProfileProvider**
- 用户个人信息管理（昵称、头像、等级）
- HSK等级升级检测
- 头像上传与裁剪
- 数据库字段: `profiles` 表

**SubscriptionProvider**
- 订阅状态管理（`isPro`, `expiresAt`）
- RevenueCat购买流程（仅移动端）
- Supabase订阅数据同步
- 平台感知加载（Web端只显示状态）

**PlanProvider**
- 每周学习计划管理
- 练习进度跟踪
- Edge Function调用（`create-plan`）
- 流式进度反馈

**QuizProvider**
- 练习题目加载与缓存
- 用户答题记录
- 能力评估数据提交
- TTS语音播放集成

**TTSProvider（3级缓存架构）**
```dart
L1 Cache: 内存缓存 (_audioCache Map)
    ↓ Miss
L2 Cache: 本地文件缓存 (path_provider)
    ↓ Miss
L3 Cache: 网络请求 (VolcTTS API)
    ↓
存储到 L2 → 加载到 L1 → 播放
```

### 路由系统架构

#### Shell路由（底部导航）
```dart
StatefulShellRoute(
  branches: [
    // Tab 1: 首页
    StatefulShellBranch(
      routes: [GoRoute(path: '/home', builder: HomePage)]
    ),
    // Tab 2: 计划
    StatefulShellBranch(
      routes: [GoRoute(path: '/goal_list', builder: PlanPage)]
    ),
    // Tab 3: 个人中心
    StatefulShellBranch(
      routes: [GoRoute(path: '/profile', builder: ProfilePage)]
    ),
  ]
)
```

#### 认证路由守卫
```dart
redirect: (context, state) {
  final session = Supabase.instance.client.auth.currentSession;
  final isAuthRoute = state.matchedLocation.startsWith('/login');
  
  if (session == null && !isAuthRoute) {
    return '/login'; // 未登录跳转登录页
  }
  if (session != null && isAuthRoute) {
    return '/home'; // 已登录跳转首页
  }
  return null; // 无需重定向
}
```

#### Deep Link处理
- **Apple Sign In Callback**: `toneup://login-callback`
- **Google Sign In Callback**: `toneup://login-callback`
- **Email Change**: `toneup://email-change-callback`
- **Password Reset**: `toneup://reset-password-callback`

---

## 数据库结构

### 核心数据表

#### 用户认证相关
**`profiles` (用户档案)**
```sql
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users,
  email TEXT,
  nickname TEXT,
  hsk_level INTEGER DEFAULT 1,
  target_level INTEGER DEFAULT 6,
  avatar_url TEXT,
  study_days INTEGER DEFAULT 0,
  total_exp INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- View: active_profiles (仅返回活跃用户)
```

**`subscriptions` (订阅状态)**
```sql
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users,
  is_pro BOOLEAN DEFAULT FALSE,
  product_id TEXT, -- toneup_monthly_sub / toneup_annually_sub
  expires_at TIMESTAMP,
  revenue_cat_id TEXT,
  platform TEXT, -- ios / android
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
```

#### 学习计划系统
**`user_weekly_plans` (用户学习计划)**
```sql
CREATE TABLE user_weekly_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users,
  start_date DATE,
  end_date DATE,
  status TEXT, -- 'active' | 'completed' | 'expired' | 'reactive'
  total_exp INTEGER DEFAULT 0,
  practices UUID[], -- 关联的练习ID数组
  target_inds INTEGER[], -- 目标指标ID数组
  created_at TIMESTAMP DEFAULT NOW()
);

-- View: active_user_weekly_plans (状态过滤)
```

**`user_practices` (用户练习)**
```sql
CREATE TABLE user_practices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users,
  plan_id UUID REFERENCES user_weekly_plans,
  activity_id UUID REFERENCES activities,
  status TEXT, -- 'not_started' | 'in_progress' | 'completed'
  score INTEGER,
  completion_rate FLOAT,
  quizzes JSONB[], -- 题目数据数组
  created_at TIMESTAMP DEFAULT NOW()
);

-- View: active_user_practices
```

#### 学习材料系统
**`user_materials` (学习材料)**
```sql
CREATE TABLE user_materials (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  level INTEGER, -- HSK 1-6
  topic_tag INTEGER,
  culture_tag INTEGER,
  chars TEXT[], -- 汉字数组
  words TEXT[], -- 词汇数组
  syllables TEXT[], -- 音节数组
  grammars TEXT[], -- 语法点数组
  sentences TEXT[], -- 句子数组
  paragraphs TEXT[], -- 段落数组
  dialogs JSONB[], -- 对话数据
  created_at TIMESTAMP DEFAULT NOW()
);
```

**`activities` (练习活动模板)**
```sql
CREATE TABLE activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quiz_template TEXT, -- selectionQuiz, fillQuiz 等
  quiz_type TEXT,
  material_type TEXT[], -- character, word, sentence 等
  indicator_cats INTEGER[], -- 关联的能力指标
  title TEXT,
  description TEXT
);
```

**`indicators` (能力指标定义)**
```sql
CREATE TABLE indicators (
  id SERIAL PRIMARY KEY,
  category TEXT, -- charsRecognition, grammar 等
  name TEXT,
  description TEXT,
  hsk_level INTEGER
);
```

#### 学习记录系统
**`user_score_records` (得分记录)**
```sql
CREATE TABLE user_score_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users,
  practice_id UUID REFERENCES user_practices,
  plan_id UUID REFERENCES user_weekly_plans,
  score INTEGER,
  max_score INTEGER,
  exp_gained INTEGER,
  completed_at TIMESTAMP DEFAULT NOW()
);
```

**`user_ability_history` (能力评估历史)**
```sql
CREATE TABLE user_ability_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users,
  indicator_id INTEGER REFERENCES indicators,
  ability_score FLOAT, -- 0-100分能力值
  measured_at TIMESTAMP DEFAULT NOW()
);
```

**`user_event_records` (用户行为日志)**
```sql
CREATE TABLE user_event_records (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users,
  event_type TEXT, -- 'page_view', 'practice_complete', 'purchase' 等
  event_data JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);
```

### Supabase RPC 函数

**`activate_weekly_plan(plan_id UUID)`**
- 功能: 激活指定的学习计划
- 返回: 更新后的计划数据
- 业务逻辑: 检查是否有其他active计划，将旧计划设为expired

**其他自定义函数**（根据代码grep结果）
- 计划生成、能力评估相关RPC待补充

### Edge Functions

**`create-plan` (学习计划生成)**
- 方法: POST
- 参数: `{ user_id, inds[], dur, acts[] }`
- 返回: 流式JSON进度数据
- 业务逻辑:
  1. 根据用户能力指标选择合适的学习材料
  2. 生成每日练习活动
  3. 创建计划和练习记录
  4. 实时返回生成进度

**Webhook接收**
- RevenueCat订阅事件 → 更新 `subscriptions` 表

---

## 核心业务模型

### 学习流程

#### 1. 用户注册与评估
```
注册 → 填写学习目标 (target_level) → 
能力评估测试 (EvaluationPage) → 
生成初始HSK等级 (hsk_level) → 
创建第一个学习计划
```

#### 2. 学习计划生成逻辑
```dart
// PlanProvider.generatePlan()
Stream<Map<String, dynamic>> generatePlan({
  required List<int> targetIndicators, // 选择的指标ID
  int duration = 60, // 学习时长（分钟）
  List<String>? activityTypes, // 可选：指定练习类型
}) async* {
  // 调用Edge Function: create-plan
  // 1. 查询用户当前能力数据（user_ability_history）
  // 2. 根据HSK等级和指标匹配学习材料
  // 3. 生成7天练习序列（每天多个practice）
  // 4. 写入 user_weekly_plans 和 user_practices
  // 5. 流式返回进度: { step: '材料匹配', progress: 30 }
}
```

#### 3. 练习执行流程
```
选择计划 → 选择练习 → 
加载题目 (QuizProvider.loadQuizzes()) → 
答题交互 (支持TTS语音播放) → 
提交答案 → 计算得分 → 
记录到 user_score_records → 
更新能力评估 (user_ability_history) → 
获得经验值 (total_exp += exp_gained) → 
检查是否升级
```

#### 4. HSK等级升级机制
```dart
// ProfileProvider.checkLevelUpgrade()
规则:
- 当前等级所有15个指标的平均能力值 >= 80分
- 且完成至少20个该等级的练习
→ 触发升级动画
→ hsk_level += 1
→ 解锁新的学习材料
```

### 订阅系统流程

#### 移动端购买流程
```
1. 用户点击 "Upgrade to Pro" → PaywallPage
2. 加载 RevenueCat Offerings
   - Monthly: toneup_monthly_sub (¥18/月, 7天免费试用)
   - Annual: toneup_annually_sub (¥128/年)
3. 用户选择套餐 → RevenueCat SDK 发起IAP
4. App Store/Play Store 处理支付
5. RevenueCat Webhook → Supabase subscriptions 表更新
6. SubscriptionProvider 轮询检测到变化
7. UI显示 isPro = true，解锁Pro功能
```

#### Web端流程
```
1. Web端无RevenueCat，只读取 Supabase subscriptions 表
2. 显示订阅状态 + "Download App" 按钮
3. 引导用户下载iOS/Android App完成购买
```

#### Pro功能控制
```dart
// 使用 PremiumFeatureGate 组件包裹
PremiumFeatureGate(
  featureName: 'Advanced Analytics',
  child: ProFeatureWidget(),
)

// 内部逻辑
if (!SubscriptionProvider().isPro) {
  return UpgradePrompt(); // 显示升级提示
}
return child; // 显示实际功能
```

---

## 用户体验流程

### 关键用户路径

#### Path 1: 新用户首次使用
```
1. WelcomePage (欢迎页，品牌展示)
2. SignUpPage (注册: Email + 密码)
3. EvaluationPage (能力评估测试)
4. CreateGoalPage (设置学习目标: target_level)
5. HomePage (自动生成首个学习计划)
6. 引导完成第一个练习
```

#### Path 2: 日常学习循环
```
1. HomePage → 查看今日任务
2. PlanPage → 选择活跃计划
3. PracticePage → 完成练习题目
4. 查看得分 + 获得经验值
5. 返回 HomePage → 更新进度条
```

#### Path 3: 订阅升级
```
1. ProfilePage → 点击 "Upgrade" 按钮
2. PaywallPage → 选择订阅套餐
3. 完成支付（iOS/Android）
4. 等待订阅状态同步
5. 解锁Pro功能（高级统计、无限练习等）
```

### 导航结构
```
MainShell (底部Tab导航)
├─ Tab 1: HomePage (首页)
│   └─ 快速开始练习
├─ Tab 2: PlanPage (学习计划)
│   └─ 查看所有计划与练习
└─ Tab 3: ProfilePage (个人中心)
    ├─ 个人信息
    ├─ 订阅管理 → SubscriptionManagePage
    ├─ 账户设置 → AccountSettingsPage
    ├─ HSK等级详情 → LevelDetailPage
    └─ 设置 → SettingsPage
```

---

## 商业化策略

### Freemium模型

#### 免费用户权限
- ✅ 每周1个学习计划
- ✅ 每日5个练习
- ✅ 基础能力评估
- ✅ 标准TTS语音
- ❌ 无高级统计图表
- ❌ 无历史计划回顾

#### Pro订阅权限
- ✅ 无限学习计划
- ✅ 无限练习次数
- ✅ 高级能力分析仪表盘
- ✅ 历史数据导出
- ✅ 优先客服支持
- ✅ 未来功能: Podcast学习、AI对话练习

### 定价策略
```yaml
产品ID: toneup_monthly_sub
价格: ¥18/月
试用期: 7天免费

产品ID: toneup_annually_sub
价格: ¥128/年
优惠: 相当于 ¥10.67/月 (节省41%)
试用期: 7天免费
```

### RevenueCat配置
```dart
// config.dart
class RevenueCatConfig {
  static bool useTestKey = kDebugMode; // Debug自动用测试密钥
  
  static String get apiKeyIOS => useTestKey
      ? 'test_shpnmmJxpcaomwUSHhOLGIfqrAy'
      : 'appl_PfoovuEVLvjtBrZlHZMBaHdnpqW';
  
  static String apiKeyAndroid = 'YOUR_ANDROID_API_KEY'; // 待配置
  
  static const entitlementId = 'pro_features';
}
```

### 收入追踪
- RevenueCat Dashboard: 实时订阅数据、MRR、流失率
- Supabase: `user_event_records` 记录购买事件
- 未来集成: Google Analytics 4 for Firebase

---

## 开发路线图

### ✅ 已完成 (v1.0)
- [x] 用户认证系统（Email/Password + Apple/Google SSO）
- [x] HSK分级学习系统
- [x] 15维度能力评估
- [x] 每周学习计划生成（Edge Function流式响应）
- [x] 9种练习题型模板
- [x] TTS语音播放（3级缓存）
- [x] RevenueCat订阅集成（iOS）
- [x] Web部署支持（Netlify）
- [x] 头像上传与裁剪
- [x] Material Design 3主题系统
- [x] 等级升级检测

### 🚧 开发中 (v1.1 - Q1 2026)
- [ ] **Podcast学习功能** (ListenLeap模式)
  - [ ] 数据库表设计: `media_content`, `media_segments`, `user_media_progress`
  - [ ] 管理端CMS（管理员上传音频/视频）
  - [ ] UGC用户上传（30%内容占比，严格审核）
  - [ ] AI自动分段（Whisper STT + GPT-4）
  - [ ] 播放器UI（支持逐句跟读、字幕显示）
  - [ ] 进度同步与推荐算法
- [ ] Android订阅配置（Google Play Billing）
- [ ] 高级统计仪表盘（Pro功能）
- [ ] 离线模式支持

### 📅 计划中 (v2.0 - Q2-Q3 2026)
- [ ] **AIGC内容生产流水线**
  - [ ] GPT-4o脚本生成（话题 → 学习脚本）
  - [ ] Whisper音频转录 + 时间戳对齐
  - [ ] TTS音频合成（火山引擎 → 自建Coqui TTS）
  - [ ] DALL-E 3封面图生成
  - [ ] 自动化发布工作流
  - [ ] 成本目标: $3.10/集 (vs 人工 $95/集)
- [ ] AI对话练习（GPT-4 Turbo集成）
- [ ] 社区学习小组功能
- [ ] 家长监控Dashboard（教育版）

### 🔮 长期规划 (v3.0+)
- [ ] AR字卡识别（Apple Vision Pro / ARKit）
- [ ] 实时语音评分（发音准确度）
- [ ] 企业培训版（B2B）
- [ ] 多语言扩展（日语、韩语）

---

## 附录

### 开发环境配置

#### 必需工具
```bash
flutter --version  # 需要 3.35.2+
dart --version     # 需要 3.9.0+
```

#### iOS开发
```bash
# Xcode 15+
# CocoaPods
cd ios && pod install

# StoreKit测试
# 启用: Edit Scheme → Run → Options → StoreKit Configuration
# 文件: ios/ToneUpProducts.storekit
```

#### Android开发
```bash
# Android Studio 2023.1+
# SDK 21-34
# 配置密钥: android/key.properties
```

#### Supabase本地开发
```bash
# 使用 Supabase CLI
supabase start
supabase db reset  # 重置数据库
```

### 代码规范

#### 命名约定
- **文件**: `snake_case.dart`
- **类**: `PascalCase`
- **变量/方法**: `camelCase`
- **常量**: `UPPER_SNAKE_CASE`
- **私有成员**: `_leadingUnderscore`

#### 导入规范
```dart
// ✅ 使用绝对导入
import 'package:toneup_app/services/data_service.dart';

// ❌ 避免相对导入
import '../services/data_service.dart';
```

#### Provider更新模式
```dart
// ✅ 正确
_data = newData;
if (!_disposed) {
  notifyListeners();
}

// ❌ 错误 (不检查dispose状态)
_data = newData;
notifyListeners();
```

### 平台适配检查清单

#### 移动端专用功能
- [ ] RevenueCat购买流程
- [ ] Native Auth (Apple/Google Sign In)
- [ ] 相机/相册访问
- [ ] 本地文件缓存

#### Web端专用处理
- [ ] 跳过RevenueCat初始化
- [ ] OAuth浏览器流程
- [ ] 显示应用下载链接
- [ ] 响应式布局适配

#### 平台检测工具
```dart
import 'package:toneup_app/services/config.dart';

if (PlatformUtils.isWeb) {
  // Web逻辑
} else if (PlatformUtils.isMobile) {
  // 移动端逻辑
}
```

### 常见问题排查

**Q: RevenueCat初始化失败 (Configuration error 23)**
```
A: 检查Xcode Scheme设置是否启用StoreKit Configuration
   路径: Edit Scheme → Run → Options → StoreKit Configuration
```

**Q: 订阅购买后状态未更新**
```
A: 1. 检查RevenueCat Webhook是否配置
   2. 查询Supabase subscriptions表是否有数据
   3. 确认SubscriptionProvider已初始化
```

**Q: Web端报错 "PurchasesFlutter not supported on this platform"**
```
A: 检查是否有未包裹的RevenueCat调用
   应在所有RevenueCat代码前添加:
   if (kIsWeb) return;
```

**Q: TTS播放失败**
```
A: 1. 检查网络连接（L3缓存需网络）
   2. 查看VolcTTS API密钥是否有效
   3. 确认文本内容不为空
```

---

## 文档维护

本文档应在以下情况更新：
- ✏️ 添加新的数据表或字段
- ✏️ 修改订阅流程或定价策略
- ✏️ 新增核心功能模块
- ✏️ 更新技术栈版本
- ✏️ 修改业务逻辑规则

**文档责任人**: 项目负责人  
**审核周期**: 每月1次  
**版本控制**: Git + 语义化版本号

---

**📌 提示**: 本文档为AI助手快速理解项目设计，人类开发者请同时参考：
- `docs/THIRD_PARTY_AUTH.md` - 第三方登录详细实现
- `docs/TESTING_GUIDE.md` - 测试策略与用例
- `docs/WEB_DEPLOYMENT.md` - Web部署指南
- `.github/copilot-instructions.md` - AI Copilot工作流规范
