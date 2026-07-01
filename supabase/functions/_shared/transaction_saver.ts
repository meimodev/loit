import { serviceClient } from "./supabase.ts";
import { findCategoryInScope, type UserContext } from "./user_context.ts";
import { looksLikeCanonicalBreakdown } from "./notes_breakdown.ts";

export type TransactionSource = "manual" | "scanned" | "bot_image" | "bot_chat";

export interface SaveTransactionInput {
  userId: string;
  type: "expense" | "income";
  totalPositive: number; // always positive; sign is set from `type`
  currency: string;
  category: string;
  accountName: string;
  merchant?: string | null;
  notes?: string | null;
  roomId?: string | null;
  aiParsed?: boolean;
  // Canonical origin (matches `transactions.source`). Defaults to `bot_chat`
  // for caller convenience since this saver is used exclusively by the
  // Telegram pipeline today.
  source?: TransactionSource;
}

export interface SaveTransactionResult {
  ok: true;
  transactionId: string;
  signedAmount: number;
  roomId: string | null;
  accountId: string;
}

export interface SaveTransactionError {
  ok: false;
  reason:
    | "account_not_found"
    | "not_room_member"
    | "invalid_category"
    | "fx_unavailable"
    | "insert_failed";
  details?: string;
}

async function buildFxSnapshot(currency: string): Promise<Record<string, number> | null> {
  const sb = serviceClient();
  const { data } = await sb
    .from("fx_rates")
    .select("currency, rate_per_usd");
  if (!data || data.length === 0) return null;
  const rateOf = (cur: string): number | null => {
    const r = data.find((d) => d.currency === cur);
    return r ? Number(r.rate_per_usd) : null;
  };
  const txnRate = rateOf(currency);
  if (txnRate === null || txnRate === 0) return null;
  const snap: Record<string, number> = {};
  for (const row of data) {
    const target = Number(row.rate_per_usd);
    if (!Number.isFinite(target) || target === 0) continue;
    // 1 unit txn currency -> target currency = target_rate_per_usd / txn_rate_per_usd
    snap[row.currency] = target / txnRate;
  }
  snap[currency] = 1.0;
  return snap;
}

export async function saveTransaction(
  input: SaveTransactionInput,
  ctx: UserContext,
): Promise<SaveTransactionResult | SaveTransactionError> {
  const sb = serviceClient();

  let roomId: string | null = input.roomId ?? null;
  if (roomId) {
    const isMember = ctx.rooms.some((r) => r.id === roomId);
    if (!isMember) return { ok: false, reason: "not_room_member" };
  }

  // Funding (ADR-0023): a room capture defaults to the room's pool — the first
  // active Room account, booked as a Room-account movement. Fall back to the
  // parsed personal account (an Out-of-pocket room expense) only when the room
  // has no Room account. Personal captures use the parsed personal account.
  let accountId: string;
  const pool = roomId
    ? ctx.roomAccounts.find((a) => a.roomId === roomId)
    : undefined;
  if (pool) {
    accountId = pool.id;
  } else {
    const account = ctx.accounts.find(
      (a) => a.name.toLowerCase() === input.accountName.toLowerCase(),
    );
    if (!account) return { ok: false, reason: "account_not_found" };
    accountId = account.id;
  }

  // Category scope guard — personal txns must use user-scoped categories,
  // room txns must use that room's categories, and the category kind must
  // match the transaction type. This is the last line of defence even if a
  // parser or callback path missed validation upstream.
  const categoryMatch = findCategoryInScope(ctx, input.category, input.type, roomId);
  if (!categoryMatch) {
    return {
      ok: false,
      reason: "invalid_category",
      details: roomId
        ? `category '${input.category}' not in room ${roomId} (${input.type})`
        : `category '${input.category}' not in personal scope (${input.type})`,
    };
  }

  const fx = await buildFxSnapshot(input.currency);
  if (!fx) return { ok: false, reason: "fx_unavailable" };

  // Sign convention (post-flip): expense negative, income positive.
  const signed =
    input.type === "expense"
      ? -Math.abs(input.totalPositive)
      : Math.abs(input.totalPositive);

  // Merchant column was dropped (migration 20260501000002). Preserve merchant
  // context by appending into notes — same convention scan-receipt uses.
  // When notes already carry the canonical breakdown shape (merchant on the
  // first line, bullet rows below — produced by Telegram image saves), keep
  // them verbatim so the app's `parseBreakdown` still recognises the
  // structure and renders the item-breakdown UI.
  const merchantTrim = input.merchant?.trim() ?? "";
  const notesTrim = input.notes?.trim() ?? "";
  const notesAlreadyCanonical =
    notesTrim.length > 0 && looksLikeCanonicalBreakdown(notesTrim);
  const firstNoteLine = notesTrim
    .split("\n")
    .map((l) => l.trim())
    .find((l) => l.length > 0) ?? "";
  const firstLineIsMerchant =
    merchantTrim.length > 0 &&
    firstNoteLine.toLowerCase() === merchantTrim.toLowerCase();
  const mergedNotes = notesAlreadyCanonical || firstLineIsMerchant
    ? notesTrim
    : merchantTrim
      ? notesTrim
        ? `${merchantTrim} — ${notesTrim}`
        : merchantTrim
      : notesTrim || null;

  // Persisted timestamp comes from the database default (`now()`). Telegram
  // never sets `created_at`, so parser/caption dates do not override the
  // server-current insert time.
  const insertRow: Record<string, unknown> = {
    user_id: input.userId,
    room_id: roomId,
    account_id: accountId,
    type: input.type,
    amount: signed,
    currency: input.currency,
    category: input.category,
    notes: mergedNotes,
    ai_parsed: input.aiParsed ?? true,
    source: input.source ?? "bot_chat",
    fx_snapshot: fx,
  };

  const { data, error } = await sb
    .from("transactions")
    .insert(insertRow)
    .select("id")
    .single();
  if (error || !data) {
    return { ok: false, reason: "insert_failed", details: error?.message };
  }

  // Fan-out room notifications (best-effort). Server-trusted invocation: pass
  // the contract `room-transaction-notify` expects, plus a service-role
  // bearer header so the function skips its end-user JWT path.
  if (roomId) {
    try {
      const { error: notifyError } = await sb.functions.invoke(
        "room-transaction-notify",
        {
          body: {
            room_id: roomId,
            actor_id: input.userId,
            amount: signed,
            currency: input.currency,
            type: input.type,
            service_role: true,
          },
        },
      );
      if (notifyError) {
        console.error(
          JSON.stringify({
            kind: "bot_room_notify_failed",
            room_id: roomId,
            user_id: input.userId,
            error: notifyError.message ?? String(notifyError),
          }),
        );
      }
    } catch (e) {
      console.error(
        JSON.stringify({
          kind: "bot_room_notify_exception",
          room_id: roomId,
          user_id: input.userId,
          error: e instanceof Error ? e.message : String(e),
        }),
      );
    }
  }

  return {
    ok: true,
    transactionId: data.id,
    signedAmount: signed,
    roomId,
    accountId,
  };
}

export type DeleteTransactionResult =
  | { ok: true }
  | { ok: false; reason: "not_found" | "delete_failed"; details?: string };

export async function deleteTransaction(
  transactionId: string,
  userId: string,
): Promise<DeleteTransactionResult> {
  const sb = serviceClient();
  const { data, error } = await sb
    .from("transactions")
    .delete()
    .eq("id", transactionId)
    .eq("user_id", userId)
    .select("id");
  if (error) {
    return { ok: false, reason: "delete_failed", details: error.message };
  }
  if (!data || data.length === 0) {
    return { ok: false, reason: "not_found" };
  }
  return { ok: true };
}
