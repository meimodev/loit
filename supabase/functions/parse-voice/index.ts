import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "npm:@supabase/supabase-js@2.46.1";
import { gatedCapture } from "../_shared/scan_gate.ts";
import {
  extractIntendedRoomName,
  findRoomByName,
  parseTransactionText,
} from "../_shared/text_parser.ts";
import type {
  TextParseResult,
  TextParseSuccess,
} from "../_shared/text_parser.ts";
import { transcribeAudio } from "../_shared/openrouter.ts";
import {
  categoriesForScope,
  findCategoryInScope,
  loadUserContext,
  remapCategoryAcrossScopes,
} from "../_shared/user_context.ts";
import type { UserContext } from "../_shared/user_context.ts";

// In-app voice Capture (ADR-0022). Transcribes (Whisper) then parses (Haiku)
// through the SAME pipeline + SAME full context the Telegram bot uses
// (`loadUserContext`), so voice parses exactly what typed text does — the
// narrow client-sent context that caused voice to reject Telegram-parseable
// notes is gone (ADR-0022 amendment). Audio is transcribed and discarded.
// Destination is resolved server-side: a room named in speech wins; otherwise
// the screen the user tapped from (`roomId`) is the default. Same JSON contract
// as scan-receipt, plus `destination_room_id` / `routed_by_speech`.

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

// Pick a guaranteed-present catch-all for the destination scope when the parsed
// category can't be matched/remapped. Room catch-alls (`other` /
// `income_other`, namespaced) are seeded at room creation (ADR-0009); personal
// has the same plain keys. Falls back to the first in-scope category of the
// right kind so a transaction never lands category-less.
function catchAllCategory(
  ctx: UserContext,
  roomId: string | null,
  kind: "expense" | "income",
): string | null {
  const scope = categoriesForScope(ctx, roomId).filter((c) => c.kind === kind);
  if (scope.length === 0) return null;
  const wantSuffix = kind === "income" ? "income_other" : "other";
  const hit = scope.find((c) => c.key === wantSuffix || c.key.endsWith(`:${wantSuffix}`)) ??
    scope.find((c) => c.key.toLowerCase().includes("other"));
  return (hit ?? scope[0]).key;
}

// Resolve the final destination + a scope-valid category. Speech wins: a room
// named in the transcript (and matched to a member room) overrides the screen
// `roomId`; absent that, the screen room is the default. The parser ran against
// the full context, so its category may belong to the wrong scope — remap it by
// name into the resolved scope, else fall back to that scope's catch-all.
function resolveDestination(
  parsed: TextParseSuccess,
  ctx: UserContext,
  screenRoomId: string | null,
): { roomId: string | null; roomName: string | null; routedBySpeech: boolean; category: string } {
  const spoken = findRoomByName(ctx, parsed.destination_room);
  const roomId = spoken?.id ?? screenRoomId ?? null;
  const routedBySpeech = !!spoken && spoken.id !== screenRoomId;
  let category = parsed.category;
  if (!findCategoryInScope(ctx, category, parsed.type, roomId)) {
    category =
      remapCategoryAcrossScopes(ctx, category, parsed.type, roomId) ??
        catchAllCategory(ctx, roomId, parsed.type) ??
        category;
  }
  const roomName = roomId
    ? ctx.rooms.find((r) => r.id === roomId)?.name ?? null
    : null;
  return { roomId, roomName, routedBySpeech, category };
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
    audio?: string;
    mimeType?: string;
    roomId?: string;
  };
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const { audio, roomId: screenRoomId } = body;
  const mimeType = body.mimeType ?? "audio/m4a";
  if (!audio) return jsonResponse({ error: "Missing audio" }, 400);
  // Base64 of a 60s m4a is well under this; mirrors scan-receipt's cap.
  if (audio.length > 8 * 1024 * 1024) {
    return jsonResponse({ error: "Audio too large" }, 413);
  }

  // Full server-authoritative context — the same one the Telegram bot parses
  // with. Client-sent categories/accounts are no longer trusted (ADR-0022
  // amendment): a cold client provider could ship an empty list and force a
  // reject. `roomId` from the body is only the default destination.
  const ctx = await loadUserContext(userId);
  if (!ctx) return jsonResponse({ error: "User not found" }, 404);

  try {
    // Transcribe + parse in one gated step, keeping the transcript so we can
    // store the FULL spoken note (the parser's `notes` is deliberately a short
    // phrasing, and the audio is discarded — the transcript is the only
    // verbatim record).
    let transcript = "";
    const res = await gatedCapture<TextParseResult>({
      userId,
      tier: ctx.tier,
      parse: async () => {
        try {
          transcript = (await transcribeAudio(audio, mimeType)) ?? "";
        } catch {
          return { kind: "ai_failure" };
        }
        if (transcript.trim().length < 2) return { kind: "ai_failure" };
        return parseTransactionText(transcript, ctx);
      },
      classify: (r) => ({
        usable: r.kind === "ok",
        completionTokens: r.kind === "ok" ? r.completionTokens : 0,
      }),
    });

    if (res.kind === "quota_reached") {
      // Client maps 402 → ScanResult.quotaExceeded and shows the top-up sheet.
      return jsonResponse({ error: "Credit cap reached" }, 402);
    }
    if (res.kind === "ok") {
      const heardOk = transcript.trim();
      const dest = resolveDestination(
        res.parsed,
        ctx,
        screenRoomId ?? null,
      );
      return jsonResponse(
        {
          ...res.parsed,
          category: dest.category,
          // `notes` is the parser's remark (Catatan, ADR-0024) — it rides the
          // canonical notes text client-side. The verbatim transcript travels
          // separately so nothing heard is lost to the UI.
          transcript: heardOk,
          destination_room: dest.roomName,
          destination_room_id: dest.roomId,
          routed_by_speech: dest.routedBySpeech,
          credits_charged: res.creditsCharged,
          credits_remaining: res.creditsRemaining,
        },
        200,
      );
    }
    const heard = transcript.trim();
    if (res.kind === "rejected") {
      // Room-not-found parity with the bot: the user clearly addressed a room
      // they are not a member of. Surface that specifically (still refunded).
      const intended = extractIntendedRoomName(heard);
      if (intended && !findRoomByName(ctx, intended)) {
        return jsonResponse(
          { room_not_found: true, room: intended, transcript: heard },
          422,
        );
      }
      // Surface what was heard so the user can see the misparse and retry.
      return jsonResponse(
        { not_a_transaction: true, reason: res.reason, transcript: heard },
        422,
      );
    }
    // ai_failure — transcription or parse produced nothing usable. Seed the
    // transcript into notes so the manual-fallback form shows what was heard.
    return jsonResponse(
      {
        ai_failure: true,
        partial_fields: heard.length > 0 ? { notes: heard } : {},
        transcript: heard,
      },
      422,
    );
  } catch (err) {
    console.error("Voice parse error:", err);
    return jsonResponse({ error: "Voice service unavailable" }, 500);
  }
});
