// Deno runtime. Supabase Edge Functions run on Deno 1.45+.
// Pin dependency versions — `npm:` specifiers without a version pick
// whatever is cached, which breaks reproducibility across deployments.
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import Anthropic from 'npm:@anthropic-ai/sdk@0.32.1';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const anthropic = new Anthropic({ apiKey: Deno.env.get('ANTHROPIC_API_KEY')! });

// Service-role client — bypasses RLS. Only used for quota increment
// and the demo-scan flag update. All user-scoped reads validate JWT first.
const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

// CORS — the Edge Function is called directly from the Flutter app via HTTPS,
// and during dev from the Supabase Studio function tester (browser origin).
// Without these headers the browser-based tester fails with CORS errors.
const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const SCANNER_PROMPT = `You are a receipt parsing assistant. Analyze the receipt image and return ONLY valid JSON.
Do not include any explanation, preamble, or markdown formatting.

{
  "merchant": "",
  "address": "",
  "date": "YYYY-MM-DD",
  "time": "HH:MM",
  "currency": "ISO 4217 code",
  "items": [
    { "name": "", "qty": 1, "unit_price": 0.00, "total_price": 0.00 }
  ],
  "subtotal": 0.00,
  "tax": 0.00,
  "tip": 0.00,
  "total": 0.00,
  "payment_method": "",
  "category": "dining|groceries|transport|shopping|entertainment|utilities|health|travel|other"
}

If any field cannot be determined, use null. Never guess — use null if unsure.`;

/**
 * Extract partial fields from malformed AI response using targeted regex patterns.
 * This runs server-side so the client receives a clean structured object,
 * not raw unparseable text that would require unsafe client-side parsing.
 */
function extractPartialFields(rawText: string): Record<string, unknown> {
  const partial: Record<string, unknown> = {};

  const patterns: [string, RegExp][] = [
    ['merchant',       /"merchant"\s*:\s*"([^"]+)"/],
    ['date',           /"date"\s*:\s*"(\d{4}-\d{2}-\d{2})"/],
    ['total',          /"total"\s*:\s*([\d.]+)/],
    ['currency',       /"currency"\s*:\s*"([A-Z]{3})"/],
    ['category',       /"category"\s*:\s*"([^"]+)"/],
    ['tax',            /"tax"\s*:\s*([\d.]+)/],
    ['subtotal',       /"subtotal"\s*:\s*([\d.]+)/],
    ['payment_method', /"payment_method"\s*:\s*"([^"]+)"/],
  ];

  for (const [key, regex] of patterns) {
    const match = rawText.match(regex);
    if (match) partial[key] = match[1];
  }

  // Attempt to salvage the items array even if the outer JSON is broken
  const itemsMatch = rawText.match(/"items"\s*:\s*(\[[\s\S]*?\])/);
  if (itemsMatch) {
    try {
      partial['items'] = JSON.parse(itemsMatch[1]);
    } catch {
      // Items array is also malformed — skip, don't include
    }
  }

  return partial;
}

async function getUserFromJWT(
  req: Request,
): Promise<{ id: string; tier: string; has_used_demo_scan: boolean } | null> {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return null;

  const token = authHeader.replace('Bearer ', '');
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) return null;

  const { data: profile } = await supabase
    .from('users')
    .select('tier, has_used_demo_scan')
    .eq('id', user.id)
    .single();

  return {
    id: user.id,
    tier: profile?.tier ?? 'free',
    has_used_demo_scan: profile?.has_used_demo_scan ?? false,
  };
}

async function incrementQuotaIfAllowed(userId: string, tier: string): Promise<boolean> {
  const limits: Record<string, number> = { free: 8, pro: 50, team: 999999 };
  const limit = limits[tier] ?? 8;

  await supabase.rpc('reset_scan_quota_if_new_month', { p_user_id: userId });

  const { data, error } = await supabase.rpc('increment_scan_quota', {
    p_user_id: userId,
    p_limit: limit,
  });

  return !!data && !error;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  });
}

serve(async (req) => {
  // CORS preflight (fires automatically from browser-based tools)
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: CORS_HEADERS });
  }
  if (req.method !== 'POST') {
    return new Response('Method Not Allowed', { status: 405, headers: CORS_HEADERS });
  }

  const user = await getUserFromJWT(req);
  if (!user) return jsonResponse({ error: 'Unauthorized' }, 401);

  let body: { image?: string; is_demo?: boolean };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: 'Invalid JSON body' }, 400);
  }
  const { image, is_demo } = body;
  if (!image) return jsonResponse({ error: 'Missing image' }, 400);

  // Defensive cap: refuse payloads > ~8 MB base64 (≈6 MB decoded).
  // Flutter compresses to <500 KB, so anything larger is a bug or abuse.
  if (image.length > 8 * 1024 * 1024) {
    return jsonResponse({ error: 'Image too large' }, 413);
  }

  // Demo scan: free for the very first attempt only, even on free tier.
  const isDemoScan = is_demo === true && !user.has_used_demo_scan;

  if (!isDemoScan) {
    const allowed = await incrementQuotaIfAllowed(user.id, user.tier);
    if (!allowed) return jsonResponse({ error: 'Quota exceeded' }, 402);
  } else {
    await supabase
      .from('users')
      .update({ has_used_demo_scan: true })
      .eq('id', user.id);
  }

  try {
    const result = await anthropic.messages.create({
      // Claude Sonnet 4.6 — current latest as of April 2026.
      // See https://platform.claude.com/docs/en/about-claude/models/overview
      // If upgrading, prefer dated IDs like `claude-sonnet-4-6-20260318` for
      // deterministic builds.
      // model: 'claude-sonnet-4-6',
      model: 'claude-haiku-4-5-20251001',
      max_tokens: 1024,
      messages: [{
        role: 'user',
        content: [
          { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: image } },
          { type: 'text', text: SCANNER_PROMPT },
        ],
      }],
    });

    const text = result.content[0]?.type === 'text' ? result.content[0].text : '';

    try {
      const parsed = JSON.parse(text);
      return jsonResponse(parsed, 200);
    } catch {
      // AI returned unparseable JSON — extract partial fields server-side
      // so the Flutter client receives a safe structured object, not raw text.
      const partialFields = extractPartialFields(text);
      return jsonResponse({ ai_failure: true, partial_fields: partialFields }, 422);
    }
  } catch (err) {
    console.error('Claude API error:', err);
    // 500 = upstream/connection error → client shows retry screen (NOT manual entry form).
    return jsonResponse({ error: 'Scan service unavailable' }, 500);
  }
});
