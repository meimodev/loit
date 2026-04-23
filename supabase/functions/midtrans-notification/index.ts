// supabase/functions/midtrans-notification/index.ts
//
// Midtrans posts payment status changes to this endpoint. We verify the
// SHA-512 signature, look up the matching row in `midtrans_orders`, and
// apply the side effect (tier upgrade / top-up credit / storage extension).
//
// Required Supabase secrets:
//   MIDTRANS_SERVER_KEY  — used as the signing salt
//
// Configure the webhook URL in Midtrans Dashboard → Settings → Configuration
// → Payment Notification URL:
//   https://<project-ref>.supabase.co/functions/v1/midtrans-notification
//
// Midtrans retries on non-2xx for up to 24 hours, so always return 200 for
// inputs we've successfully processed (even no-op duplicates) and only 4xx/5xx
// for signatures we couldn't verify or transient DB failures.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

// ================================================================
// Signature verification: SHA-512 of order_id + status_code + gross_amount + server_key.
// Midtrans docs: https://docs.midtrans.com/docs/https-notification-webhooks
// ================================================================
async function verifySignature(payload: {
  order_id: string;
  status_code: string;
  gross_amount: string;
  signature_key: string;
}): Promise<boolean> {
  const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY');
  if (!serverKey) throw new Error('MIDTRANS_SERVER_KEY is not set');

  const raw = `${payload.order_id}${payload.status_code}${payload.gross_amount}${serverKey}`;
  const hashBuf = await crypto.subtle.digest(
    'SHA-512',
    new TextEncoder().encode(raw),
  );
  const expected = Array.from(new Uint8Array(hashBuf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return expected === payload.signature_key;
}

// ================================================================
// Map Midtrans transaction_status + fraud_status to our internal
// order status. See:
//   https://docs.midtrans.com/docs/status-definition
// ================================================================
function resolveFinalStatus(
  transactionStatus: string,
  fraudStatus: string | undefined,
): 'succeeded' | 'pending' | 'failed' | 'cancelled' | 'expired' {
  switch (transactionStatus) {
    case 'capture':
      // Credit-card specific. Only treat as succeeded when fraud check passed.
      return fraudStatus === 'accept' ? 'succeeded' : 'pending';
    case 'settlement':
      return 'succeeded';
    case 'pending':
      return 'pending';
    case 'deny':
    case 'failure':
      return 'failed';
    case 'cancel':
      return 'cancelled';
    case 'expire':
      return 'expired';
    default:
      return 'pending';
  }
}

// ================================================================
// Side-effect handlers. Each is idempotent — we call them at most once
// per order thanks to the `status != 'succeeded'` guard below, but a
// duplicate call must still be safe.
// ================================================================
async function applySuccess(order: {
  user_id: string;
  product_key: string;
}): Promise<void> {
  switch (order.product_key) {
    case 'loit_pro_monthly':
    case 'loit_pro_yearly':
      await supabase.from('users').update({ tier: 'pro' }).eq('id', order.user_id);
      return;
    case 'loit_team_monthly':
    case 'loit_team_yearly':
      await supabase.from('users').update({ tier: 'team' }).eq('id', order.user_id);
      return;
    case 'loit_scan_topup':
      await supabase.rpc('add_scan_topup', { p_user_id: order.user_id, p_amount: 10 });
      return;
    case 'loit_storage_ext':
      await supabase.rpc('extend_receipt_expiry', { p_user_id: order.user_id });
      return;
    default:
      console.warn('Unknown product_key in succeeded order:', order.product_key);
  }
}

// ================================================================
// Request handler.
// ================================================================
serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  let payload: Record<string, unknown>;
  try {
    payload = await req.json() as Record<string, unknown>;
  } catch {
    return new Response('Invalid JSON', { status: 400 });
  }

  const orderId      = payload.order_id       as string | undefined;
  const statusCode   = payload.status_code    as string | undefined;
  const grossAmount  = payload.gross_amount   as string | undefined;
  const signatureKey = payload.signature_key  as string | undefined;
  const transactionStatus = payload.transaction_status as string | undefined;
  const fraudStatus       = payload.fraud_status       as string | undefined;

  if (!orderId || !statusCode || !grossAmount || !signatureKey || !transactionStatus) {
    return new Response('Missing required fields', { status: 400 });
  }

  // 1. Verify the SHA-512 signature before trusting anything else.
  const ok = await verifySignature({
    order_id:      orderId,
    status_code:   statusCode,
    gross_amount:  grossAmount,
    signature_key: signatureKey,
  });
  if (!ok) {
    console.warn('Signature verification failed for order', orderId);
    return new Response('Invalid signature', { status: 401 });
  }

  // 2. Look up the order.
  const { data: order, error: orderErr } = await supabase
    .from('midtrans_orders')
    .select('order_id, user_id, product_key, amount_idr, status')
    .eq('order_id', orderId)
    .maybeSingle();
  if (orderErr) {
    console.error('DB error looking up order:', orderErr);
    return new Response('DB error', { status: 500 });
  }
  if (!order) {
    // Unknown order — reply 200 so Midtrans stops retrying. A warning log
    // is enough; legitimate orders always have a row.
    console.warn('Notification for unknown order:', orderId);
    return new Response('OK', { status: 200 });
  }

  // 3. Compute final status and short-circuit if we've already applied it.
  const finalStatus = resolveFinalStatus(transactionStatus, fraudStatus);
  if (order.status === 'succeeded' && finalStatus === 'succeeded') {
    return new Response('OK (duplicate)', { status: 200 });
  }

  // 4. Update the order row first, so a mid-flight crash in `applySuccess`
  //    still leaves us with a durable status. Idempotent on retry.
  await supabase.from('midtrans_orders').update({
    status:                   finalStatus,
    midtrans_transaction_status: transactionStatus,
    midtrans_fraud_status:       fraudStatus ?? null,
    paid_at:                     finalStatus === 'succeeded' ? new Date().toISOString() : null,
  }).eq('order_id', orderId);

  // 5. Apply the side effect — only on the first transition to succeeded.
  if (finalStatus === 'succeeded' && order.status !== 'succeeded') {
    await applySuccess({ user_id: order.user_id, product_key: order.product_key });
  }

  return new Response('OK', { status: 200 });
});
