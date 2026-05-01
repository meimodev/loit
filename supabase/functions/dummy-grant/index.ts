// Stub entitlement grant for the `DummyPaymentService` Flutter client.
//
// PURPOSE: keep building the app (paywall, gating, analytics, dashboards,
// recurring bills, exports) before RevenueCat / Play Console developer
// API access is unlocked. Mirrors the side effects of `revenuecat-webhook`
// so the database state after a dummy purchase is identical to a real
// RevenueCat-driven purchase.
//
// SECURITY: this function MUST be removed (or behind a `STUB_MODE=true`
// guard) before launch. There is **no payment validation** — any
// authenticated user can call it and grant themselves Pro / Team. Rejects
// itself when `STUB_MODE` is not `true` so a misconfigured prod deploy
// does not silently expose the endpoint.
//
// Replacement plan: when RevenueCat is live, switch the Flutter
// `paymentServiceProvider` from `DummyPaymentService` to
// `RevenueCatPaymentService` and remove this function with
// `supabase functions delete dummy-grant`.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const STUB_MODE = (Deno.env.get('STUB_MODE') ?? 'false').toLowerCase() === 'true';

const SUBSCRIPTION_SKUS: Record<string, { tier: 'pro' | 'team'; days: number }> = {
  loit_pro_monthly_1: { tier: 'pro', days: 30 },
  loit_pro_annual_1: { tier: 'pro', days: 365 },
  loit_team_monthly_1: { tier: 'team', days: 30 },
  loit_team_annual_1: { tier: 'team', days: 365 },
};
const ONE_TIME_SKUS = new Set([
  'loit_scan_topup_10',
  'loit_storage_ext_6mo',
]);

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  });
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }
  if (!STUB_MODE) {
    return jsonResponse({ error: 'STUB_MODE not enabled' }, 403);
  }
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405, headers: CORS_HEADERS });
  }

  const auth = req.headers.get('Authorization');
  if (!auth) return jsonResponse({ error: 'Unauthorized' }, 401);
  const { data: userData, error: userErr } = await supabase.auth.getUser(
    auth.replace('Bearer ', ''),
  );
  if (userErr || !userData.user) {
    return jsonResponse({ error: 'Unauthorized' }, 401);
  }

  let body: { productId?: string; userId?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }
  const { productId, userId } = body;
  if (!productId || !userId) {
    return jsonResponse({ error: 'productId and userId required' }, 400);
  }
  if (userData.user.id !== userId) {
    return jsonResponse({ error: 'User mismatch' }, 403);
  }

  const stubToken = `stub-${productId}-${userId}-${Date.now()}`;

  try {
    if (productId in SUBSCRIPTION_SKUS) {
      const cfg = SUBSCRIPTION_SKUS[productId];
      const expiry = new Date(Date.now() + cfg.days * 24 * 60 * 60 * 1000);
      await supabase
        .from('users')
        .update({
          tier: cfg.tier,
          tier_expires_at: expiry.toISOString(),
        })
        .eq('id', userId);
      await supabase.from('payment_receipts').insert({
        user_id: userId,
        product_id: productId,
        purchase_token: stubToken,
        raw: { stub: true, productId, expiry: expiry.toISOString() },
      });
      await supabase.from('notifications').insert({
        user_id: userId,
        kind: 'subscription',
        title: 'LOIT Pro active (stub)',
        body: 'Stub purchase granted. Real purchases will use RevenueCat.',
        deep_link: '/billing',
        metadata: { sku: productId, stub: true },
      });
      return jsonResponse({ success: true, tier: cfg.tier });
    }

    if (ONE_TIME_SKUS.has(productId)) {
      if (productId === 'loit_scan_topup_10') {
        await supabase.rpc('add_scan_topup', {
          p_user_id: userId,
          p_amount: 10,
        });
      } else if (productId === 'loit_storage_ext_6mo') {
        await supabase.rpc('extend_receipt_expiry', { p_user_id: userId });
      }
      await supabase.from('payment_receipts').insert({
        user_id: userId,
        product_id: productId,
        purchase_token: stubToken,
        raw: { stub: true, productId },
      });
      await supabase.from('notifications').insert({
        user_id: userId,
        kind: 'subscription',
        title: 'Top-up applied (stub)',
        body: `${productId} stub purchase granted.`,
        deep_link: '/billing',
        metadata: { sku: productId, stub: true },
      });
      const { data: profile } = await supabase
        .from('users')
        .select('tier')
        .eq('id', userId)
        .single();
      return jsonResponse({ success: true, tier: profile?.tier ?? 'free' });
    }

    return jsonResponse({ error: `Unknown productId: ${productId}` }, 400);
  } catch (err) {
    console.error('dummy-grant error:', err);
    return jsonResponse({ error: 'Stub grant failed' }, 500);
  }
});
