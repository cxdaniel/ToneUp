# Revenue Cat Webhook - 订阅事件处理接口

## 功能说明

接收来自 RevenueCat 的订阅事件 webhook，自动同步订阅状态到 Supabase 数据库。

**支持的事件类型**：
- `INITIAL_PURCHASE` - 首次购买
- `RENEWAL` - 订阅续费
- `NON_RENEWING_PURCHASE` - 非续订购买（一次性购买）
- `CANCELLATION` - 订阅取消
- `EXPIRATION` - 订阅过期
- `BILLING_ISSUE` - 账单问题

## 接口信息

**端点**: `POST /revenue-cat-webhook`

**请求体**（由 RevenueCat 自动发送）:
```json
{
  "type": "INITIAL_PURCHASE",
  "app_user_id": "user_123",
  "product_id": "toneup_monthly_sub",
  "period_type": "normal",
  "store": "app_store",
  "expiration_at_ms": 1738022400000,
  "purchased_at_ms": 1735430400000
}
```

## 事件处理

### INITIAL_PURCHASE（首次购买）
```typescript
await handlePurchase(supabase, event, userId);
```

**操作**：
- 插入或更新 `subscriptions` 表
- 设置状态为 `trial`（试用期）或 `active`（正式订阅）
- 记录订阅开始和结束时间
- 保存产品ID和平台信息

**数据库更新**：
```sql
INSERT INTO subscriptions (
  user_id,
  revenue_cat_customer_id,
  revenue_cat_entitlement_id,
  status,
  tier,
  subscription_start_at,
  subscription_end_at,
  platform,
  product_id,
  updated_at
) VALUES (...)
ON CONFLICT (user_id) 
DO UPDATE SET ...
```

### RENEWAL（订阅续费）
```typescript
await handlePurchase(supabase, event, userId);
```

**操作**：
- 更新订阅状态为 `active`
- 延长 `subscription_end_at`
- 记录续费时间

### NON_RENEWING_PURCHASE（一次性购买）
```typescript
await handlePurchase(supabase, event, userId);
```

**操作**：
- 购买终身会员或一次性内购
- 设置状态为 `active`
- `subscription_end_at` 为 null（永久有效）

### CANCELLATION（订阅取消）
```typescript
await handleCancellation(supabase, event, userId);
```

**操作**：
- 更新订阅状态为 `cancelled`
- 记录取消时间 `cancelled_at`
- **注意**：订阅在当前周期结束前仍然有效

**数据库更新**：
```sql
UPDATE subscriptions
SET 
  status = 'cancelled',
  cancelled_at = NOW(),
  updated_at = NOW()
WHERE user_id = '...';
```

### EXPIRATION（订阅过期）
```typescript
await handleExpiration(supabase, event, userId);
```

**操作**：
- 更新订阅状态为 `expired`
- 用户失去 Pro 功能访问权限

**数据库更新**：
```sql
UPDATE subscriptions
SET 
  status = 'expired',
  updated_at = NOW()
WHERE user_id = '...';
```

### BILLING_ISSUE（账单问题）
```typescript
await handleBillingIssue(supabase, event, userId);
```

**操作**：
- 记录日志（目前仅记录，不修改数据库）
- 可扩展：发送通知提醒用户更新支付方式

## 响应格式

### 成功响应
```json
{
  "received": true
}
```

### 错误响应
```json
{
  "error": "Database update failed"
}
```

## 订阅状态流转

```
        INITIAL_PURCHASE
              ↓
          [trial/active]
              ↓
    ┌─────────┴─────────┐
    ↓                   ↓
 RENEWAL           CANCELLATION
    ↓                   ↓
 [active]          [cancelled]
    ↓                   ↓
    └────→ EXPIRATION ←─┘
              ↓
          [expired]
```

## 订阅数据模型

### subscriptions 表结构
```sql
CREATE TABLE subscriptions (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID UNIQUE NOT NULL REFERENCES auth.users(id),
  revenue_cat_customer_id TEXT,
  revenue_cat_entitlement_id TEXT,
  status TEXT NOT NULL,  -- trial/active/cancelled/expired
  tier TEXT,             -- monthly/yearly/lifetime
  subscription_start_at TIMESTAMPTZ,
  subscription_end_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  platform TEXT,         -- app_store/play_store
  product_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 状态说明
| 状态 | 说明 | Pro权限 |
|-----|------|---------|
| trial | 试用期 | ✅ 有 |
| active | 正常订阅 | ✅ 有 |
| cancelled | 已取消（周期内仍有效） | ✅ 有（直到过期） |
| expired | 已过期 | ❌ 无 |

## Tier（订阅层级）识别

```typescript
function getTierFromProduct(productId: string): string | null {
  if (productId.includes('monthly')) return 'monthly';
  if (productId.includes('yearly') || productId.includes('annual')) 
    return 'yearly';
  if (productId.includes('lifetime')) return 'lifetime';
  return null;
}
```

**产品ID示例**：
- `toneup_monthly_sub` → `monthly`
- `toneup_annually_sub` → `yearly`
- `toneup_lifetime_purchase` → `lifetime`

## RevenueCat 配置

### 1. Webhook URL 设置
在 RevenueCat Dashboard 中配置：
```
https://kixonwnuivnjqlraydmz.supabase.co/functions/v1/revenue-cat-webhook
```

### 2. 事件订阅
启用以下事件：
- ✅ Initial Purchase
- ✅ Renewal
- ✅ Non Renewing Purchase
- ✅ Cancellation
- ✅ Expiration
- ✅ Billing Issue

### 3. Authorization（可选）
可在 RevenueCat 中设置 Authorization Header：
```
Authorization: Bearer YOUR_SECRET_KEY
```

然后在 Edge Function 中验证：
```typescript
const authHeader = req.headers.get('authorization');
if (authHeader !== `Bearer ${EXPECTED_SECRET}`) {
  return new Response('Unauthorized', { status: 401 });
}
```

## 客户端订阅流程

### 1. 用户发起购买（移动端）
```dart
// iOS/Android使用RevenueCat SDK
final offerings = await Purchases.getOfferings();
final package = offerings.current?.monthly;

final purchaserInfo = await Purchases.purchasePackage(package);
```

### 2. RevenueCat 处理购买
- RevenueCat SDK 与 App Store/Play Store 通信
- 验证购买凭证
- 记录交易信息

### 3. RevenueCat 发送 Webhook
- 自动触发 `INITIAL_PURCHASE` 事件
- 调用本 Edge Function

### 4. Edge Function 更新数据库
- 插入/更新 `subscriptions` 表
- 用户获得 Pro 权限

### 5. 客户端同步状态
```dart
// SubscriptionProvider 轮询检查
await subscriptionProvider.checkSubscriptionStatus();

// 或监听 Supabase 实时更新
supabase
  .from('subscriptions')
  .stream(primaryKey: ['user_id'])
  .eq('user_id', userId)
  .listen((data) {
    updateLocalStatus(data);
  });
```

## Web 平台处理

**注意**：Web 平台不支持 RevenueCat SDK
- ❌ Web 端无购买功能
- ✅ Web 端仅显示订阅状态（从 Supabase 读取）
- ✅ Web 端显示"下载移动应用"提示

```dart
if (PlatformUtils.isWeb) {
  // 显示订阅状态 + 下载链接
  return SubscriptionStatusDisplay();
} else {
  // 显示购买选项
  return PaywallPage();
}
```

## 调试与测试

### 测试 Webhook（本地）
```bash
curl -X POST \
  'http://localhost:54321/functions/v1/revenue-cat-webhook' \
  -H 'Content-Type: application/json' \
  -d '{
    "type": "INITIAL_PURCHASE",
    "app_user_id": "test_user",
    "product_id": "toneup_monthly_sub",
    "period_type": "trial",
    "store": "app_store",
    "expiration_at_ms": 1738022400000
  }'
```

### 查看日志
```bash
# 查看 Edge Function 日志
supabase functions logs revenue-cat-webhook --tail

# 或在 Supabase Dashboard 中查看
```

### 验证数据库
```sql
SELECT * FROM subscriptions WHERE user_id = 'test_user';
```

## 错误处理

### 数据库写入失败
- 日志记录错误
- 返回 400 错误
- **RevenueCat 会重试 webhook**（建议做幂等性处理）

### 用户不存在
```typescript
if (!userId) {
  console.error('Missing app_user_id');
  return new Response(
    JSON.stringify({ error: 'Invalid user' }),
    { status: 400 }
  );
}
```

## 安全考虑

### 1. 验证来源
建议添加 RevenueCat Webhook 签名验证：
```typescript
const signature = req.headers.get('X-RevenueCat-Signature');
const isValid = verifyWebhookSignature(body, signature);
if (!isValid) {
  return new Response('Invalid signature', { status: 401 });
}
```

### 2. 幂等性处理
```typescript
// 使用 ON CONFLICT ... DO UPDATE 确保重复事件不会破坏数据
await supabase
  .from('subscriptions')
  .upsert(data, { onConflict: 'user_id' });
```

### 3. 日志记录
所有事件都记录到控制台，便于审计和调试：
```typescript
console.log('收到 RevenueCat webhook:', event.type);
console.log('用户ID:', userId, '产品ID:', productId);
```

## 性能指标

| 操作 | 耗时 |
|-----|------|
| 解析事件 | ~0.01s |
| 数据库更新 | ~0.1-0.2s |
| **总耗时** | **~0.2s** |

## 环境变量

```bash
SUPABASE_URL=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx
# 可选：RevenueCat Webhook 密钥（用于验证签名）
REVENUECAT_WEBHOOK_SECRET=xxx
```

## 相关文档

- [RevenueCat Webhook文档](https://docs.revenuecat.com/docs/webhooks)
- [ToneUp订阅系统架构](../../docs/PROJECT_OVERVIEW.md#订阅系统)
- [SubscriptionProvider实现](../../lib/providers/subscription_provider.dart)

## 版本历史

- **v1.0** (2026-01-27): 初始版本，支持所有主要订阅事件
