import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.46.1";
import {
  parseReceiptImage,
  type AccountRef,
  type Category,
} from "../_shared/receipt_parser.ts";

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

async function authUser(req: Request): Promise<string | null> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return null;
  const token = authHeader.replace("Bearer ", "");
  const { data: { user }, error } = await supabase.auth.getUser(token);
  if (error || !user) return null;
  return user.id;
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", ...CORS_HEADERS },
  });
}

serve(async (req) => {
  if (req.method === "OPTIONS")
    return new Response("ok", { headers: CORS_HEADERS });
  if (req.method !== "POST") {
    return new Response("Method Not Allowed", {
      status: 405,
      headers: CORS_HEADERS,
    });
  }

  const userId = await authUser(req);
  if (!userId) return jsonResponse({ error: "Unauthorized" }, 401);

  let body: {
    image?: string;
    categories?: Category[];
    accounts?: AccountRef[];
    strict_retry?: boolean;
  };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const { image, categories, accounts, strict_retry } = body;
  if (!image) return jsonResponse({ error: "Missing image" }, 400);
  if (image.length > 8 * 1024 * 1024) {
    return jsonResponse({ error: "Image too large" }, 413);
  }

  try {
    const res = await parseReceiptImage({
      imageBase64: image,
      categories,
      accounts,
      strictRetry: strict_retry,
    });
    switch (res.kind) {
      case "ok":
        return jsonResponse(res.parsed, 200);
      case "not_a_transaction":
        return jsonResponse(
          {
            not_a_transaction: true,
            transaction_kind: res.transactionKind,
            reason: res.reason,
          },
          422,
        );
      case "partial":
        return jsonResponse(res.partial, 200);
      case "ai_failure":
        return jsonResponse(
          { ai_failure: true, partial_fields: res.partial },
          422,
        );
    }
  } catch (err) {
    console.error("Claude API error:", err);
    return jsonResponse({ error: "Scan service unavailable" }, 500);
  }
});
