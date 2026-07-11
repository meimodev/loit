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
  'loit_lite_monthly',
  'loit_lite_annual',
  'loit_pro_monthly_1',
  'loit_pro_annual_1',
]);
// v2 scan top-up: loit_scan_topup_15 (Rp 9,000 / 15 scans). The legacy
// loit_scan_topup_10 SKU is kept here so historical receipts (already-purchased
// 10-scan packs) can still be honored when RC re-sends. New paywall flows
// must only surface the _15 SKU.
const ONE_TIME_SKUS = new Set([
  'loit_scan_topup_15',
  'loit_scan_topup_10',
  'loit_storage_ext_6mo',
  'loit_room_slot', // +1 permanent room slot, Pro only (ADR-0020)
]);

const SKU_TO_TIER: Record<string, 'pro' | 'lite'> = {
  loit_lite_monthly: 'lite',
  loit_lite_annual: 'lite',
  loit_pro_monthly_1: 'pro',
  loit_pro_annual_1: 'pro',
};

const TOPUP_AMOUNT: Record<string, number> = {
  loit_scan_topup_15: 15,
  loit_scan_topup_10: 10,
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

// supabase-js never throws — it returns { error }. Swallowing it would ack
// the event to RC as granted while the DB write silently failed, so surface
// it and let the top-level catch return 500 (RC retries on non-2xx).
function orThrow<T extends { error: { message: string } | null }>(res: T): T {
  if (res.error) throw new Error(res.error.message);
  return res;
}

async function recordReceipt(
  userId: string,
  sku: string,
  eventId: string,
  payload: unknown,
) {
  orThrow(await supabase.from('payment_receipts').insert({
    user_id: userId,
    product_id: sku,
    purchase_token: eventId,
    raw: payload,
  }));
}

async function grantSubscription(userId: string, sku: string, expiryMs?: number) {
  const tier = SKU_TO_TIER[sku];
  orThrow(await supabase
    .from('users')
    .update({
      tier,
      tier_expires_at: expiryMs ? new Date(expiryMs).toISOString() : null,
    })
    .eq('id', userId));
  return tier;
}

async function revokeSubscription(userId: string) {
  orThrow(await supabase
    .from('users')
    .update({ tier: 'free', tier_expires_at: null })
    .eq('id', userId));
}

async function grantScanTopUp(userId: string, sku: string) {
  const amount = TOPUP_AMOUNT[sku] ?? 15;
  orThrow(
    await supabase.rpc('add_scan_topup', { p_user_id: userId, p_amount: amount }),
  );
}

async function grantStorageExtension(userId: string) {
  orThrow(await supabase.rpc('extend_receipt_expiry', { p_user_id: userId }));
}

async function grantRoomSlot(userId: string) {
  orThrow(await supabase.rpc('add_room_slot', { p_user_id: userId, p_amount: 1 }));
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
    console.log('rc-webhook malformed', JSON.stringify(body));
    return jsonResponse({ error: 'Malformed event' }, 400);
  }

  console.log(
    `rc-webhook event type=${ev.type} sku=${ev.product_id} ` +
    `user=${ev.app_user_id} env=${ev.environment} exp=${ev.expiration_at_ms}`,
  );

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

  // Google Play sends product_id in `subscriptionId:basePlanId` form
  // (e.g. `loit_pro_annual_1:loit-pro-annual-2`). RC forwards it verbatim.
  // Strip the base-plan suffix so SKU set lookups match our bare ids.
  const sku = ev.product_id.split(':')[0];

  try {
    if (GRANT_EVENTS.has(ev.type)) {
      let granted = false;
      if (SUBSCRIPTION_SKUS.has(sku)) {
        await grantSubscription(userId, sku, ev.expiration_at_ms);
        granted = true;
      } else if (ONE_TIME_SKUS.has(sku)) {
        if (sku === 'loit_scan_topup_15' || sku === 'loit_scan_topup_10') {
          await grantScanTopUp(userId, sku);
          granted = true;
        } else if (sku === 'loit_storage_ext_6mo') {
          await grantStorageExtension(userId);
          granted = true;
        } else if (sku === 'loit_room_slot') {
          await grantRoomSlot(userId);
          granted = true;
        }
      }
      await recordReceipt(userId, sku, ev.id, body);
      if (granted) {
        await supabase.from('notifications').insert({
          user_id: userId,
          kind: 'subscription',
          title: SUBSCRIPTION_SKUS.has(sku)
            ? 'LOIT Pro active'
            : 'Purchase complete',
          body: SUBSCRIPTION_SKUS.has(sku)
            ? 'Your subscription is active. Welcome aboard.'
            : `Top-up applied (${sku}).`,
          deep_link: '/billing',
          metadata: { sku, event_type: ev.type, event_id: ev.id },
        });
      }
      return jsonResponse({ ok: true, granted, sku });
    }

    if (REVOKE_EVENTS.has(ev.type)) {
      // REFUND with "remove entitlement" on Play Console = immediate revoke,
      // grace period does not apply. CANCELLATION/EXPIRATION/BILLING_ISSUE/
      // SUBSCRIPTION_PAUSED honor `expiration_at_ms` so the user keeps access
      // through the paid-up period they already paid for.
      const isHardRevoke = ev.type === 'REFUND' || ev.type === 'EXPIRATION';
      const inGrace = !isHardRevoke &&
        ev.expiration_at_ms !== undefined &&
        ev.expiration_at_ms > Date.now();
      const shouldRevoke = SUBSCRIPTION_SKUS.has(sku) && !inGrace;
      if (shouldRevoke) {
        await revokeSubscription(userId);
      }
      await recordReceipt(userId, sku, ev.id, body);
      const notifTitle = ev.type === 'BILLING_ISSUE'
        ? 'Billing issue with your subscription'
        : ev.type === 'REFUND'
        ? 'Refund processed'
        : shouldRevoke
        ? 'Subscription ended'
        : 'Subscription set to expire';
      const notifBody = ev.type === 'BILLING_ISSUE'
        ? 'Update your payment method in Google Play to keep Pro features.'
        : ev.type === 'REFUND'
        ? 'Your purchase has been refunded.'
        : shouldRevoke
        ? "You're back on the free tier."
        : 'Access continues until the end of the paid period.';
      await supabase.from('notifications').insert({
        user_id: userId,
        kind: 'subscription',
        title: notifTitle,
        body: notifBody,
        deep_link: '/billing',
        metadata: { sku, event_type: ev.type, event_id: ev.id },
      });
      return jsonResponse({ ok: true, revoked: shouldRevoke, type: ev.type });
    }

    // Acknowledge unknown / informational events (TRANSFER, TEST, etc.)
    // without touching state — RC retries on non-2xx so we must 200.
    return jsonResponse({ ok: true, ignored: ev.type });
  } catch (err) {
    console.error('revenuecat-webhook error:', err);
    return jsonResponse({ error: 'Webhook processing failed' }, 500);
  }
});
