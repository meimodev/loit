import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.46.1";

// Service-role client — bypasses RLS for tier lookup and fx_rates upsert.
const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const OXR_APP_ID = Deno.env.get("OXR_APP_ID");

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const STALENESS_MS: Record<string, number> = {
  free: 25 * 60 * 60 * 1000,
  pro: 35 * 60 * 1000,
  team: 35 * 60 * 1000,
};

const ISO_4217 = /^[A-Z]{3}$/;

type Tier = "free" | "pro" | "team";

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

async function getUserTier(req: Request): Promise<Tier | null> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return null;

  const token = authHeader.replace("Bearer ", "");
  const {
    data: { user },
    error,
  } = await supabase.auth.getUser(token);
  if (error || !user) return null;

  const { data: profile } = await supabase
    .from("users")
    .select("tier")
    .eq("id", user.id)
    .single();

  const tier = (profile?.tier ?? "free") as string;
  return tier === "pro" || tier === "team" ? (tier as Tier) : "free";
}

async function readCache(
  from: string,
  to: string,
): Promise<{ rate: number; fetchedAt: Date } | null> {
  const { data } = await supabase
    .from("fx_rates")
    .select("rate, fetched_at")
    .eq("base_currency", from)
    .eq("target_currency", to)
    .maybeSingle();
  if (!data) return null;
  return {
    rate: Number(data.rate),
    fetchedAt: new Date(data.fetched_at as string),
  };
}

async function writeCache(from: string, to: string, rate: number) {
  await supabase.from("fx_rates").upsert({
    base_currency: from,
    target_currency: to,
    rate,
    fetched_at: new Date().toISOString(),
  });
}

async function fetchFrankfurter(from: string, to: string): Promise<number> {
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 10000);
  try {
    const res = await fetch(
      `https://api.frankfurter.app/latest?from=${from}&to=${to}`,
      { signal: ctrl.signal },
    );
    if (!res.ok) throw new Error(`Frankfurter ${res.status}`);
    const data = await res.json();
    const rate = data?.rates?.[to];
    if (typeof rate !== "number") throw new Error("Frankfurter: no rate");
    return rate;
  } finally {
    clearTimeout(timer);
  }
}

async function fetchOxr(from: string, to: string): Promise<number> {
  if (!OXR_APP_ID) throw new Error("OXR_APP_ID missing");
  const ctrl = new AbortController();
  const timer = setTimeout(() => ctrl.abort(), 10000);
  try {
    // OXR free plan only allows base=USD. Fetch USD-base rates for both
    // currencies and derive the cross-rate: from→to = (USD→to) / (USD→from).
    const symbols = from === "USD" || to === "USD"
      ? (from === "USD" ? to : from)
      : `${from},${to}`;
    const res = await fetch(
      `https://openexchangerates.org/api/latest.json?app_id=${OXR_APP_ID}&symbols=${symbols}`,
      { signal: ctrl.signal },
    );
    if (!res.ok) throw new Error(`OXR ${res.status}`);
    const data = await res.json();
    const rates = data?.rates ?? {};
    const usdToFrom = from === "USD" ? 1 : rates[from];
    const usdToTo = to === "USD" ? 1 : rates[to];
    if (typeof usdToFrom !== "number" || typeof usdToTo !== "number") {
      throw new Error("OXR: no rate");
    }
    return usdToTo / usdToFrom;
  } finally {
    clearTimeout(timer);
  }
}

serve(async (req) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: CORS_HEADERS });
  if (req.method !== "POST")
    return jsonResponse({ error: "Method Not Allowed" }, 405);

  const tier = await getUserTier(req);
  if (!tier) return jsonResponse({ error: "Unauthorized" }, 401);

  let body: { from?: string; to?: string };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const from = body.from?.toUpperCase();
  const to = body.to?.toUpperCase();
  if (!from || !to || !ISO_4217.test(from) || !ISO_4217.test(to)) {
    return jsonResponse({ error: "Invalid currency code" }, 400);
  }

  if (from === to) {
    return jsonResponse({ rate: 1, isStale: false, source: "identity" });
  }

  const cached = await readCache(from, to);
  const threshold = STALENESS_MS[tier];
  const ageMs = cached
    ? Date.now() - cached.fetchedAt.getTime()
    : Number.POSITIVE_INFINITY;

  if (cached && ageMs < threshold) {
    return jsonResponse({
      rate: cached.rate,
      isStale: false,
      source: "cache",
    });
  }

  try {
    let rate: number;
    if (tier === "free") {
      rate = await fetchFrankfurter(from, to);
    } else {
      try {
        rate = await fetchOxr(from, to);
      } catch (oxrErr) {
        console.warn(`OXR failed, falling back to Frankfurter: ${(oxrErr as Error).message}`);
        rate = await fetchFrankfurter(from, to);
      }
    }
    await writeCache(from, to, rate);
    return jsonResponse({ rate, isStale: false, source: "live" });
  } catch (e) {
    if (cached) {
      return jsonResponse({
        rate: cached.rate,
        isStale: true,
        source: "stale",
      });
    }
    return jsonResponse(
      { error: `FX fetch failed: ${(e as Error).message}` },
      502,
    );
  }
});
