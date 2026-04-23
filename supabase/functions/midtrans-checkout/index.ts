// supabase/functions/midtrans-checkout/index.ts
//
// Creates a Midtrans Snap transaction and returns the Snap `token` to the
// client, along with our own `order_id`. The client then hands the token
// to `MidtransSDK.startPaymentUiFlow(token: ...)`.
//
// Required Supabase secrets:
//   MIDTRANS_SERVER_KEY        — `SB-Mid-server-...` (sandbox) or `Mid-server-...`
//   MIDTRANS_IS_PRODUCTION     — "true" to hit production Snap API, any other value = sandbox
//
// Authentication: the caller must send a valid Supabase user JWT in the
// Authorization header. We use that to identify the buyer and stamp
// `metadata.user_id` on the Snap transaction — the notification webhook
// uses this to credit the right user.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

// ================================================================
// Product catalog. Keep in sync with LOIT_Build_Guide.md §3.1.
// Prices are in IDR (Midtrans only supports IDR for most payment
// channels). Adjust if you add USD-equivalent variants later.
// ================================================================
type ProductKey =
  | 'loit_pro_monthly'
  | 'loit_pro_yearly'
  | 'loit_team_monthly'
  | 'loit_team_yearly'
  | 'loit_scan_topup'
  | 'loit_storage_ext';

interface ProductDef {
  name: string;
  priceIdr: number;
  kind: 'subscription' | 'one_time';
  tier?: 'pro' | 'team';
}

const PRODUCTS: Record<ProductKey, ProductDef> = {
  loit_pro_monthly:  { name: 'LOIT Pro Monthly',  priceIdr: 85_529,    kind: 'subscription', tier: 'pro'  },
  loit_pro_yearly:   { name: 'LOIT Pro Yearly',   priceIdr: 856_680,   kind: 'subscription', tier: 'pro'  },
  loit_team_monthly: { name: 'LOIT Team Monthly', priceIdr: 171_169,   kind: 'subscription', tier: 'team' },
  loit_team_yearly:  { name: 'LOIT Team Yearly',  priceIdr: 1_713_360, kind: 'subscription', tier: 'team' },
  loit_scan_topup:   { name: 'Scan Top-Up (10)',  priceIdr: 16_969,    kind: 'one_time'              },
  loit_storage_ext:  { name: 'Receipt Storage +6mo', priceIdr: 16_969, kind: 'one_time'              },
};

// ================================================================
// Midtrans Snap endpoints.
// ================================================================
const SNAP_SANDBOX = 'https://app.sandbox.midtrans.com/snap/v1/transactions';
const SNAP_PRODUCTION = 'https://app.midtrans.com/snap/v1/transactions';

function snapEndpoint(): string {
  return Deno.env.get('MIDTRANS_IS_PRODUCTION')?.toLowerCase() === 'true'
    ? SNAP_PRODUCTION
    : SNAP_SANDBOX;
}

// Midtrans server key is sent as HTTP Basic auth: `base64(server_key:)`.
function midtransAuthHeader(): string {
  const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY');
  if (!serverKey) throw new Error('MIDTRANS_SERVER_KEY is not set');
  return 'Basic ' + btoa(serverKey + ':');
}

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

// ================================================================
// Request handler.
// ================================================================
serve(async (req) => {
  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  // 1. Authenticate the caller.
  const auth = req.headers.get('Authorization');
  if (!auth) return new Response('Unauthorized', { status: 401 });
  const { data: { user } } = await supabase.auth.getUser(auth.replace('Bearer ', ''));
  if (!user) return new Response('Unauthorized', { status: 401 });

  // 2. Validate request body.
  let body: { product_key?: string };
  try {
    body = await req.json();
  } catch {
    return new Response('Invalid JSON', { status: 400 });
  }
  const productKey = body.product_key as ProductKey | undefined;
  if (!productKey || !PRODUCTS[productKey]) {
    return new Response(`Unknown product_key: ${productKey}`, { status: 400 });
  }
  const product = PRODUCTS[productKey];

  // 3. Mint a unique order_id. Prefix with the user id so the webhook can
  //    cheaply verify the order belongs to the authenticated user even
  //    before hitting the database.
  const orderId = `${user.id.slice(0, 8)}-${productKey}-${Date.now()}`;

  // 4. Persist a pending row so the notification webhook has something to
  //    reconcile against. This is also what the paywall UI polls while the
  //    user waits for the webhook to fire.
  await supabase.from('midtrans_orders').insert({
    order_id:    orderId,
    user_id:     user.id,
    product_key: productKey,
    amount_idr:  product.priceIdr,
    status:      'pending',
  });

  // 5. Ask Midtrans for a Snap token.
  const snapRes = await fetch(snapEndpoint(), {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
      Authorization: midtransAuthHeader(),
    },
    body: JSON.stringify({
      transaction_details: {
        order_id:     orderId,
        gross_amount: product.priceIdr,
      },
      item_details: [{
        id:       productKey,
        name:     product.name,
        price:    product.priceIdr,
        quantity: 1,
      }],
      customer_details: {
        email:      user.email ?? `user-${user.id}@loit.app`,
        first_name: (user.user_metadata?.full_name as string | undefined) ?? 'LOIT User',
      },
      // `custom_field1` is echoed back in the notification payload and is
      // our safety net in case `order_id` parsing fails.
      custom_field1: user.id,
      custom_field2: productKey,
      credit_card:   { secure: true },
    }),
  });

  if (!snapRes.ok) {
    const errText = await snapRes.text();
    console.error('Midtrans Snap create failed:', snapRes.status, errText);
    await supabase.from('midtrans_orders')
      .update({ status: 'init_failed', failure_reason: errText })
      .eq('order_id', orderId);
    return new Response(`Snap create failed: ${errText}`, { status: 502 });
  }

  const snapJson = await snapRes.json() as { token: string; redirect_url: string };

  return new Response(JSON.stringify({
    order_id:     orderId,
    snap_token:   snapJson.token,
    redirect_url: snapJson.redirect_url,
  }), {
    status: 200,
    headers: { 'Content-Type': 'application/json' },
  });
});
