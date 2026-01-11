# ToneUp App - API 参考文档

> **文档版本**: v1.0  
> **更新日期**: 2026年1月11日  
> **用途**: 完整的Supabase API、Edge Functions、第三方服务API使用指南

---

## 📑 目录

- [Supabase 数据库 API](#supabase-数据库-api)
- [Supabase Edge Functions](#supabase-edge-functions)
- [Supabase RPC 函数](#supabase-rpc-函数)
- [Supabase Storage API](#supabase-storage-api)
- [RevenueCat API](#revenuecat-api)
- [火山引擎 TTS API](#火山引擎-tts-api)
- [第三方认证 API](#第三方认证-api)

---

## Supabase 数据库 API

### DataService 核心方法

#### 学习计划相关

**`fetchPlans(String userId)`**
```dart
/// 查询用户所有学习计划（按创建时间排序）
Future<List<UserWeeklyPlanModel>> fetchPlans(String userId)

// 使用示例
final plans = await DataService().fetchPlans(currentUser.id);

// 返回数据
[
  UserWeeklyPlanModel {
    id: "uuid-123",
    userId: "user-456",
    startDate: 2026-01-06,
    endDate: 2026-01-12,
    status: active,
    practices: ["practice-1", "practice-2"]
  }
]
```

**API详情**:
- **表**: `active_user_weekly_plans`
- **排序**: `created_at ASC`
- **过滤**: `user_id = userId`

---

**`fetchActivePlan(String userId)`**
```dart
/// 查询用户当前活跃计划（只返回1条）
Future<UserWeeklyPlanModel?> fetchActivePlan(String userId)

// 使用示例
final activePlan = await DataService().fetchActivePlan(userId);
if (activePlan == null) {
  print('没有活跃计划');
}

// 返回数据
UserWeeklyPlanModel { status: active } 或 null
```

**API详情**:
- **表**: `active_user_weekly_plans`
- **过滤**: `user_id = userId AND (status = 'active' OR status = 'reactive')`
- **限制**: `LIMIT 1`
- **排序**: `created_at DESC`

---

**`setupPracticetoPlan(UserWeeklyPlanModel? plan)`**
```dart
/// 加载计划关联的练习数据，填充到 practiceData 字段
Future<UserWeeklyPlanModel?> setupPracticetoPlan(plan)

// 使用示例
var plan = await DataService().fetchActivePlan(userId);
plan = await DataService().setupPracticetoPlan(plan);
// plan.practiceData 现在包含完整的练习对象

// 返回数据
UserWeeklyPlanModel {
  practiceData: [
    UserPracticeModel { id: "practice-1", status: "completed" },
    UserPracticeModel { id: "practice-2", status: "not_started" }
  ]
}
```

**API详情**:
- **表**: `active_user_practices`
- **过滤**: `id IN plan.practices`
- **特殊处理**: 按 `plan.practices` 数组顺序重新排序

---

**`markActivePlanComplete(UserWeeklyPlanModel plan)`**
```dart
/// 标记计划为已完成状态
Future<void> markActivePlanComplete(plan)

// 使用示例
await DataService().markActivePlanComplete(currentPlan);
```

**API详情**:
- **表**: `user_weekly_plans`
- **更新**: `status = 'reactive'`
- **过滤**: `id = plan.id`

---

**`markPlanAsActive(String userId, UserWeeklyPlanModel plan)`**
```dart
/// 激活指定计划（通过RPC函数，自动处理状态冲突）
Future<UserWeeklyPlanModel?> markPlanAsActive({
  required String userId,
  required UserWeeklyPlanModel plan,
})

// 使用示例
final activated = await DataService().markPlanAsActive(
  userId: user.id,
  plan: pendingPlan,
);

// 返回数据
UserWeeklyPlanModel { status: active }
```

**API详情**:
- **RPC函数**: `activate_plan(p_user_id, p_plan_id)`
- **业务逻辑**: 将用户其他active计划设为pending，激活目标计划

---

#### 练习题目相关

**`fetchQuizesByIds(List<int> data)`**
```dart
/// 根据ID数组获取题目数据
Future<List<QuizesModle>> fetchQuizesByIds(List<int> data)

// 使用示例
final quizzes = await DataService().fetchQuizesByIds([101, 102, 103]);

// 返回数据
[QuizesModle { id: 101, question: "..." }]
```

**API详情**:
- **表**: `active_quizes`
- **过滤**: `id IN data`

---

**`generateQuizesContent(List<int> data)`**
```dart
/// 调用Edge Function生成题目实例
Future<List<QuizesModle>> generateQuizesContent(List<int> data)

// 使用示例
final quizzes = await DataService().generateQuizesContent([1, 2, 3]);

// 返回数据
[
  QuizesModle {
    activityId: "act-123",
    question: "选择正确的拼音",
    options: ["nǐ", "ní"],
    correctAnswer: 0
  }
]
```

**API详情**:
- **Edge Function**: `get_activity_instances`
- **请求体**: `{ "ids": "[1,2,3]" }`
- **响应**: HTTP 200, JSON数组

---

**`saveResultScores(List<QuizBase> quizzes, UserPracticeModel practice)`**
```dart
/// 保存练习得分，更新4个表：
/// 1. user_practices (练习总分)
/// 2. user_score_records (单题得分)
/// 3. user_ability_history (能力评估)
Future<void> saveResultScores(quizzes, practice)

// 使用示例
await DataService().saveResultScores(completedQuizzes, currentPractice);
```

**业务逻辑**:
1. **计算总分**: `totalScore = sum(quiz.result.score) / quizzes.length`
2. **更新练习表**: RPC `increment_practice_count(practice_id, new_score)`
3. **保存单题记录**:
   ```sql
   INSERT INTO user_score_records (category, item, score, user_id)
   VALUES (...), (...)
   ```
4. **保存能力评估**:
   ```sql
   INSERT INTO user_ability_history (user_id, indicator_id, score)
   VALUES (...), (...)
   ```

---

#### 用户档案相关

**`fetchProfile(String userId)`**
```dart
/// 获取用户档案
Future<ProfileModel?> fetchProfile(String userId)

// 使用示例
final profile = await DataService().fetchProfile(user.id);
print('等级: ${profile.level}, 经验: ${profile.exp}');

// 返回数据
ProfileModel {
  id: "user-123",
  nickname: "学习者",
  level: 3,
  exp: 1250,
  streakDays: 7
}
```

**API详情**:
- **视图**: `active_profiles`
- **过滤**: `id = userId`

---

**`saveProfile(ProfileModel profile)`**
```dart
/// 保存/更新用户档案（Upsert操作）
Future<void> saveProfile(ProfileModel profile)

// 使用示例
profile.nickname = "新昵称";
profile.level = 4;
await DataService().saveProfile(profile);
```

**API详情**:
- **表**: `profiles`
- **操作**: `UPSERT ON CONFLICT (id)`
- **说明**: 存在则更新，不存在则插入

---

**`fetchUserScoreRecord(String userId)`**
```dart
/// 获取用户学习材料得分记录
Future<List<UserScoreRecordsModel>> fetchUserScoreRecord(userId)

// 使用示例
final records = await DataService().fetchUserScoreRecord(user.id);
// 返回所有汉字、词汇、句子的学习记录

// 返回数据
[
  UserScoreRecordsModel {
    item: "你",
    category: character,
    score: 95.5,
    createdAt: 2026-01-10
  }
]
```

**API详情**:
- **表**: `user_score_records`
- **过滤**: 
  - `user_id = userId`
  - `score > 0`
  - `category IN ['character', 'word', 'sentence']`

---

#### 能力评估相关

**`getUserIndicatorResult(String userId, int level)`**
```dart
/// 获取用户当前级别的指标完成情况
Future<IndicatorResultModel> getUserIndicatorResult(userId, level)

// 使用示例
final result = await DataService().getUserIndicatorResult(user.id, 3);
print('完成进度: ${result.completionRate}%');

// 返回数据
IndicatorResultModel {
  indicators: [
    { id: 1, name: "辨认汉字", score: 85.5, practiceCount: 10 }
  ],
  completionRate: 72.3,
  canUpgrade: false
}
```

**API详情**:
- **Edge Function**: `check_for_upgrade`
- **请求体**: `{ "user_id": "...", "level": 3 }`
- **业务逻辑**: 查询15个指标的练习数和平均分，判断是否达到升级条件

---

**`getFocusedIndicators(List<IndicatorCoreDetailModel> indicators, {int quantity = 3})`**
```dart
/// 计算并返回重点关注的指标（根据优先级得分）
Future<List<IndicatorCoreDetailModel>> getFocusedIndicators(indicators)

// 使用示例
final focusedInds = await DataService().getFocusedIndicators(
  allIndicators,
  quantity: 3
);
// 返回最需要练习的3个指标
```

**优先级计算公式**:
```dart
priorityScore = 
  indicatorWeight * 0.4        // 指标重要性
  + gapRatio * 0.35            // 达标差距占比
  + insufficientScore * 0.25   // 完成度不足
```

---

#### 其他工具方法

**`saveImage(String url, Uint8List data)`**
```dart
/// 上传用户头像到Supabase Storage
Future<void> saveImage(String url, Uint8List data)

// 使用示例
final imageBytes = await file.readAsBytes();
await DataService().saveImage('avatars/user-123.jpg', imageBytes);
```

**API详情**:
- **Bucket**: `images`
- **Options**: `upsert: true` (存在则覆盖)

---

**`getImage(String url)`**
```dart
/// 从Storage下载图片
Future<Uint8List> getImage(String url)

// 使用示例
final avatarData = await DataService().getImage('avatars/user-123.jpg');
```

**API详情**:
- **Bucket**: `images`
- **方法**: `download(url)`

---

**`saveExp(double exp, {String userId, String title})`**
```dart
/// 保存经验值记录并返回总经验
Future<double> saveExp(exp, {userId, title})

// 使用示例
final totalExp = await DataService().saveExp(
  50.0,
  userId: user.id,
  title: "完成每日练习"
);
```

**业务逻辑**:
1. 插入经验值事件到 `user_event_records`
2. 查询该用户所有经验值记录
3. 累加返回总经验值

---

## Supabase Edge Functions

### create-plan (学习计划生成)

**功能**: 根据用户能力和目标指标生成个性化学习计划。

**请求方式**: `POST`

**URL**: `https://kixonwnuivnjqlraydmz.supabase.co/functions/v1/create-plan`

**请求头**:
```http
Content-Type: application/json
Authorization: Bearer {ACCESS_TOKEN}
apikey: {SUPABASE_ANON_KEY}
```

**请求体**:
```json
{
  "user_id": "uuid-123",
  "inds": [1, 2, 3, 5],          // 目标指标ID数组
  "dur": 60,                     // 学习时长（分钟）
  "acts": ["act-1", "act-2"]     // 可选：指定活动ID
}
```

**响应格式**: 流式JSON（Server-Sent Events）

**响应示例**:
```json
{"step": "材料匹配", "progress": 10}
{"step": "生成练习", "progress": 30}
{"step": "题目生成", "progress": 60}
{"step": "保存计划", "progress": 90}
{"step": "完成", "progress": 100, "planId": "plan-uuid"}
```

**客户端调用**:
```dart
final service = DataService();
await for (final event in service.generatePlanWithProgress(
  userId: userId,
  inds: [1, 2, 3],
  dur: 60,
)) {
  print('进度: ${event['progress']}%');
  if (event['step'] == '完成') {
    final planId = event['planId'];
  }
}
```

**错误响应**:
- **401**: 未认证
- **400**: 参数错误
- **500**: 服务器错误

---

### get_activity_instances (题目实例生成)

**功能**: 根据活动ID生成具体题目内容。

**请求方式**: `POST`

**URL**: `{SUPABASE_URL}/functions/v1/get_activity_instances`

**请求体**:
```json
{
  "ids": "[1, 2, 3]"  // JSON字符串格式的ID数组
}
```

**响应示例**:
```json
[
  {
    "id": 1,
    "activityId": "act-123",
    "indicatorId": 5,
    "question": "选择正确的拼音",
    "options": ["nǐ", "ní", "nì"],
    "correctAnswer": 0,
    "explanation": "第三声"
  }
]
```

**客户端调用**:
```dart
final quizzes = await DataService().generateQuizesContent([1, 2, 3]);
```

---

### check_for_upgrade (升级检查)

**功能**: 检查用户当前等级的学习完成情况。

**请求方式**: `POST`

**URL**: `{SUPABASE_URL}/functions/v1/check_for_upgrade`

**请求体**:
```json
{
  "user_id": "uuid-123",
  "level": 3
}
```

**响应示例**:
```json
{
  "indicators": [
    {
      "id": 1,
      "name": "辨认汉字",
      "category": "charsRecognition",
      "practiceCount": 15,
      "minimum": 20,
      "practiceGap": 5,
      "averageScore": 85.5
    }
  ],
  "completionRate": 72.3,
  "canUpgrade": false,
  "nextLevelUnlocked": false
}
```

**升级条件**:
- 所有15个指标的 `averageScore >= 80`
- 完成至少20个该等级的练习

**客户端调用**:
```dart
final result = await DataService().getUserIndicatorResult(userId, level);
if (result.canUpgrade) {
  // 触发升级动画
}
```

---

## Supabase RPC 函数

### activate_plan

**功能**: 激活指定学习计划，将其他active计划设为pending。

**调用方式**:
```dart
final result = await _supabase.rpc('activate_plan', params: {
  'p_user_id': 'user-uuid',
  'p_plan_id': 'plan-uuid'
});
```

**SQL定义**:
```sql
CREATE OR REPLACE FUNCTION activate_plan(
  p_user_id UUID,
  p_plan_id UUID
) RETURNS SETOF user_weekly_plans AS $$
BEGIN
  -- 将该用户其他active计划设为pending
  UPDATE user_weekly_plans
  SET status = 'pending'
  WHERE user_id = p_user_id
    AND status = 'active'
    AND id != p_plan_id;
  
  -- 激活目标计划
  UPDATE user_weekly_plans
  SET status = 'active'
  WHERE id = p_plan_id;
  
  RETURN QUERY SELECT * FROM user_weekly_plans WHERE id = p_plan_id;
END;
$$ LANGUAGE plpgsql;
```

---

### increment_practice_count

**功能**: 更新练习的完成次数和得分。

**调用方式**:
```dart
final data = await _supabase.rpc('increment_practice_count', params: {
  'practice_id': 'practice-uuid',
  'new_score': 85.5
});
```

**SQL定义**:
```sql
CREATE OR REPLACE FUNCTION increment_practice_count(
  practice_id UUID,
  new_score FLOAT
) RETURNS SETOF user_practices AS $$
BEGIN
  UPDATE user_practices
  SET 
    count = count + 1,
    score = (score * count + new_score) / (count + 1)
  WHERE id = practice_id;
  
  RETURN QUERY SELECT * FROM user_practices WHERE id = practice_id;
END;
$$ LANGUAGE plpgsql;
```

---

### random_evaluation (评测题目生成)

**功能**: 随机生成指定等级的评测题目。

**调用方式**:
```dart
final quizzes = await _supabase
    .schema('research_core')
    .rpc('random_evaluation', params: {
      'level_input': 3,
      'n': 10
    });
```

**SQL定义**:
```sql
CREATE OR REPLACE FUNCTION random_evaluation(
  level_input INT,
  n INT
) RETURNS SETOF quizes AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM quizes
  WHERE level = level_input
  ORDER BY RANDOM()
  LIMIT n;
END;
$$ LANGUAGE plpgsql;
```

---

## Supabase Storage API

### images Bucket

**用途**: 存储用户头像和其他图片资源。

**上传文件**:
```dart
await _supabase.storage
    .from('images')
    .uploadBinary(
      'avatars/user-123.jpg',
      imageBytes,
      fileOptions: FileOptions(upsert: true)
    );
```

**下载文件**:
```dart
final bytes = await _supabase.storage
    .from('images')
    .download('avatars/user-123.jpg');
```

**获取公开URL**:
```dart
final url = _supabase.storage
    .from('images')
    .getPublicUrl('avatars/user-123.jpg');
```

**删除文件**:
```dart
await _supabase.storage
    .from('images')
    .remove(['avatars/user-123.jpg']);
```

---

## RevenueCat API

### RevenueCatService 方法

**`initialize()`**
```dart
/// 初始化RevenueCat SDK（自动区分iOS/Android）
Future<void> initialize()

// 使用示例
await RevenueCatService().initialize();
```

**平台配置**:
- **iOS**: `appl_PfoovuEVLvjtBrZlHZMBaHdnpqW` (生产)
- **Android**: `YOUR_ANDROID_API_KEY` (待配置)
- **Test**: `test_shpnmmJxpcaomwUSHhOLGIfqrAy` (Debug模式自动使用)

---

**`login(String userId)`**
```dart
/// 登录后设置RevenueCat用户ID
Future<void> login(String userId)

// 使用示例
await RevenueCatService().login(Supabase.instance.client.auth.currentUser!.id);
```

---

**`logout()`**
```dart
/// 登出RevenueCat
Future<void> logout()

// 使用示例
await RevenueCatService().logout();
```

---

**`getOfferings()`**
```dart
/// 获取可用的订阅产品
Future<Offerings?> getOfferings()

// 使用示例
final offerings = await RevenueCatService().getOfferings();
final monthly = offerings.current?.monthly;
final annual = offerings.current?.annual;

// 返回数据
Offerings {
  current: Offering {
    monthly: Package {
      product: StoreProduct {
        identifier: "toneup_monthly_sub",
        price: "¥18.00",
        priceString: "¥18.00/月",
        introPrice: "免费试用7天"
      }
    },
    annual: Package { ... }
  }
}
```

---

**`purchasePackage(Package package)`**
```dart
/// 购买订阅套餐
Future<CustomerInfo> purchasePackage(Package package)

// 使用示例
try {
  final customerInfo = await RevenueCatService().purchasePackage(monthly);
  if (customerInfo.entitlements.active.containsKey('pro_features')) {
    // 订阅成功
  }
} on PlatformException catch (e) {
  if (e.code == 'purchaseCancelledError') {
    // 用户取消
  }
}
```

**可能的异常**:
- `purchaseCancelledError` - 用户取消购买
- `productAlreadyPurchasedError` - 已购买
- `networkError` - 网络错误

---

**`getCustomerInfo()`**
```dart
/// 获取当前用户订阅信息
Future<CustomerInfo> getCustomerInfo()

// 使用示例
final info = await RevenueCatService().getCustomerInfo();
final isPro = info.entitlements.active.containsKey('pro_features');
final expiresAt = info.entitlements.active['pro_features']?.expirationDate;

// 返回数据
CustomerInfo {
  entitlements: {
    active: {
      'pro_features': EntitlementInfo {
        identifier: "pro_features",
        isActive: true,
        expirationDate: "2026-02-01T00:00:00Z"
      }
    }
  }
}
```

---

**`syncSubscriptionToSupabase()`**
```dart
/// 将RevenueCat订阅状态同步到Supabase
Future<void> syncSubscriptionToSupabase()

// 使用示例
await RevenueCatService().syncSubscriptionToSupabase();
```

**同步逻辑**:
1. 从RevenueCat获取 `CustomerInfo`
2. 提取 `pro_features` entitlement
3. Upsert到Supabase `subscriptions` 表:
   ```dart
   {
     'user_id': userId,
     'is_pro': entitlement.isActive,
     'expires_at': entitlement.expirationDate,
     'revenue_cat_id': customerId,
     'platform': Platform.isIOS ? 'ios' : 'android'
   }
   ```

---

## 火山引擎 TTS API

### VolcTTS 服务方法

**`synthesizeEF(String text, {String voiceType = 'BV001_streaming'})`**
```dart
/// 云端TTS语音合成
Future<Uint8List> synthesizeEF(String text, {String voiceType})

// 使用示例
final audioData = await VolcTTS().synthesizeEF('你好世界');
await audioPlayer.setAudioSource(BytesSource(audioData));
```

**支持的语音类型**:
- `BV001_streaming` - 标准女声
- `BV002_streaming` - 标准男声
- `zh_female_tianmeiruixin_moon_bigtts` - 甜美女声
- `zh_male_xuefengyousheng_moon_bigtts` - 浑厚男声

**API配置**:
- **App ID**: 存储在环境变量
- **Access Token**: 需要定期刷新
- **请求格式**: HTTP POST, Content-Type: application/json

---

**`speakLocal(String text)`**
```dart
/// 系统本地TTS播放
Future<void> speakLocal(String text)

// 使用示例
await VolcTTS().speakLocal('你好');
```

**说明**: 使用 `flutter_tts` 包调用系统TTS引擎，无需网络。

---

## 第三方认证 API

### Apple Sign In

**`NativeAuthService.signInWithApple()`**
```dart
/// Apple原生登录
Future<AuthResponse> signInWithApple()

// 使用示例
try {
  final response = await NativeAuthService().signInWithApple();
  final user = response.user;
} catch (e) {
  print('Apple登录失败: $e');
}
```

**流程**:
1. 调用 `sign_in_with_apple` 包
2. 获取 `idToken`
3. 调用 Supabase: `signInWithIdToken(provider: 'apple', idToken)`

**Deep Link回调**: `toneup://login-callback`

---

### Google Sign In

**`NativeAuthService.signInWithGoogle()`**
```dart
/// Google原生登录
Future<AuthResponse> signInWithGoogle()

// 使用示例
final response = await NativeAuthService().signInWithGoogle();
```

**配置要求**:
- **移动端**: 需要 `serverClientId` (iOS/Android不同)
- **Web**: `serverClientId: null`
- **Supabase**: 必须启用 "Skip nonce checks"

**流程**:
1. 调用 `google_sign_in.authenticate()`
2. 获取 `idToken` 和 `accessToken`
3. 调用 Supabase: `signInWithIdToken(provider: 'google', idToken, accessToken)`

---

### 账号绑定

**`NativeAuthService.linkWithApple()`**
```dart
/// 绑定Apple账号到现有用户
Future<UserIdentity> linkWithApple()

// 使用示例
try {
  final identity = await NativeAuthService().linkWithApple();
  print('绑定成功: ${identity.identityId}');
} catch (e) {
  if (e is AuthException && e.statusCode == 'identity_already_exists') {
    print('该Apple账号已被其他用户绑定');
  }
}
```

**可能的错误**:
- `identity_already_exists` - 账号已绑定其他用户
- `user_cancelled` - 用户取消绑定

---

## API错误处理

### 通用错误格式

**Supabase错误**:
```dart
try {
  await _supabase.from('table').select();
} on PostgrestException catch (e) {
  print('数据库错误: ${e.message}, Code: ${e.code}');
}
```

**Auth错误**:
```dart
try {
  await _supabase.auth.signInWithPassword(...);
} on AuthException catch (e) {
  if (e.statusCode == 'invalid_credentials') {
    // 用户名或密码错误
  }
}
```

**RevenueCat错误**:
```dart
try {
  await Purchases.purchasePackage(package);
} on PlatformException catch (e) {
  switch (e.code) {
    case 'purchaseCancelledError':
      // 用户取消
      break;
    case 'networkError':
      // 网络错误
      break;
  }
}
```

---

## API速率限制

| 服务 | 限制 | 说明 |
|------|------|------|
| Supabase Database | 无硬限制 | 受Postgres连接数限制 |
| Supabase Edge Functions | 60次/分钟 | 超出返回429 |
| Supabase Storage | 100MB/文件 | 总容量1GB (免费版) |
| RevenueCat | 无限制 | 建议缓存CustomerInfo |
| 火山引擎 TTS | 1000次/天 | 免费额度 |

---

## API调试工具

### Supabase Studio
- **URL**: https://supabase.com/dashboard
- **功能**: 数据表查看、SQL查询、日志监控

### RevenueCat Dashboard
- **URL**: https://app.revenuecat.com
- **功能**: 订阅事件、Webhook日志、测试购买

### 日志过滤
```dart
// 仅在Debug模式打印
if (kDebugMode) {
  debugPrint('API响应: $data');
}
```

---

## 附录: 环境变量配置

**.env 文件示例**:
```env
SUPABASE_URL=https://kixonwnuivnjqlraydmz.supabase.co
SUPABASE_ANON_KEY=your_anon_key
REVENUECAT_API_KEY_IOS=appl_PfoovuEVLvjtBrZlHZMBaHdnpqW
REVENUECAT_API_KEY_ANDROID=your_android_key
VOLC_TTS_APP_ID=your_app_id
VOLC_TTS_ACCESS_TOKEN=your_token
GOOGLE_CLIENT_ID_IOS=your_ios_client_id
GOOGLE_CLIENT_ID_ANDROID=your_android_client_id
```

**加载方式**:
```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

await dotenv.load();
final apiKey = dotenv.env['SUPABASE_ANON_KEY'];
```

---

**📌 相关文档**:
- [PROJECT_OVERVIEW.md](./PROJECT_OVERVIEW.md) - 项目架构
- [DATA_MODELS.md](./DATA_MODELS.md) - 数据模型
- [THIRD_PARTY_AUTH.md](./THIRD_PARTY_AUTH.md) - 第三方登录详解
