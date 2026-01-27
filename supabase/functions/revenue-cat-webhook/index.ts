// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
console.info('server started');
const supabase = createClient(Deno.env.get("SUPABASE_URL"), Deno.env.get("SUPABASE_SERVICE_ROLE_KEY"));
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////
/// 部署服务
Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type"
      }
    });
  }
  const event = await req.json();
  // 1. 解析并验证输入参数
  if (event) {
    throw new Error("缺少参数: event");
  }
  try {
    const event = await req.json();
    console.log('收到 RevenueCat webhook:', event.type);
    const userId = event.app_user_id;

    // 根据事件类型处理
    switch (event.type) {
      case 'INITIAL_PURCHASE':
      case 'RENEWAL':
      case 'NON_RENEWING_PURCHASE':
        await handlePurchase(supabase, event, userId)
        break

      case 'CANCELLATION':
        await handleCancellation(supabase, event, userId)
        break

      case 'EXPIRATION':
        await handleExpiration(supabase, event, userId)
        break

      case 'BILLING_ISSUE':
        await handleBillingIssue(supabase, event, userId)
        break
    }

    return new Response(JSON.stringify({ received: true }), {
      headers: {
        'Content-Type': 'application/json',
        "Access-Control-Allow-Origin": "*"
      },
      status: 200
    });
  } catch (error) {
    console.error('Webhook 处理失败:', error)
    return new Response(
      JSON.stringify({
        error: error.message
      }), {
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*"
      },
      status: 400
    });
  }
});
async function handlePurchase(supabase, event, userId) {
  const entitlement = event.product_id
  const expiresAt = event.expiration_at_ms
    ? new Date(event.expiration_at_ms).toISOString()
    : null

  await supabase
    .from('subscriptions')
    .upsert({
      user_id: userId,
      revenue_cat_customer_id: event.app_user_id,
      revenue_cat_entitlement_id: 'pro_features',
      status: event.period_type === 'trial' ? 'trial' : 'active',
      tier: getTierFromProduct(event.product_id),
      subscription_start_at: new Date().toISOString(),
      subscription_end_at: expiresAt,
      platform: event.store,
      product_id: event.product_id,
      updated_at: new Date().toISOString(),
    }, {
      onConflict: 'user_id'
    })
}

async function handleCancellation(supabase, event, userId) {
  await supabase
    .from('subscriptions')
    .update({
      status: 'cancelled',
      cancelled_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    })
    .eq('user_id', userId)
}

async function handleExpiration(supabase, event, userId) {
  await supabase
    .from('subscriptions')
    .update({
      status: 'expired',
      updated_at: new Date().toISOString(),
    })
    .eq('user_id', userId)
}

async function handleBillingIssue(supabase, event, userId) {
  // 可以发送通知或标记账户
  console.log('账单问题:', userId)
}

function getTierFromProduct(productId: string): string | null {
  if (productId.includes('monthly')) return 'monthly'
  if (productId.includes('yearly') || productId.includes('annual')) return 'yearly'
  if (productId.includes('lifetime')) return 'lifetime'
  return null
}