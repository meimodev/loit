// User-invocable fallback refresh. Called by client only when
// `max(fx_rates.fetched_at) > 4h` — i.e. the 3h cron missed.
// Same OXR fetch as fx-rate-refresh; reused so a single failure mode covers both.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const OXR_APP_ID = Deno.env.get('OXR_APP_ID');

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  });
}

async function requireAuth(req: Request): Promise<boolean> {
  const auth = req.headers.get('Authorization');
  if (!auth) return false;
  const token = auth.replace('Bearer ', '');
  const { data: { user }, error } = await supabase.auth.getUser(token);
  return !error && !!user;
}

async function fetchOxrUsdBase(symbols: string[]): Promise<Record<string, number>> {
  if (!OXR_APP_ID) throw new Error('OXR_APP_ID missing');
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 15000);
  try {
    const url = `https://openexchangerates.org/api/latest.json?app_id=${OXR_APP_ID}&symbols=${symbols.join(',')}`;
    const res = await fetch(url, { signal: ctrl.signal });
    if (!res.ok) throw new Error(`OXR ${res.status}`);
    const data = await res.json();
    const rates = data?.rates;
    if (!rates || typeof rates !== 'object') {
      throw new Error('OXR: missing rates');
    }
    return rates as Record<string, number>;
  } finally {
    clearTimeout(timer);
  }
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS_HEADERS });
  if (req.method !== 'POST') return jsonResponse({ error: 'Method Not Allowed' }, 405);

  if (!(await requireAuth(req))) return jsonResponse({ error: 'Unauthorized' }, 401);

  const { data: supported } = await supabase
    .from('supported_currencies')
    .select('code');
  if (!supported) return jsonResponse({ error: 'no currencies' }, 500);

  const symbols = supported.map((r) => r.code as string).filter((c) => c !== 'USD');

  let rates: Record<string, number>;
  try {
    rates = await fetchOxrUsdBase(symbols);
  } catch (e) {
    return jsonResponse({ error: `FX fetch failed: ${(e as Error).message}` }, 502);
  }

  const fetchedAt = new Date().toISOString();
  const rows = [
    { currency: 'USD', rate_per_usd: 1, fetched_at: fetchedAt },
    ...symbols.map((c) => ({ currency: c, rate_per_usd: rates[c], fetched_at: fetchedAt }))
      .filter((r) => typeof r.rate_per_usd === 'number' && r.rate_per_usd > 0),
  ];

  const { error: upsertErr } = await supabase
    .from('fx_rates')
    .upsert(rows, { onConflict: 'currency' });
  if (upsertErr) return jsonResponse({ error: upsertErr.message }, 500);

  return jsonResponse({ refreshedAt: fetchedAt, count: rows.length });
});
