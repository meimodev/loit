// RevenueCat → Supabase webhook.
//
// Single source of truth for entitlement state. RevenueCat validates every
// purchase against Google Play (and Apple, later) on its side and posts a
// signed event to this endpoint on every state change (purchase, renewal,
// cancellation, refund, billing issue, etc.). We trust this event — and
// only this event — to flip `users.tier`, grant scan top-ups, or extend
// receipt storage.
//
// Auth model:
//   RevenueCat does not sign webhook bodies. The recommended pattern is a
//   shared bearer token configured in the RC dashboard ("Authorization
//   header value"). We mirror that secret as `REVENUECAT_WEBHOOK_AUTH`
//   and reject any request that doesn't match. Treat this like a webhook
//   signing secret — rotate via the RC dashboard.
//
// Idempotency:
//   `payment_receipts(purchase_token)` is unique. RC events carry both
//   `event.id` (RC-side event UUID) and `event.transaction_id` (Play
//   purchase token). We key on `transaction_id` so resends never
//   double-grant credits.
//
// Required Edge Function secrets:
//   REVENUECAT_WEBHOOK_AUTH               — shared bearer token (matches RC config)
//   SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY — provided by Supabase runtime

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const SHARED_AUTH = Deno.env.get('REVENUECAT_WEBHOOK_AUTH')!;

const SUBSCRIPTION_SKUS = new Set([
  'loit_pro_monthly_1',
  'loit_pro_annual_1',
  'loit_team_monthly_1',
  'loit_team_annual_1',
]);
const ONE_TIME_SKUS = new Set([
  'loit_scan_topup_10',
  'loit_storage_ext_6mo',
]);

const SKU_TO_TIER: Record<string, 'pro' | 'team'> = {
  loit_pro_monthly_1: 'pro',
  loit_pro_annual_1: 'pro',
  loit_team_monthly_1: 'team',
  loit_team_annual_1: 'team',
};

// Event types we act on. Anything else (TRANSFER, SUBSCRIBER_ALIAS, TEST,
// INVOICE_ISSUANCE, etc.) is acknowledged but not processed.
const GRANT_EVENTS = new Set([
  'INITIAL_PURCHASE',
  'RENEWAL',
  'PRODUCT_CHANGE',
  'NON_RENEWING_PURCHASE',
  'UNCANCELLATION',
]);
const REVOKE_EVENTS = new Set([
  'CANCELLATION', // honors expiry — only revoke if expiration_at_ms in past
  'EXPIRATION',
  'BILLING_ISSUE',
  'SUBSCRIPTION_PAUSED',
  'REFUND',
]);

interface RcEvent {
  id: string;
  type: string;
  app_user_id: string;
  original_app_user_id?: string;
  product_id: string;
  transaction_id?: string;
  original_transaction_id?: string;
  expiration_at_ms?: number;
  purchased_at_ms?: number;
  store?: string;
  environment?: 'SANDBOX' | 'PRODUCTION';
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

async function alreadyProcessed(eventId: string): Promise<boolean> {
  const { data } = await supabase
    .from('payment_receipts')
    .select('purchase_token')
    .eq('purchase_token', eventId)
    .maybeSingle();
  return !!data;
}

async function recordReceipt(
  userId: string,
  sku: string,
  eventId: string,
  payload: unknown,
) {
  await supabase.from('payment_receipts').insert({
    user_id: userId,
    product_id: sku,
    purchase_token: eventId,
    raw: payload,
  });
}

async function grantSubscription(userId: string, sku: string, expiryMs?: number) {
  const tier = SKU_TO_TIER[sku];
  await supabase
    .from('users')
    .update({
      tier,
      tier_expires_at: expiryMs ? new Date(expiryMs).toISOString() : null,
    })
    .eq('id', userId);
  return tier;
}

async function revokeSubscription(userId: string) {
  await supabase
    .from('users')
    .update({ tier: 'free', tier_expires_at: null })
    .eq('id', userId);
}

async function grantScanTopUp(userId: string) {
  await supabase.rpc('add_scan_topup', { p_user_id: userId, p_amount: 10 });
}

async function grantStorageExtension(userId: string) {
  await supabase.rpc('extend_receipt_expiry', { p_user_id: userId });
}

serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405 });
  }

  // Shared-secret auth. Configured in RC dashboard → Integrations → Webhooks
  // → "Authorization header value".
  const auth = req.headers.get('Authorization') ?? '';
  if (auth !== SHARED_AUTH) {
    return jsonResponse({ error: 'Unauthorized' }, 401);
  }

  let body: { event?: RcEvent };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }

  const ev = body.event;
  if (!ev?.type || !ev.app_user_id || !ev.product_id) {
    return jsonResponse({ error: 'Malformed event' }, 400);
  }

  // RC sends sandbox events too — let them through but never write in
  // production. Comment the next line out during sandbox QA.
  if (ev.environment === 'SANDBOX' && Deno.env.get('REJECT_SANDBOX') === 'true') {
    return jsonResponse({ ok: true, ignored: 'sandbox' });
  }

  // Idempotency: `id` is RC's per-event UUID. Resends carry the same id.
  if (await alreadyProcessed(ev.id)) {
    return jsonResponse({ ok: true, idempotent: true });
  }

  // `app_user_id` is the Supabase user UUID we set via Purchases.configure.
  // Validate it actually exists before writing entitlements.
  const userId = ev.app_user_id;
  const { data: existing, error: userErr } = await supabase
    .from('users')
    .select('id')
    .eq('id', userId)
    .maybeSingle();
  if (userErr || !existing) {
    return jsonResponse({ error: `Unknown app_user_id: ${userId}` }, 404);
  }

  try {
    if (GRANT_EVENTS.has(ev.type)) {
      if (SUBSCRIPTION_SKUS.has(ev.product_id)) {
        await grantSubscription(userId, ev.product_id, ev.expiration_at_ms);
      } else if (ONE_TIME_SKUS.has(ev.product_id)) {
        if (ev.product_id === 'loit_scan_topup_10') {
          await grantScanTopUp(userId);
        } else if (ev.product_id === 'loit_storage_ext_6mo') {
          await grantStorageExtension(userId);
        }
      }
      await recordReceipt(userId, ev.product_id, ev.id, body);
      return jsonResponse({ ok: true, granted: true });
    }

    if (REVOKE_EVENTS.has(ev.type)) {
      // Subscriptions: only revoke once we're past expiry. RC sends
      // CANCELLATION the moment the user cancels, but they keep access
      // until `expiration_at_ms`.
      const inGrace =
        ev.expiration_at_ms && ev.expiration_at_ms > Date.now();
      if (SUBSCRIPTION_SKUS.has(ev.product_id) && !inGrace) {
        await revokeSubscription(userId);
      }
      await recordReceipt(userId, ev.product_id, ev.id, body);
      return jsonResponse({ ok: true, revoked: !inGrace });
    }

    // Acknowledge unknown / informational events (TRANSFER, TEST, etc.)
    // without touching state — RC retries on non-2xx so we must 200.
    return jsonResponse({ ok: true, ignored: ev.type });
  } catch (err) {
    console.error('revenuecat-webhook error:', err);
    return jsonResponse({ error: 'Webhook processing failed' }, 500);
  }
});
