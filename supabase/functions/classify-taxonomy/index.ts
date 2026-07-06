import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.46.1";
import { chatComplete } from "../_shared/openrouter.ts";
import { gatedCapture } from "../_shared/gated_capture.ts";

// Generic AI classifier: maps each supplied item to exactly one code from a
// caller-provided taxonomy, or UNCLASSIFIED. Denomination-agnostic (ADR-0026) —
// the ~300-code GMIM chart lives in the Dart client and rides in the request,
// so a different chart reuses this function with no redeploy. Metered as one
// AI Capture (ADR-0017) via the shared `gatedCapture` tail: reserve 1 credit,
// charge by completion tokens, refund on failure. The caller (the treasurer
// generating Laporan Realisasi Mata Anggaran) pays from their own credits.

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// ponytail: one call classifies the whole period. Output is ~one short line per
// item (~15 tokens), so max_tokens 8192 covers ~500 items; a bigger period would
// truncate — chunk by item count if that ceiling is ever hit.
const MAX_TOKENS = 8192;

interface Item { id: string; text: string; kind: "income" | "expense" }
interface Code { kode: string; name: string }
interface Taxonomy { income: Code[]; expense: Code[] }

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

async function authUser(req: Request): Promise<string | null> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return null;
  const token = authHeader.replace("Bearer ", "");
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) return null;
  return user.id;
}

function codeList(codes: Code[]): string {
  return codes.map((c) => `${c.kode}\t${c.name}`).join("\n");
}

function buildSystem(tax: Taxonomy): string {
  return [
    "You assign each financial transaction to exactly one budget-line code",
    "(Mata Anggaran) from the lists below. Rules:",
    "- Match the transaction's `kind`: an income item may ONLY use an INCOME",
    "  code; an expense item may ONLY use an EXPENSE code.",
    "- Return the MOST SPECIFIC code the text justifies. If the text does not",
    "  distinguish a leaf (e.g. it says 'persembahan minggu' but not which",
    "  service), return the parent group code instead of guessing a leaf.",
    "- If nothing fits, return \"UNCLASSIFIED\". Never invent a code.",
    "- Output ONLY a JSON array, no prose: [{\"id\":\"<id>\",\"kode\":\"<code>\"}].",
    "",
    "INCOME codes (kode <tab> name):",
    codeList(tax.income),
    "",
    "EXPENSE codes (kode <tab> name):",
    codeList(tax.expense),
  ].join("\n");
}

// Pull the first JSON array out of the model text (tolerates code fences / prose).
function extractArray(text: string): Array<{ id: string; kode: string }> {
  const start = text.indexOf("[");
  const end = text.lastIndexOf("]");
  if (start === -1 || end === -1 || end < start) {
    throw new Error("no JSON array in response");
  }
  const arr = JSON.parse(text.slice(start, end + 1));
  if (!Array.isArray(arr)) throw new Error("not an array");
  return arr;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", {
      status: 405,
      headers: CORS_HEADERS,
    });
  }

  const userId = await authUser(req);
  if (!userId) return jsonResponse({ error: "Unauthorized" }, 401);

  let body: { items?: Item[]; taxonomy?: Taxonomy };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }
  const items = body.items ?? [];
  const taxonomy = body.taxonomy;
  if (!taxonomy?.income || !taxonomy?.expense) {
    return jsonResponse({ error: "Missing taxonomy" }, 400);
  }
  // No items → nothing to classify, no AI call, no charge.
  if (items.length === 0) {
    return jsonResponse({ mapping: {}, credits_charged: 0, credits_remaining: null });
  }

  const { data: profile } = await supabase
    .from("users")
    .select("tier")
    .eq("id", userId)
    .maybeSingle();
  const tier = (profile?.tier as string | undefined) ?? "free";

  const validIncome = new Set(taxonomy.income.map((c) => c.kode));
  const validExpense = new Set(taxonomy.expense.map((c) => c.kode));
  const kindOf = new Map(items.map((i) => [i.id, i.kind] as const));
  const system = buildSystem(taxonomy);
  const userContent = JSON.stringify(
    items.map((i) => ({ id: i.id, kind: i.kind, text: i.text })),
  );

  try {
    const res = await gatedCapture<
      { mapping: Record<string, string>; completionTokens: number }
    >({
      userId,
      tier,
      parse: async () => {
        const runOnce = async () => {
          const out = await chatComplete({
            system,
            userContent,
            maxTokens: MAX_TOKENS,
          });
          return { arr: extractArray(out.text), tokens: out.completionTokens };
        };
        let got: { arr: Array<{ id: string; kode: string }>; tokens: number };
        try {
          got = await runOnce();
        } catch {
          // One retry — completion tokens already burned, squeeze a usable
          // parse before failing. Still one logical capture, one charge.
          got = await runOnce();
        }
        const mapping: Record<string, string> = {};
        for (const row of got.arr) {
          const id = row?.id;
          const kode = row?.kode;
          if (typeof id !== "string" || typeof kode !== "string") continue;
          const kind = kindOf.get(id);
          if (!kind) continue; // hallucinated id
          const valid = kind === "income" ? validIncome : validExpense;
          // Anything not in the matching-kind list collapses to UNCLASSIFIED.
          mapping[id] = valid.has(kode) ? kode : "UNCLASSIFIED";
        }
        return { mapping, completionTokens: got.tokens };
      },
      // A parsed mapping is always usable work, even when every item is
      // UNCLASSIFIED — the AI did classify. Only a thrown parse refunds.
      classify: (r) => ({ usable: true, completionTokens: r.completionTokens }),
    });

    if ("kind" in res && res.kind === "quota_reached") {
      return jsonResponse({ error: "AI credit quota reached" }, 402);
    }
    return jsonResponse({
      mapping: res.mapping,
      credits_charged: res.creditsCharged,
      credits_remaining: res.creditsRemaining,
    });
  } catch (err) {
    console.error("classify-taxonomy error:", err);
    return jsonResponse({ error: "Classification service unavailable" }, 500);
  }
});
