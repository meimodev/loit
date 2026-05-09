// 3-hour cron — refreshes USD-base FX rates for all supported currencies.
//
// One OXR call returns all 63 rates in a single request (base=USD, free plan).
// Cross-rates are derived client-side from cached rate_per_usd values.
//
// Schedule via Supabase dashboard:
//   Edge Functions → fx-rate-refresh → Schedule → cron `5 */3 * * *`
//   (00:05, 03:05, 06:05, 09:05, 12:05, 15:05, 18:05, 21:05 UTC)
//   8 fires/day × 30 days = 240 calls/mo = 24% of OXR free 1000/mo quota.
//
// Idempotent: upsert by primary key (currency).

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const OXR_APP_ID = Deno.env.get('OXR_APP_ID');

async function fetchOxrUsdBase(symbols: string[]): Promise<Record<string, number>> {
  if (!OXR_APP_ID) throw new Error('OXR_APP_ID missing');
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 15000);
  try {
    const url = `https://openexchangerates.org/api/latest.json?app_id=${OXR_APP_ID}&symbols=${symbols.join(',')}`;
    const res = await fetch(url, { signal: ctrl.signal });
    if (!res.ok) throw new Error(`OXR ${res.status}: ${await res.text()}`);
    const data = await res.json();
    const rates = data?.rates;
    if (!rates || typeof rates !== 'object') {
      throw new Error('OXR: missing rates field');
    }
    return rates as Record<string, number>;
  } finally {
    clearTimeout(timer);
  }
}

serve(async () => {
  const { data: supported, error: listErr } = await supabase
    .from('supported_currencies')
    .select('code');
  if (listErr || !supported) {
    console.error('supported_currencies query failed:', listErr);
    return new Response(JSON.stringify({ error: listErr?.message ?? 'no currencies' }), { status: 500 });
  }

  const symbols = supported.map((r) => r.code as string).filter((c) => c !== 'USD');

  let rates: Record<string, number>;
  try {
    rates = await fetchOxrUsdBase(symbols);
  } catch (e) {
    console.error('OXR fetch failed:', e);
    return new Response(JSON.stringify({ error: (e as Error).message }), { status: 502 });
  }

  const fetchedAt = new Date().toISOString();
  const rows = [
    { currency: 'USD', rate_per_usd: 1, fetched_at: fetchedAt },
    ...symbols.map((c) => ({
      currency: c,
      rate_per_usd: rates[c],
      fetched_at: fetchedAt,
    })).filter((r) => typeof r.rate_per_usd === 'number' && r.rate_per_usd > 0),
  ];

  const missing = symbols.filter((c) => !(typeof rates[c] === 'number' && rates[c] > 0));
  if (missing.length > 0) {
    console.warn('OXR missing rates for:', missing);
  }

  const { error: upsertErr } = await supabase
    .from('fx_rates')
    .upsert(rows, { onConflict: 'currency' });
  if (upsertErr) {
    console.error('fx_rates upsert failed:', upsertErr);
    return new Response(JSON.stringify({ error: upsertErr.message }), { status: 500 });
  }

  console.log(`fx-rate-refresh: ${rows.length} rates upserted at ${fetchedAt}`);
  return new Response(JSON.stringify({
    ok: true,
    refreshedAt: fetchedAt,
    count: rows.length,
    missing,
  }));
});
