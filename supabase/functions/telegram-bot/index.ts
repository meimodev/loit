// Telegram adapter for LOIT messaging pipeline. Keeps Telegram-specific
// concerns (webhook secret, file download, inline keyboards) in this file
// only; everything else lives in `../_shared/`.

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { serviceClient } from "../_shared/supabase.ts";
import { resolveLocale, t, type Locale } from "../_shared/i18n.ts";
import { formatMoneyDisplay } from "../_shared/money.ts";
import {
  consumeLinkCode,
  disconnectChat,
  resolveChat,
  type MessagingLink,
} from "../_shared/messaging_identity.ts";
import { checkRateLimit } from "../_shared/rate_limiter.ts";
import {
  categoriesForScope,
  findCategoryInScope,
  loadUserContext,
  remapCategoryAcrossScopes,
  type AccountRef,
  type CategoryRef,
  type UserContext,
} from "../_shared/user_context.ts";
import {
  extractIntendedRoomName,
  findRoomByName,
  parseCaptionMetadata,
  parseTransactionFromAudio,
  parseTransactionText,
} from "../_shared/text_parser.ts";
// Bot receipt OCR shares the Claude parser with the in-app scanner.
// See docs/adr/0002-telegram-bot-back-to-claude.md.
import { gatedScan } from "../_shared/scan_gate.ts";
import {
  canStoreReceipt,
  deleteStashedReceipt,
  promotePendingReceipt,
  stashPendingReceipt,
  storeReceiptForTxn,
} from "../_shared/receipt_storage.ts";
import {
  saveTransaction,
  deleteTransaction,
} from "../_shared/transaction_saver.ts";
import {
  chargeExtraCredits,
  consumeScanQuota,
  creditsForTokens,
  refundScanQuota,
  remainingFromUsed,
} from "../_shared/quota.ts";
import {
  amountBucket,
  confidenceBucket,
  logBotEvent,
  logBotError,
} from "../_shared/analytics.ts";
import { bytesToBase64 } from "../_shared/base64.ts";
import { preprocessReceiptImage } from "../_shared/image_preprocessor.ts";

const BOT_TOKEN = Deno.env.get("TELEGRAM_BOT_TOKEN")!;
const WEBHOOK_SECRET = Deno.env.get("TELEGRAM_WEBHOOK_SECRET")!;
const APP_DEEP_LINK_BASE = "loit://";
const PLATFORM = "telegram" as const;
const CONFIDENCE_AUTO_SAVE = 0.85;
const PERSONAL_UNDO_HOURS = 24;
const ROOM_UNDO_HOURS = 1;

// -----------------------------------------------------------------
// Telegram REST helpers
// -----------------------------------------------------------------
const TG_BASE = `https://api.telegram.org/bot${BOT_TOKEN}`;

type InlineKeyboardButton = { text: string; callback_data: string };
type InlineKeyboard = InlineKeyboardButton[][];

async function tg<T = unknown>(method: string, payload: unknown): Promise<T | null> {
  try {
    const res = await fetch(`${TG_BASE}/${method}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const json = await res.json();
    if (!json.ok) {
      logBotError(new Error(json.description ?? "tg error"), {
        stage: `tg:${method}`,
        platform: PLATFORM,
      });
      return null;
    }
    return json.result as T;
  } catch (e) {
    logBotError(e, { stage: `tg:${method}`, platform: PLATFORM });
    return null;
  }
}

async function sendMessage(
  chatId: string,
  text: string,
  keyboard?: InlineKeyboard,
  opts?: { html?: boolean },
): Promise<{ message_id: number } | null> {
  return tg<{ message_id: number }>("sendMessage", {
    chat_id: chatId,
    text,
    reply_markup: keyboard ? { inline_keyboard: keyboard } : undefined,
    parse_mode: opts?.html ? "HTML" : undefined,
  });
}

async function editMessage(
  chatId: string,
  messageId: number,
  text: string,
  keyboard?: InlineKeyboard,
  opts?: { html?: boolean },
): Promise<void> {
  await tg("editMessageText", {
    chat_id: chatId,
    message_id: messageId,
    text,
    reply_markup: keyboard ? { inline_keyboard: keyboard } : undefined,
    parse_mode: opts?.html ? "HTML" : undefined,
  });
}

async function answerCallback(callbackId: string, text?: string): Promise<void> {
  await tg("answerCallbackQuery", { callback_query_id: callbackId, text });
}

async function getFilePath(fileId: string): Promise<string | null> {
  const f = await tg<{ file_path: string }>("getFile", { file_id: fileId });
  return f?.file_path ?? null;
}

async function downloadFile(filePath: string): Promise<Uint8Array | null> {
  try {
    const res = await fetch(
      `https://api.telegram.org/file/bot${BOT_TOKEN}/${filePath}`,
    );
    if (!res.ok) return null;
    return new Uint8Array(await res.arrayBuffer());
  } catch (e) {
    logBotError(e, { stage: "tg:downloadFile", platform: PLATFORM });
    return null;
  }
}

// -----------------------------------------------------------------
// Telegram-local date defaulting. Bot transactions always carry a concrete
// YYYY-MM-DD; parsers may return null when the user didn't state a date, in
// which case we stamp today.
// -----------------------------------------------------------------
function todayYmd(): string {
  return new Date().toISOString().slice(0, 10);
}

// -----------------------------------------------------------------
// Formatting
// -----------------------------------------------------------------
function htmlEscape(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

// Resolve a category key to its display name, scoped to where the transaction
// lives. Personal txns prefer user categories; room txns prefer that room's
// categories. Falls back through other scopes, then the raw key for legacy or
// deleted categories.
function categoryDisplayName(
  ctx: UserContext,
  key: string,
  roomId: string | null,
): string {
  const scoped = categoriesForScope(ctx, roomId).find((c) => c.key === key);
  if (scoped) return scoped.name;
  const any = ctx.categories.find((c) => c.key === key);
  return any?.name ?? key;
}

// Localized label for account kind. Inline (vs. i18n strings) because the
// canonical account line composes them with the account name + currency.
function accountKindLabel(locale: Locale, kind: "asset" | "debt"): string {
  if (locale === "id") return kind === "asset" ? "Aset" : "Hutang";
  return kind === "asset" ? "Asset" : "Debt";
}

// Resolve the canonical account display for a transaction summary. Prefers
// `accountOverride` (used when the account isn't in `ctx.accounts`, e.g.
// archived), then `accountId`, then case-insensitive `accountName`. Falls back
// to the provided name (or "?") so the account line is always rendered.
function resolveAccountDisplay(
  ctx: UserContext,
  locale: Locale,
  args: {
    accountId?: string | null;
    accountName?: string | null;
    accountOverride?: AccountRef | null;
  },
): string {
  let account: AccountRef | undefined;
  if (args.accountOverride) {
    account = args.accountOverride;
  }
  if (!account && args.accountId) {
    account = ctx.accounts.find((a) => a.id === args.accountId);
  }
  if (!account && args.accountName) {
    const wanted = args.accountName.toLowerCase();
    account = ctx.accounts.find((a) => a.name.toLowerCase() === wanted);
  }
  if (account) {
    const kindLabel = accountKindLabel(locale, account.kind);
    return `${htmlEscape(account.name)} · ${kindLabel} · ${htmlEscape(account.currency)}`;
  }
  const fallback = args.accountName?.trim();
  return htmlEscape(fallback && fallback.length > 0 ? fallback : "?");
}

// Rich, multi-line HTML summary used by saved/pending/picker replies.
// All dynamic user-controlled strings (merchant, notes, names) are escaped.
function richSummary(
  ctx: UserContext,
  locale: Locale,
  args: {
    type: "expense" | "income";
    total: number;
    currency: string;
    merchant?: string | null;
    category: string;
    accountName: string;
    accountId?: string | null;
    accountOverride?: AccountRef | null;
    roomId?: string | null;
    roomName?: string | null;
    notes?: string | null;
    date?: string | null;
  },
): string {
  const amountStr = formatMoneyDisplay(args.total, args.currency, {
    hide: ctx.hideAmounts,
    locale,
  });
  const sign = args.type === "expense" ? "-" : "+";
  const catName = categoryDisplayName(ctx, args.category, args.roomId ?? null);
  const labelAmount = locale === "id" ? "Jumlah" : "Amount";
  const labelCategory = locale === "id" ? "Kategori" : "Category";
  const labelAccount = locale === "id" ? "Akun" : "Account";
  const labelEmail = "Email";
  const labelRoom = locale === "id" ? "Ruang" : "Room";
  const labelDestination = locale === "id" ? "Tujuan" : "Destination";
  const labelPersonal = locale === "id" ? "Pribadi" : "Personal";
  const labelDate = locale === "id" ? "Tanggal" : "Date";
  const labelNotes = locale === "id" ? "Catatan" : "Notes";
  const lines: string[] = [];
  lines.push(`• ${labelAmount}: <b>${sign}${htmlEscape(amountStr)}</b>`);
  lines.push(`• ${labelCategory}: ${htmlEscape(catName)}`);
  const accountLine = resolveAccountDisplay(ctx, locale, {
    accountId: args.accountId ?? null,
    accountName: args.accountName,
    accountOverride: args.accountOverride ?? null,
  });
  lines.push(`• ${labelAccount}: ${accountLine}`);
  const emailVal = ctx.email?.trim();
  if (emailVal && emailVal.length > 0) {
    lines.push(`• ${labelEmail}: ${htmlEscape(emailVal)}`);
  }
  // Destination: render Room when known, Personal when explicitly personal
  // (roomId === null with no roomName). Skip when destination is still
  // undetermined (caller passes neither).
  if (args.roomName) {
    lines.push(`• ${labelRoom}: ${htmlEscape(args.roomName)}`);
  } else if (args.roomId === null) {
    lines.push(`• ${labelDestination}: ${labelPersonal}`);
  }
  if (args.date && args.date.length > 0) {
    // Normalize to YYYY-MM-DD; accept ISO timestamps from saved rows too.
    const datePart = args.date.length >= 10 ? args.date.slice(0, 10) : args.date;
    lines.push(`• ${labelDate}: ${htmlEscape(datePart)}`);
  }
  const noteVal = args.notes && args.notes.trim().length > 0 ? args.notes.trim() : null;
  const merchantVal = args.merchant && args.merchant.trim().length > 0 ? args.merchant.trim() : null;
  // Merchant column was dropped — merchant flows through notes display only
  // when no explicit note exists.
  const noteDisplay = noteVal ?? merchantVal;
  if (noteDisplay) lines.push(`• ${labelNotes}: ${htmlEscape(noteDisplay)}`);
  return lines.join("\n");
}

function deepLinkForTransaction(transactionId: string, roomId: string | null): string {
  if (roomId) {
    return `${APP_DEEP_LINK_BASE}rooms/${roomId}/transactions/${transactionId}`;
  }
  return `${APP_DEEP_LINK_BASE}transactions/${transactionId}?highlight=${transactionId}`;
}

// -----------------------------------------------------------------
// Undo token helpers
// -----------------------------------------------------------------
async function issueUndoToken(args: {
  userId: string;
  transactionId: string;
  externalChatId: string;
  botMessageId: number | null;
  scope: "personal" | "room";
  roomId: string | null;
}): Promise<string | null> {
  const sb = serviceClient();
  const hours = args.scope === "room" ? ROOM_UNDO_HOURS : PERSONAL_UNDO_HOURS;
  const expires = new Date(Date.now() + hours * 60 * 60 * 1000).toISOString();
  const { data, error } = await sb
    .from("bot_transaction_undo_tokens")
    .insert({
      user_id: args.userId,
      transaction_id: args.transactionId,
      platform: PLATFORM,
      external_chat_id: args.externalChatId,
      bot_message_id: args.botMessageId == null ? null : String(args.botMessageId),
      scope: args.scope,
      room_id: args.roomId,
      expires_at: expires,
    })
    .select("id")
    .single();
  if (error || !data) return null;
  return data.id as string;
}

async function updateUndoTokenMessageId(
  tokenId: string,
  botMessageId: number,
): Promise<void> {
  const sb = serviceClient();
  await sb
    .from("bot_transaction_undo_tokens")
    .update({ bot_message_id: String(botMessageId) })
    .eq("id", tokenId);
}

type UndoLookup =
  | { kind: "ok"; tokenId: string; userId: string; transactionId: string }
  | { kind: "expired" }
  | { kind: "missing" };

async function loadUndoToken(
  tokenId: string,
  link: MessagingLink,
): Promise<UndoLookup> {
  const sb = serviceClient();
  const { data } = await sb
    .from("bot_transaction_undo_tokens")
    .select("id, user_id, transaction_id, expires_at, external_chat_id, platform")
    .eq("id", tokenId)
    .maybeSingle();
  if (!data) return { kind: "missing" };
  if (data.platform !== PLATFORM) return { kind: "missing" };
  if (data.external_chat_id !== link.externalChatId) return { kind: "missing" };
  if (data.user_id !== link.userId) return { kind: "missing" };
  if (new Date(data.expires_at).getTime() < Date.now()) return { kind: "expired" };
  return {
    kind: "ok",
    tokenId: data.id as string,
    userId: data.user_id as string,
    transactionId: data.transaction_id as string,
  };
}

// Resolve an undo token by the Telegram message that carries the inline
// button. Used as a fallback for legacy `undo:pending` callback rows minted
// before commitAndReply switched to mint-then-render.
async function loadUndoTokenByMessageId(
  link: MessagingLink,
  botMessageId: number,
): Promise<UndoLookup> {
  const sb = serviceClient();
  const { data } = await sb
    .from("bot_transaction_undo_tokens")
    .select("id, user_id, transaction_id, expires_at, external_chat_id, platform, bot_message_id")
    .eq("platform", PLATFORM)
    .eq("external_chat_id", link.externalChatId)
    .eq("user_id", link.userId)
    .eq("bot_message_id", String(botMessageId))
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (!data) return { kind: "missing" };
  if (new Date(data.expires_at as string).getTime() < Date.now()) {
    return { kind: "expired" };
  }
  return {
    kind: "ok",
    tokenId: data.id as string,
    userId: data.user_id as string,
    transactionId: data.transaction_id as string,
  };
}

async function latestUndoToken(link: MessagingLink): Promise<UndoLookup> {
  const sb = serviceClient();
  const nowIso = new Date().toISOString();
  // Best-effort sweep of stale tokens for this chat/user — don't await the
  // outcome before selecting; the select below filters expired rows itself.
  sb.from("bot_transaction_undo_tokens")
    .delete()
    .eq("platform", PLATFORM)
    .eq("external_chat_id", link.externalChatId)
    .eq("user_id", link.userId)
    .lt("expires_at", nowIso)
    .then(() => {});
  const { data } = await sb
    .from("bot_transaction_undo_tokens")
    .select("id, user_id, transaction_id, expires_at, external_chat_id, platform")
    .eq("platform", PLATFORM)
    .eq("external_chat_id", link.externalChatId)
    .eq("user_id", link.userId)
    .gt("expires_at", nowIso)
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (!data) return { kind: "missing" };
  return {
    kind: "ok",
    tokenId: data.id as string,
    userId: data.user_id as string,
    transactionId: data.transaction_id as string,
  };
}

// Guard for saved-transaction edit callbacks. An edit is only authorized when
// there's still an unexpired bot_transaction_undo_tokens row tying this chat
// to the transaction. `/end` and app-side disconnect both delete those rows,
// so pre-disconnect Edit buttons stop working after a reconnect.
async function hasSavedTxnAuth(
  link: MessagingLink,
  transactionId: string,
): Promise<boolean> {
  const sb = serviceClient();
  const { data } = await sb
    .from("bot_transaction_undo_tokens")
    .select("id")
    .eq("platform", PLATFORM)
    .eq("external_chat_id", link.externalChatId)
    .eq("user_id", link.userId)
    .eq("transaction_id", transactionId)
    .gt("expires_at", new Date().toISOString())
    .limit(1)
    .maybeSingle();
  return !!data;
}

type UndoOutcome =
  | { kind: "done"; transactionId: string }
  | { kind: "expired" }
  | { kind: "missing" }
  | { kind: "failed" };

async function performUndo(
  link: MessagingLink,
  lookup: UndoLookup,
): Promise<UndoOutcome> {
  if (lookup.kind !== "ok") return { kind: lookup.kind } as UndoOutcome;
  const sb = serviceClient();
  const del = await deleteTransaction(lookup.transactionId, lookup.userId);
  if (!del.ok) {
    if (del.reason === "not_found") {
      // Transaction already gone — drop the dangling token so a repeat /undo
      // doesn't keep retrying.
      await sb
        .from("bot_transaction_undo_tokens")
        .delete()
        .eq("transaction_id", lookup.transactionId);
      return { kind: "missing" };
    }
    return { kind: "failed" };
  }
  // Verified delete — now consume tokens. Wipe siblings for the same
  // transaction so an old inline button can't trigger a second undo.
  await sb
    .from("bot_transaction_undo_tokens")
    .delete()
    .eq("transaction_id", lookup.transactionId);
  return { kind: "done", transactionId: lookup.transactionId };
}

// -----------------------------------------------------------------
// Save + reply flow shared by text/voice/image
// -----------------------------------------------------------------
type CommitOutcome =
  | {
      ok: true;
      transactionId: string;
      roomId: string | null;
      botMessageId: number | null;
    }
  | { ok: false; reason: string };

// Per-capture AI Credit footer (ADR-0017). Empty for unlimited tiers
// (remaining=null) or when no credit info is supplied. Shows the cost only
// when a capture drew more than 1 credit.
function creditFooter(
  locale: Locale,
  credits?: { charged: number; remaining: number | null },
): string {
  if (!credits || credits.remaining === null) return "";
  const key = credits.charged > 1 ? "botCreditsFooterCharged" : "botCreditsFooter";
  return "\n" + t(locale, key, {
    charged: String(credits.charged),
    remaining: String(credits.remaining),
  });
}

async function commitAndReply(args: {
  link: MessagingLink;
  ctx: UserContext;
  locale: Locale;
  type: "expense" | "income";
  total: number;
  currency: string;
  merchant: string | null;
  category: string;
  accountName: string;
  notes: string | null;
  items?: Array<{
    name?: string | null;
    qty?: number | null;
    unit_price?: number | null;
    total_price?: number | null;
  }> | null;
  roomId: string | null;
  confidence: number | null;
  sourceType: "text" | "voice" | "image";
  // AI Credits charged + remaining for this capture (ADR-0017). Omitted/
  // remaining=null ⇒ no footer (unlimited tier).
  credits?: { charged: number; remaining: number | null };
}): Promise<CommitOutcome> {
  // Best-effort scope correction before save. If a parser produced a personal
  // category for a room transaction (or vice versa), try to remap by name —
  // typical when a low-confidence parse later gets a room destination chosen.
  let effectiveCategory = args.category;
  if (!findCategoryInScope(args.ctx, effectiveCategory, args.type, args.roomId)) {
    const remapped = remapCategoryAcrossScopes(
      args.ctx,
      effectiveCategory,
      args.type,
      args.roomId,
    );
    if (remapped) effectiveCategory = remapped;
  }

  const canonicalSource =
    args.sourceType === "image" ? "bot_image" : "bot_chat";
  // Persisted `created_at` is set by the database (now()); parser/caption
  // dates are display-only and never override the server timestamp.
  const save = await saveTransaction(
    {
      userId: args.link.userId,
      type: args.type,
      totalPositive: Math.abs(args.total),
      currency: args.currency,
      category: effectiveCategory,
      accountName: args.accountName,
      merchant: args.merchant,
      notes: args.notes,
      items: args.items ?? null,
      roomId: args.roomId,
      aiParsed: true,
      source: canonicalSource,
    },
    args.ctx,
  );
  if (!save.ok) {
    if (save.reason === "invalid_category") {
      await offerInvalidCategoryPicker(args);
    } else {
      await sendMessage(args.link.externalChatId, t(args.locale, "botParseFailed"));
    }
    logBotEvent({
      event: "bot_save_failed",
      platform: PLATFORM,
      messageType: args.sourceType,
      userId: args.link.userId,
      extra: { reason: save.reason },
    });
    return { ok: false, reason: save.reason };
  }
  // From here on, summaries should reflect the actual saved key.
  args = { ...args, category: effectiveCategory };
  const roomName =
    args.roomId ? args.ctx.rooms.find((r) => r.id === args.roomId)?.name ?? null : null;
  const summary = richSummary(args.ctx, args.locale, {
    type: args.type,
    total: args.total,
    currency: args.currency,
    merchant: args.merchant,
    category: args.category,
    accountName: args.accountName,
    accountId: save.accountId,
    roomId: args.roomId,
    roomName,
    notes: args.notes,
    date: todayYmd(),
  });
  const savedKey = args.type === "income" ? "botIncomeSaved" : "botTransactionSaved";
  const reply = t(args.locale, savedKey, { summary }) + creditFooter(args.locale, args.credits);
  // Mint the undo token BEFORE sending so the rendered button carries the
  // real id. `bot_message_id` is patched in once Telegram returns it.
  const tokenId = await issueUndoToken({
    userId: args.link.userId,
    transactionId: save.transactionId,
    externalChatId: args.link.externalChatId,
    botMessageId: null,
    scope: args.roomId ? "room" : "personal",
    roomId: args.roomId,
  });
  const undoCallback = tokenId ? `undo:${tokenId}` : `undo:pending`;
  const msg = await sendMessage(
    args.link.externalChatId,
    reply,
    [
      [
        { text: t(args.locale, "btnUndo"), callback_data: undoCallback },
        { text: t(args.locale, "btnEdit"), callback_data: `edit:t:${save.transactionId}` },
      ],
    ],
    { html: true },
  );
  const botMessageId: number | null = msg?.message_id ?? null;
  if (tokenId && botMessageId != null) {
    await updateUndoTokenMessageId(tokenId, botMessageId);
  }

  logBotEvent({
    event: "bot_transaction_saved",
    platform: PLATFORM,
    messageType: args.sourceType,
    scope: args.roomId ? "room" : "personal",
    confidence: confidenceBucket(args.confidence),
    amountBucket: amountBucket(args.total),
    userId: args.link.userId,
  });
  return { ok: true, transactionId: save.transactionId, roomId: args.roomId, botMessageId };
}

// -----------------------------------------------------------------
// Pending transaction (low-confidence) helpers
// -----------------------------------------------------------------
async function createPending(
  link: MessagingLink,
  locale: Locale,
  payload: Record<string, unknown>,
  confidence: number,
  summary: string,
  sourceType: "text" | "voice" | "image",
  // When present (low-confidence image on a storage-eligible tier), the photo
  // is stashed and the path recorded on the row so `pconfirm` can promote it.
  imageBytes?: Uint8Array,
): Promise<void> {
  const sb = serviceClient();
  const stamped: Record<string, unknown> = { ...payload, sourceType };
  const { data } = await sb
    .from("bot_pending_transactions")
    .insert({
      user_id: link.userId,
      platform: PLATFORM,
      external_chat_id: link.externalChatId,
      payload: stamped,
      confidence,
    })
    .select("id")
    .single();
  if (!data) {
    await sendMessage(link.externalChatId, t(locale, "botParseFailed"));
    return;
  }
  if (imageBytes) {
    const stash = await stashPendingReceipt(
      link.userId,
      data.id as string,
      imageBytes,
    );
    if (stash) {
      stamped.receiptStash = stash;
      await sb
        .from("bot_pending_transactions")
        .update({ payload: stamped })
        .eq("id", data.id);
    }
  }
  const msg = await sendMessage(
    link.externalChatId,
    t(locale, "botPendingConfirm", { summary }),
    [
      [
        { text: t(locale, "btnConfirm"), callback_data: `pconfirm:${data.id}` },
        { text: t(locale, "btnCancel"), callback_data: `pcancel:${data.id}` },
      ],
      [
        { text: t(locale, "btnEdit"), callback_data: `edit:p:${data.id}` },
      ],
    ],
    { html: true },
  );
  if (msg) {
    await sb
      .from("bot_pending_transactions")
      .update({ bot_message_id: String(msg.message_id) })
      .eq("id", data.id);
  }
}

// Recovery path: save was rejected with `invalid_category`. Park the
// parsed payload as a pending transaction and send a destination-scoped
// category keyboard. The existing `pick:<idx>` callback writes the chosen
// key onto the pending row; the user then taps Confirm to finalize.
async function offerInvalidCategoryPicker(args: {
  link: MessagingLink;
  ctx: UserContext;
  locale: Locale;
  type: "expense" | "income";
  total: number;
  currency: string;
  merchant: string | null;
  category: string;
  accountName: string;
  notes: string | null;
  items?: Array<{
    name?: string | null;
    qty?: number | null;
    unit_price?: number | null;
    total_price?: number | null;
  }> | null;
  roomId: string | null;
  sourceType: "text" | "voice" | "image";
}): Promise<void> {
  const sb = serviceClient();
  const payload: Record<string, unknown> = {
    type: args.type,
    total: args.total,
    currency: args.currency,
    merchant: args.merchant,
    // category will be overwritten by the pick callback; keep the rejected
    // key around for telemetry / debugging.
    category: args.category,
    account: args.accountName,
    notes: args.notes,
    roomId: args.roomId,
    sourceType: args.sourceType,
  };
  const { data } = await sb
    .from("bot_pending_transactions")
    .insert({
      user_id: args.link.userId,
      platform: PLATFORM,
      external_chat_id: args.link.externalChatId,
      payload,
      confidence: 0.4,
    })
    .select("id")
    .single();
  if (!data) {
    await sendMessage(args.link.externalChatId, t(args.locale, "botInvalidCategory"));
    return;
  }
  const pendingId = data.id as string;
  await openEditSession(args.link, { type: "p", id: pendingId }, "category");
  const keyboard = categoryKeyboard(args.ctx, args.roomId, args.type);
  const msg = await sendMessage(
    args.link.externalChatId,
    t(args.locale, "botInvalidCategory"),
    keyboard,
    { html: true },
  );
  if (msg) {
    await sb
      .from("bot_pending_transactions")
      .update({ bot_message_id: String(msg.message_id) })
      .eq("id", pendingId);
  }
  logBotEvent({
    event: "bot_invalid_category_picker",
    platform: PLATFORM,
    messageType: args.sourceType,
    scope: args.roomId ? "room" : "personal",
    userId: args.link.userId,
  });
}

// @deprecated 2026-05-21 — destination is now auto-detected from message
// content (text/voice via destination_room, image via caption). Retained for
// one TTL cycle so in-flight `bot_pending_transactions` rows with
// state="awaiting_destination" still resolve via the `dest:` callback. Safe
// to delete in a follow-up PR after the deprecation window.
// deno-lint-ignore no-unused-vars
async function offerDestinationPicker(
  link: MessagingLink,
  ctx: UserContext,
  locale: Locale,
  payload: Record<string, unknown>,
  confidence: number,
  summary: string,
  sourceType: "text" | "voice" | "image",
): Promise<void> {
  const sb = serviceClient();
  const stamped = { ...payload, sourceType };
  const { data } = await sb
    .from("bot_pending_transactions")
    .insert({
      user_id: link.userId,
      platform: PLATFORM,
      external_chat_id: link.externalChatId,
      payload: stamped,
      confidence,
      state: "awaiting_destination",
    })
    .select("id")
    .single();
  if (!data) {
    await sendMessage(link.externalChatId, t(locale, "botParseFailed"));
    return;
  }
  // Use index-based callbacks — UUID room IDs would overflow Telegram's
  // 64-byte callback_data limit when combined with pending UUID + prefix.
  const buttons: InlineKeyboardButton[][] = [
    [{ text: t(locale, "btnPersonal"), callback_data: `dest:${data.id}:p` }],
  ];
  ctx.rooms.forEach((room, idx) => {
    buttons.push([
      { text: room.name, callback_data: `dest:${data.id}:${idx}` },
    ]);
  });
  buttons.push([
    { text: t(locale, "btnCancel"), callback_data: `pcancel:${data.id}` },
  ]);
  const msg = await sendMessage(
    link.externalChatId,
    `${t(locale, "botRoomPicker")}\n${summary}`,
    buttons,
    { html: true },
  );
  if (msg) {
    await sb
      .from("bot_pending_transactions")
      .update({ bot_message_id: String(msg.message_id) })
      .eq("id", data.id);
  }
}

// Cancel all active bot work for this chat/user — latest unexpired pending
// row plus any open edit sessions. Edits the original pending prompt so the
// stale buttons no longer feel actionable. Returns what was cleared so the
// caller can pick the right reply.
async function cancelActiveWork(
  link: MessagingLink,
  locale: Locale,
  opts?: { pendingId?: string },
): Promise<{ pendingCancelled: boolean; editCancelled: boolean }> {
  const sb = serviceClient();
  let pendingRow:
    | { id: string; bot_message_id: string | null; stash: string | null }
    | null = null;
  if (opts?.pendingId) {
    const { data } = await sb
      .from("bot_pending_transactions")
      .select("id, bot_message_id, payload")
      .eq("id", opts.pendingId)
      .eq("user_id", link.userId)
      .maybeSingle();
    if (data) {
      const stashPath = (data.payload as Record<string, unknown> | null)
        ?.receiptStash;
      pendingRow = {
        id: data.id as string,
        bot_message_id: (data.bot_message_id as string | null) ?? null,
        stash: typeof stashPath === "string" ? stashPath : null,
      };
    }
  } else {
    const { data } = await sb
      .from("bot_pending_transactions")
      .select("id, bot_message_id, payload")
      .eq("platform", PLATFORM)
      .eq("external_chat_id", link.externalChatId)
      .eq("user_id", link.userId)
      .gt("expires_at", new Date().toISOString())
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (data) {
      const stashPath = (data.payload as Record<string, unknown> | null)
        ?.receiptStash;
      pendingRow = {
        id: data.id as string,
        bot_message_id: (data.bot_message_id as string | null) ?? null,
        stash: typeof stashPath === "string" ? stashPath : null,
      };
    }
  }
  let pendingCancelled = false;
  if (pendingRow) {
    if (pendingRow.stash) await deleteStashedReceipt(pendingRow.stash);
    await sb.from("bot_pending_transactions").delete().eq("id", pendingRow.id);
    pendingCancelled = true;
    const msgIdRaw = pendingRow.bot_message_id;
    const msgId = msgIdRaw ? Number(msgIdRaw) : NaN;
    if (Number.isFinite(msgId)) {
      await editMessage(link.externalChatId, msgId, t(locale, "botCancelled"));
    }
  }
  const { data: editRows } = await sb
    .from("bot_edit_sessions")
    .select("id")
    .eq("platform", PLATFORM)
    .eq("external_chat_id", link.externalChatId)
    .eq("user_id", link.userId);
  let editCancelled = false;
  if (editRows && editRows.length > 0) {
    await sb
      .from("bot_edit_sessions")
      .delete()
      .eq("platform", PLATFORM)
      .eq("external_chat_id", link.externalChatId)
      .eq("user_id", link.userId);
    editCancelled = true;
  }
  return { pendingCancelled, editCancelled };
}

// -----------------------------------------------------------------
// Edit session helpers (multi-turn field edits)
// -----------------------------------------------------------------
type EditTarget =
  | { type: "t"; id: string }
  | { type: "p"; id: string };

type FreeTextField = "amount" | "notes" | "date";
type KeyboardField = "category" | "account" | "dest";
type EditField = FreeTextField | KeyboardField;

async function openEditSession(
  link: MessagingLink,
  target: EditTarget,
  field: EditField,
): Promise<string | null> {
  const sb = serviceClient();
  // Replace any open session for the same chat so users don't get stuck.
  await sb
    .from("bot_edit_sessions")
    .delete()
    .eq("platform", PLATFORM)
    .eq("external_chat_id", link.externalChatId)
    .eq("user_id", link.userId);
  const insert: Record<string, unknown> = {
    user_id: link.userId,
    platform: PLATFORM,
    external_chat_id: link.externalChatId,
    awaiting_field: field,
    context: { target },
  };
  if (target.type === "t") insert.transaction_id = target.id;
  const { data } = await sb
    .from("bot_edit_sessions")
    .insert(insert)
    .select("id")
    .single();
  return data?.id ?? null;
}

async function loadActiveEditSession(
  link: MessagingLink,
): Promise<
  | { id: string; target: EditTarget; awaitingField: string }
  | null
> {
  const sb = serviceClient();
  const { data } = await sb
    .from("bot_edit_sessions")
    .select("id, transaction_id, awaiting_field, context, expires_at")
    .eq("platform", PLATFORM)
    .eq("external_chat_id", link.externalChatId)
    .eq("user_id", link.userId)
    .gt("expires_at", new Date().toISOString())
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (!data) return null;
  const ctx = (data.context ?? {}) as { target?: EditTarget };
  const target: EditTarget =
    ctx.target ?? { type: "t", id: data.transaction_id as string };
  return {
    id: data.id as string,
    target,
    awaitingField: data.awaiting_field as string,
  };
}

async function closeEditSession(sessionId: string): Promise<void> {
  const sb = serviceClient();
  await sb.from("bot_edit_sessions").delete().eq("id", sessionId);
}

// -----------------------------------------------------------------
// Edit window enforcement
// 24h personal, 1h room. For saved transactions the authoritative clock is
// the matching bot_transaction_undo_tokens row (issued at save time), NOT
// transactions.created_at — which now reflects the transaction's occurrence
// date (today midnight or an explicit backdated YYYY-MM-DD) and would
// expire the edit window immediately for past dates.
// -----------------------------------------------------------------
async function checkEditWindow(
  link: MessagingLink,
  target: EditTarget,
): Promise<
  | { kind: "ok_txn"; roomId: string | null; createdAt: string }
  | { kind: "ok_pending"; payload: Record<string, unknown>; confidence: number | null }
  | { kind: "expired"; roomId: string | null }
  | { kind: "not_found" }
> {
  const sb = serviceClient();
  if (target.type === "t") {
    const { data: txn } = await sb
      .from("transactions")
      .select("created_at, room_id")
      .eq("id", target.id)
      .eq("user_id", link.userId)
      .maybeSingle();
    if (!txn) return { kind: "not_found" };
    const roomId: string | null = txn.room_id ?? null;
    const { data: token } = await sb
      .from("bot_transaction_undo_tokens")
      .select("expires_at, scope")
      .eq("transaction_id", target.id)
      .eq("platform", PLATFORM)
      .eq("external_chat_id", link.externalChatId)
      .eq("user_id", link.userId)
      .order("created_at", { ascending: false })
      .limit(1)
      .maybeSingle();
    if (!token || new Date(token.expires_at as string).getTime() < Date.now()) {
      return { kind: "expired", roomId };
    }
    return { kind: "ok_txn", roomId, createdAt: txn.created_at as string };
  }
  const { data } = await sb
    .from("bot_pending_transactions")
    .select("payload, confidence, expires_at")
    .eq("id", target.id)
    .eq("user_id", link.userId)
    .maybeSingle();
  if (!data) return { kind: "not_found" };
  if (new Date(data.expires_at as string).getTime() < Date.now()) {
    return { kind: "expired", roomId: null };
  }
  const payload = (data.payload ?? {}) as Record<string, unknown>;
  return {
    kind: "ok_pending",
    payload,
    confidence: typeof data.confidence === "number" ? data.confidence : null,
  };
}

function parseEditTarget(arg1: string, arg2: string): EditTarget | null {
  if (arg1 === "t" || arg1 === "p") {
    if (!arg2) return null;
    return { type: arg1, id: arg2 };
  }
  return null;
}

// Inline keyboards for category/account/destination pick using pick:<idx>
// callbacks; the active edit_session resolves idx → value. Required because
// Telegram caps callback_data at 64 bytes and UUID-heavy callbacks overflow.
function scopedCategoryList(
  ctx: UserContext,
  roomId: string | null,
  kind: "expense" | "income",
): CategoryRef[] {
  return categoriesForScope(ctx, roomId).filter((c) => c.kind === kind);
}

function categoryKeyboard(
  ctx: UserContext,
  roomId: string | null,
  kind: "expense" | "income",
): InlineKeyboard {
  const buttons: InlineKeyboardButton[] = scopedCategoryList(ctx, roomId, kind).map(
    (c, idx) => ({ text: c.name, callback_data: `pick:${idx}` }),
  );
  const rows: InlineKeyboardButton[][] = [];
  for (let i = 0; i < buttons.length; i += 2) {
    rows.push(buttons.slice(i, i + 2));
  }
  return rows;
}

// Resolve the destination scope + transaction kind for an edit target so the
// category keyboard / pick resolver can stay aligned. Returns null if the
// target row vanished.
async function resolveTargetMeta(
  link: MessagingLink,
  target: EditTarget,
): Promise<{ roomId: string | null; kind: "expense" | "income" } | null> {
  const sb = serviceClient();
  if (target.type === "t") {
    const { data } = await sb
      .from("transactions")
      .select("room_id, amount, type")
      .eq("id", target.id)
      .eq("user_id", link.userId)
      .maybeSingle();
    if (!data) return null;
    const roomId: string | null = (data.room_id as string | null) ?? null;
    const kind: "expense" | "income" =
      data.type === "income" ? "income" : Number(data.amount) < 0 ? "expense" : "income";
    return { roomId, kind };
  }
  const { data } = await sb
    .from("bot_pending_transactions")
    .select("payload")
    .eq("id", target.id)
    .eq("user_id", link.userId)
    .maybeSingle();
  if (!data) return null;
  const p = (data.payload ?? {}) as Record<string, unknown>;
  const roomId = typeof p.roomId === "string" ? (p.roomId as string) : null;
  const kind: "expense" | "income" = p.type === "income" ? "income" : "expense";
  return { roomId, kind };
}

function accountKeyboard(ctx: UserContext): InlineKeyboard {
  const buttons: InlineKeyboardButton[] = ctx.accounts.map((a, idx) => ({
    text: a.name,
    callback_data: `pick:${idx}`,
  }));
  const rows: InlineKeyboardButton[][] = [];
  for (let i = 0; i < buttons.length; i += 2) {
    rows.push(buttons.slice(i, i + 2));
  }
  return rows;
}

function destinationKeyboard(ctx: UserContext, locale: Locale): InlineKeyboard {
  // Index 0 = personal, then one entry per room (idx = 1 + roomIndex).
  const rows: InlineKeyboardButton[][] = [
    [{ text: t(locale, "btnPersonal"), callback_data: `pick:0` }],
  ];
  ctx.rooms.forEach((room, i) => {
    rows.push([{ text: room.name, callback_data: `pick:${i + 1}` }]);
  });
  return rows;
}

// Build a summary string for a saved transaction by reading the current row
// + user context. Returns null if the row can't be reconstructed.
async function summarizeSavedTransaction(
  ctx: UserContext,
  locale: Locale,
  link: MessagingLink,
  transactionId: string,
): Promise<{ summary: string; roomId: string | null } | null> {
  const sb = serviceClient();
  const { data } = await sb
    .from("transactions")
    .select("amount, currency, category, account_id, room_id, notes, type, created_at")
    .eq("id", transactionId)
    .eq("user_id", link.userId)
    .maybeSingle();
  if (!data) return null;
  const accountId: string | null = (data.account_id as string | null) ?? null;
  let account = accountId
    ? ctx.accounts.find((a) => a.id === accountId)
    : undefined;
  let accountOverride: AccountRef | null = null;
  if (!account && accountId) {
    // Account may be archived (loadUserContext filters those out) — fetch
    // directly so summaries of older transactions still show current info.
    const { data: dbAcc } = await sb
      .from("accounts")
      .select("id, name, currency, kind")
      .eq("id", accountId)
      .eq("user_id", link.userId)
      .maybeSingle();
    if (dbAcc) {
      accountOverride = {
        id: dbAcc.id as string,
        name: dbAcc.name as string,
        currency: dbAcc.currency as string,
        kind: dbAcc.kind as "asset" | "debt",
      };
    }
  }
  const roomId: string | null = (data.room_id as string | null) ?? null;
  const room = roomId ? ctx.rooms.find((r) => r.id === roomId) ?? null : null;
  const signedAmount = Number(data.amount);
  const type: "expense" | "income" = signedAmount < 0 ? "expense" : "income";
  const summary = richSummary(ctx, locale, {
    type,
    total: signedAmount,
    currency: data.currency,
    merchant: null,
    category: data.category,
    accountName: account?.name ?? accountOverride?.name ?? "?",
    accountId,
    accountOverride,
    roomId,
    roomName: room?.name ?? null,
    notes: typeof data.notes === "string" ? data.notes : null,
    date: typeof data.created_at === "string" ? data.created_at : null,
  });
  return { summary, roomId };
}

// Build a summary string for a pending transaction by reading the current
// payload + user context. Returns null if the row can't be reconstructed.
async function summarizePendingTransaction(
  ctx: UserContext,
  locale: Locale,
  link: MessagingLink,
  pendingId: string,
): Promise<{ summary: string; roomId: string | null } | null> {
  const sb = serviceClient();
  const { data } = await sb
    .from("bot_pending_transactions")
    .select("payload")
    .eq("id", pendingId)
    .eq("user_id", link.userId)
    .maybeSingle();
  if (!data) return null;
  const p: any = (data.payload ?? {}) as Record<string, unknown>;
  const roomId = typeof p.roomId === "string" ? (p.roomId as string) : null;
  const room = roomId ? ctx.rooms.find((r) => r.id === roomId) ?? null : null;
  const summary = richSummary(ctx, locale, {
    type: p.type === "income" ? "income" : "expense",
    total: Number(p.total),
    currency: p.currency,
    merchant: typeof p.merchant === "string" ? p.merchant : null,
    category: p.category,
    accountName: p.account,
    roomId,
    roomName: room?.name ?? null,
    notes: typeof p.notes === "string" ? p.notes : null,
    // Pending bot transactions always save with server-current timestamp;
    // never echo a stored payload date.
    date: null,
  });
  return { summary, roomId };
}

// Single entry point used by edit prompts + apply-confirmation messages.
async function buildTargetSummary(
  ctx: UserContext,
  locale: Locale,
  link: MessagingLink,
  target: EditTarget,
): Promise<string | null> {
  const res = target.type === "t"
    ? await summarizeSavedTransaction(ctx, locale, link, target.id)
    : await summarizePendingTransaction(ctx, locale, link, target.id);
  return res?.summary ?? null;
}

// Find the bot message id for a saved transaction by looking up its undo
// token (undo TTL matches edit window). Returns null when not tracked.
async function findBotMessageIdForTxn(
  link: MessagingLink,
  transactionId: string,
): Promise<number | null> {
  const sb = serviceClient();
  const { data } = await sb
    .from("bot_transaction_undo_tokens")
    .select("bot_message_id, id, expires_at")
    .eq("transaction_id", transactionId)
    .eq("external_chat_id", link.externalChatId)
    .eq("platform", PLATFORM)
    .gt("expires_at", new Date().toISOString())
    .order("created_at", { ascending: false })
    .limit(1)
    .maybeSingle();
  if (!data || !data.bot_message_id) return null;
  const n = Number(data.bot_message_id);
  return Number.isFinite(n) ? n : null;
}

async function findBotMessageIdForPending(
  link: MessagingLink,
  pendingId: string,
): Promise<{ messageId: number; row: Record<string, unknown> } | null> {
  const sb = serviceClient();
  const { data } = await sb
    .from("bot_pending_transactions")
    .select("bot_message_id, payload, confidence")
    .eq("id", pendingId)
    .eq("user_id", link.userId)
    .maybeSingle();
  if (!data || !data.bot_message_id) return null;
  const n = Number(data.bot_message_id);
  if (!Number.isFinite(n)) return null;
  return { messageId: n, row: data };
}

// Update the original "Saved: …" or "Confirm: …" message after an edit
// applied so the visible summary reflects the new state.
async function refreshOriginalMessage(
  ctx: UserContext,
  link: MessagingLink,
  locale: Locale,
  target: EditTarget,
): Promise<void> {
  if (target.type === "t") {
    const msgId = await findBotMessageIdForTxn(link, target.id);
    if (msgId === null) return;
    const result = await summarizeSavedTransaction(ctx, locale, link, target.id);
    if (!result) return;
    await editMessage(
      link.externalChatId,
      msgId,
      t(locale, "botTransactionSaved", { summary: result.summary }),
      [
        [
          { text: t(locale, "btnEdit"), callback_data: `edit:t:${target.id}` },
        ],
      ],
      { html: true },
    );
    return;
  }
  // pending
  const found = await findBotMessageIdForPending(link, target.id);
  if (!found) return;
  const summarized = await summarizePendingTransaction(ctx, locale, link, target.id);
  if (!summarized) return;
  await editMessage(
    link.externalChatId,
    found.messageId,
    t(locale, "botPendingConfirm", { summary: summarized.summary }),
    [
      [
        { text: t(locale, "btnConfirm"), callback_data: `pconfirm:${target.id}` },
        { text: t(locale, "btnCancel"), callback_data: `pcancel:${target.id}` },
      ],
      [{ text: t(locale, "btnEdit"), callback_data: `edit:p:${target.id}` }],
    ],
    { html: true },
  );
}

// Resolve a keyboard pick index against the user context. Returns the field
// being changed and the concrete value to write.
function resolvePickValue(
  ctx: UserContext,
  field: KeyboardField,
  idx: number,
  scope: { roomId: string | null; kind: "expense" | "income" } | null,
):
  | { kind: "category"; key: string }
  | { kind: "account"; id: string }
  | { kind: "dest"; roomId: string | null }
  | null {
  if (field === "category") {
    if (!scope) return null;
    const list = scopedCategoryList(ctx, scope.roomId, scope.kind);
    const cat = list[idx];
    if (!cat) return null;
    return { kind: "category", key: cat.key };
  }
  if (field === "account") {
    const acc = ctx.accounts[idx];
    if (!acc) return null;
    return { kind: "account", id: acc.id };
  }
  if (idx === 0) return { kind: "dest", roomId: null };
  const room = ctx.rooms[idx - 1];
  if (!room) return null;
  return { kind: "dest", roomId: room.id };
}

// Apply a resolved keyboard pick to the target row.
async function applyKeyboardEdit(
  link: MessagingLink,
  ctx: UserContext,
  target: EditTarget,
  resolved:
    | { kind: "category"; key: string }
    | { kind: "account"; id: string }
    | { kind: "dest"; roomId: string | null },
): Promise<boolean> {
  const sb = serviceClient();
  if (target.type === "t") {
    const update: Record<string, unknown> = {};
    if (resolved.kind === "category") {
      update.category = resolved.key;
    } else if (resolved.kind === "account") {
      update.account_id = resolved.id;
    } else {
      update.room_id = resolved.roomId;
      // Re-scope category when destination changes — keep transaction valid
      // against the post-update scope rules enforced by saveTransaction.
      const { data: cur } = await sb
        .from("transactions")
        .select("category, amount, type")
        .eq("id", target.id)
        .eq("user_id", link.userId)
        .maybeSingle();
      if (cur) {
        const kind: "expense" | "income" =
          cur.type === "income" ? "income" : Number(cur.amount) < 0 ? "expense" : "income";
        if (!findCategoryInScope(ctx, cur.category as string, kind, resolved.roomId)) {
          const remapped = remapCategoryAcrossScopes(
            ctx,
            cur.category as string,
            kind,
            resolved.roomId,
          );
          if (remapped) update.category = remapped;
        }
      }
    }
    const { error } = await sb
      .from("transactions")
      .update(update)
      .eq("id", target.id)
      .eq("user_id", link.userId);
    return !error;
  }
  // pending
  const { data: row } = await sb
    .from("bot_pending_transactions")
    .select("payload")
    .eq("id", target.id)
    .eq("user_id", link.userId)
    .maybeSingle();
  if (!row) return false;
  const payload = { ...(row.payload as Record<string, unknown>) };
  if (resolved.kind === "category") {
    payload.category = resolved.key;
  } else if (resolved.kind === "account") {
    // Pending payload stores account name (parser convention).
    const acc = (await (async () => {
      const all = await sb
        .from("accounts")
        .select("id, name")
        .eq("id", resolved.id)
        .maybeSingle();
      return all.data;
    })());
    if (!acc) return false;
    payload.account = acc.name;
  } else {
    payload.roomId = resolved.roomId;
    const kind: "expense" | "income" =
      payload.type === "income" ? "income" : "expense";
    const curCat = typeof payload.category === "string" ? payload.category : "";
    if (curCat && !findCategoryInScope(ctx, curCat, kind, resolved.roomId)) {
      const remapped = remapCategoryAcrossScopes(ctx, curCat, kind, resolved.roomId);
      if (remapped) payload.category = remapped;
    }
  }
  const { error } = await sb
    .from("bot_pending_transactions")
    .update({ payload })
    .eq("id", target.id)
    .eq("user_id", link.userId);
  return !error;
}

async function applyEditFromText(
  link: MessagingLink,
  ctx: UserContext,
  locale: Locale,
  session: { id: string; target: EditTarget; awaitingField: string },
  rawText: string,
): Promise<void> {
  const sb = serviceClient();
  const text = rawText.trim();
  const field = session.awaitingField;
  // Saved-txn edits need a live undo-token row. Without it (e.g. after `/end`
  // wiped state), drop the session and the message silently.
  if (
    session.target.type === "t" &&
    !(await hasSavedTxnAuth(link, session.target.id))
  ) {
    await closeEditSession(session.id);
    return;
  }
  // Enforce edit window before applying.
  const win = await checkEditWindow(link, session.target);
  if (win.kind === "not_found" || win.kind === "expired") {
    await closeEditSession(session.id);
    if (win.kind === "expired") {
      const url = await deepLinkForTarget(link, session.target);
      await sendMessage(
        link.externalChatId,
        `${t(locale, "botEditWindowExpired")} ${url}`,
      );
    } else {
      await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
    }
    return;
  }

  if (session.target.type === "t") {
    const update: Record<string, unknown> = {};
    if (field === "amount") {
      const cleaned = text.replace(/[^0-9.\-]/g, "");
      const n = Number(cleaned);
      if (!Number.isFinite(n) || n === 0) {
        await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
        return;
      }
      const { data: row } = await sb
        .from("transactions")
        .select("amount")
        .eq("id", session.target.id)
        .eq("user_id", link.userId)
        .maybeSingle();
      const currentSign = row && Number(row.amount) < 0 ? -1 : 1;
      update.amount = currentSign * Math.abs(n);
    } else if (field === "notes") {
      update.notes = text.length > 0 ? text : null;
    } else if (field === "date") {
      // Telegram bot transactions always use server-current timestamp; date
      // edits are not allowed.
      await closeEditSession(session.id);
      await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
      return;
    } else {
      await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
      return;
    }
    const { error } = await sb
      .from("transactions")
      .update(update)
      .eq("id", session.target.id)
      .eq("user_id", link.userId);
    await closeEditSession(session.id);
    if (error) {
      await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
      logBotError(error, {
        stage: "edit_apply",
        platform: PLATFORM,
        userId: link.userId,
      });
      return;
    }
  } else {
    // pending edit
    if (win.kind !== "ok_pending") {
      await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
      return;
    }
    const payload = { ...win.payload };
    if (field === "amount") {
      const cleaned = text.replace(/[^0-9.\-]/g, "");
      const n = Number(cleaned);
      if (!Number.isFinite(n) || n === 0) {
        await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
        return;
      }
      payload.total = Math.abs(n);
    } else if (field === "notes") {
      payload.notes = text.length > 0 ? text : null;
    } else if (field === "date") {
      // Telegram bot pending transactions always save with server-current
      // timestamp; date edits are not allowed.
      await closeEditSession(session.id);
      await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
      return;
    } else {
      await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
      return;
    }
    const { error } = await sb
      .from("bot_pending_transactions")
      .update({ payload })
      .eq("id", session.target.id)
      .eq("user_id", link.userId);
    await closeEditSession(session.id);
    if (error) {
      await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
      logBotError(error, {
        stage: "edit_apply_pending",
        platform: PLATFORM,
        userId: link.userId,
      });
      return;
    }
  }

  const newSummary = await buildTargetSummary(ctx, locale, link, session.target);
  await sendMessage(
    link.externalChatId,
    newSummary
      ? t(locale, "botEditAppliedSummary", { summary: newSummary })
      : t(locale, "botEditApplied"),
    undefined,
    { html: true },
  );
  await refreshOriginalMessage(ctx, link, locale, session.target);
  logBotEvent({
    event: "bot_transaction_edited",
    platform: PLATFORM,
    messageType: "text",
    userId: link.userId,
    // Only the field name — never raw values.
    extra: { field, target: session.target.type },
  });
}

// Build a deep link for an edit target. Honors room context (instead of
// always rendering a personal link).
async function deepLinkForTarget(
  link: MessagingLink,
  target: EditTarget,
): Promise<string> {
  const sb = serviceClient();
  if (target.type === "t") {
    const { data } = await sb
      .from("transactions")
      .select("room_id")
      .eq("id", target.id)
      .eq("user_id", link.userId)
      .maybeSingle();
    const roomId: string | null = data?.room_id ?? null;
    return deepLinkForTransaction(target.id, roomId);
  }
  // pending — link to the pending list / dashboard (no txn id yet).
  const { data } = await sb
    .from("bot_pending_transactions")
    .select("payload")
    .eq("id", target.id)
    .eq("user_id", link.userId)
    .maybeSingle();
  const payload = (data?.payload ?? {}) as Record<string, unknown>;
  const roomId = typeof payload.roomId === "string" ? payload.roomId : null;
  if (roomId) return `${APP_DEEP_LINK_BASE}rooms/${roomId}`;
  return `${APP_DEEP_LINK_BASE}transactions`;
}

// -----------------------------------------------------------------
// Command handlers
// -----------------------------------------------------------------
async function handleStart(
  chatId: string,
  args: string,
  meta: Record<string, unknown>,
): Promise<void> {
  const trimmed = args.trim();
  if (!trimmed) {
    const existing = await resolveChat(PLATFORM, chatId);
    if (existing) {
      const userCtx = await loadUserContext(existing.userId);
      const locale = resolveLocale(userCtx?.language);
      await sendMessage(chatId, t(locale, "botLinkedOk"));
      return;
    }
    await sendMessage(chatId, t("en", "botNotLinked"));
    return;
  }
  const userId = await consumeLinkCode(PLATFORM, trimmed, chatId, meta);
  if (!userId) {
    await sendMessage(chatId, t("en", "botLinkInvalid"));
    return;
  }
  const ctx = await loadUserContext(userId);
  const locale = resolveLocale(ctx?.language);
  await sendMessage(chatId, t(locale, "botLinkedOk"));
  logBotEvent({
    event: "bot_linked",
    platform: PLATFORM,
    messageType: "command",
    userId,
  });
}

async function handleToday(link: MessagingLink, ctx: UserContext, locale: Locale): Promise<void> {
  const sb = serviceClient();
  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);
  // Card label: merchant column (ADR-0025), else first notes line (legacy
  // canonical rows packed merchant there), else category.
  const { data, error } = await sb
    .from("transactions")
    .select("amount, currency, merchant, notes, category, type")
    .eq("user_id", link.userId)
    .gte("created_at", startOfDay.toISOString())
    .order("created_at", { ascending: false });
  if (error) {
    logBotError(error, {
      stage: "today_query",
      platform: PLATFORM,
      userId: link.userId,
    });
    await sendMessage(link.externalChatId, t(locale, "botTodayFailed"));
    return;
  }
  if (!data || data.length === 0) {
    await sendMessage(link.externalChatId, t(locale, "botTodayEmpty"));
    return;
  }
  const lines = [`<b>${t(locale, "botToday")}</b>`, ""];
  for (const r of data) {
    const signedAmt = Number(r.amount);
    const amt = formatMoneyDisplay(signedAmt, r.currency, {
      hide: ctx.hideAmounts,
      locale,
    });
    const sign = signedAmt < 0 ? "-" : "+";
    const merchantTrim =
      typeof r.merchant === "string" ? r.merchant.trim() : "";
    const noteFirstLine = typeof r.notes === "string"
      ? (r.notes.split("\n").find((l: string) => l.trim().length > 0) ?? "")
        .trim()
      : "";
    // Resolve category key → display name. Personal vs room scope isn't
    // stored on this projection — fall back through any scope.
    const catName = categoryDisplayName(ctx, r.category as string, null);
    const label = merchantTrim.length > 0
      ? merchantTrim
      : noteFirstLine.length > 0
      ? noteFirstLine
      : catName;
    lines.push(`• <b>${sign}${htmlEscape(amt)}</b> — ${htmlEscape(label)}`);
  }
  await sendMessage(link.externalChatId, lines.join("\n"), undefined, { html: true });
}

async function handleDisconnect(link: MessagingLink, locale: Locale): Promise<void> {
  // Send the confirmation first — once the link row is gone, future messages
  // hit the "not linked" path.
  await sendMessage(link.externalChatId, t(locale, "botDisconnected"));
  await disconnectChat(PLATFORM, link.externalChatId, link.userId);
  logBotEvent({
    event: "bot_disconnected",
    platform: PLATFORM,
    messageType: "command",
    userId: link.userId,
  });
}

async function handleCancel(link: MessagingLink, locale: Locale): Promise<void> {
  const res = await cancelActiveWork(link, locale);
  const cleared = res.pendingCancelled || res.editCancelled;
  await sendMessage(
    link.externalChatId,
    cleared ? t(locale, "botCancelled") : t(locale, "botNothingToCancel"),
  );
}

async function handleUndo(link: MessagingLink, locale: Locale): Promise<void> {
  const lookup = await latestUndoToken(link);
  if (lookup.kind === "missing") {
    await sendMessage(link.externalChatId, t(locale, "botNothingToUndo"));
    return;
  }
  if (lookup.kind === "expired") {
    await sendMessage(link.externalChatId, t(locale, "botUndoExpired"));
    return;
  }
  const outcome = await performUndo(link, lookup);
  if (outcome.kind === "done") {
    await sendMessage(link.externalChatId, t(locale, "botUndoDone"));
    return;
  }
  if (outcome.kind === "missing") {
    await sendMessage(link.externalChatId, t(locale, "botNothingToUndo"));
    return;
  }
  if (outcome.kind === "expired") {
    await sendMessage(link.externalChatId, t(locale, "botUndoExpired"));
    return;
  }
  await sendMessage(link.externalChatId, t(locale, "botUndoFailed"));
}

// -----------------------------------------------------------------
// Text flow
// -----------------------------------------------------------------
async function handleTextMessage(
  link: MessagingLink,
  ctx: UserContext,
  locale: Locale,
  message: string,
): Promise<void> {
  // Reserve one AI Credit before the parse (ADR-0017 — text is now metered).
  const reserve = await consumeScanQuota(link.userId, ctx.tier);
  if (reserve === null) {
    await sendMessage(link.externalChatId, t(locale, "botQuotaReached"));
    return;
  }
  let parsed: Awaited<ReturnType<typeof parseTransactionText>>;
  try {
    parsed = await parseTransactionText(message, ctx);
  } catch (e) {
    await refundScanQuota(link.userId);
    throw e;
  }
  if (parsed.kind === "rejected" || parsed.kind === "ai_failure") {
    await refundScanQuota(link.userId); // no usable transaction → no charge
    // Surface a specific reply when the message named a room the user
    // doesn't actually have access to — far more actionable than a generic
    // "didn't understand" line. Common cause: Telegram linked to a LOIT
    // account that isn't a member of the room the user is thinking of.
    const intended = extractIntendedRoomName(message);
    if (intended && !findRoomByName(ctx, intended)) {
      if (ctx.rooms.length === 0) {
        await sendMessage(
          link.externalChatId,
          t(locale, "botRoomNotFoundNoRooms", { room: intended }),
        );
      } else {
        const list = ctx.rooms.map((r) => `"${r.name}"`).join(", ");
        await sendMessage(
          link.externalChatId,
          t(locale, "botRoomNotFound", { room: intended, rooms: list }),
        );
      }
      logBotEvent({
        event: "bot_room_not_found",
        platform: PLATFORM,
        messageType: "text",
        userId: link.userId,
        extra: { hasRooms: ctx.rooms.length > 0 },
      });
      return;
    }
    if (parsed.kind === "rejected") {
      await sendMessage(link.externalChatId, t(locale, "botUnknown"));
    } else {
      await sendMessage(link.externalChatId, t(locale, "botParseFailed"));
    }
    return;
  }
  // Usable parse — charge any credits beyond the reserved 1 (output tokens).
  // ponytail: copy of gatedScan's charge tail; share via meterCapture only when
  // a 4th capture surface or rule change forces it (see scan_gate.ts).
  const charged = creditsForTokens(parsed.completionTokens, 1);
  const usedAfter = await chargeExtraCredits(link.userId, charged - 1) ??
    reserve.used;
  const remaining = remainingFromUsed(usedAfter, reserve.cap);
  return handleParsedText(link, ctx, locale, parsed.parsed, { charged, remaining });
}

async function handleParsedText(
  link: MessagingLink,
  ctx: UserContext,
  locale: Locale,
  parsedArg: import("../_shared/text_parser.ts").TextParseSuccess,
  credits?: { charged: number; remaining: number | null },
): Promise<void> {
  const p = parsedArg;
  const roomId = findRoomByName(ctx, p.destination_room)?.id ?? null;

  if (p.rescued) {
    logBotEvent({
      event: "bot_parse_rescued",
      platform: PLATFORM,
      messageType: "text",
      scope: roomId ? "room" : "personal",
      userId: link.userId,
    });
  }

  // Rescue path always goes through confirm flow even if confidence
  // happens to clear the autosave bar — the category was picked by
  // fallback heuristic, not by the model.
  if (!p.rescued && p.confidence >= CONFIDENCE_AUTO_SAVE) {
    await commitAndReply({
      link,
      ctx,
      locale,
      type: p.type,
      total: p.total,
      currency: p.currency,
      merchant: p.merchant,
      category: p.category,
      accountName: p.account,
      notes: p.notes,
      items: p.items ?? null,
      roomId,
      confidence: p.confidence,
      sourceType: "text",
      credits,
    });
    return;
  }
  const summary = richSummary(ctx, locale, {
    type: p.type,
    total: p.total,
    currency: p.currency,
    merchant: p.merchant,
    category: p.category,
    accountName: p.account,
    roomName: roomId ? ctx.rooms.find((r) => r.id === roomId)?.name ?? null : null,
    date: todayYmd(),
  });
  // Pending payload omits the parsed date — saves use the server `now()`
  // when the user confirms, so persisting the parser date here is moot.
  const { date: _droppedDate, ...withoutDate } = p as { date?: string | null } & typeof p;
  await createPending(
    link,
    locale,
    { ...withoutDate, roomId },
    p.confidence,
    summary,
    "text",
  );
}

// -----------------------------------------------------------------
// Voice flow
// -----------------------------------------------------------------
async function handleVoice(
  link: MessagingLink,
  ctx: UserContext,
  locale: Locale,
  voice: { file_id: string; duration: number; mime_type?: string },
): Promise<void> {
  if (voice.duration > 60) {
    await sendMessage(link.externalChatId, t(locale, "botVoiceTooLong"));
    return;
  }
  const reserve = await consumeScanQuota(link.userId, ctx.tier);
  if (reserve === null) {
    await sendMessage(link.externalChatId, t(locale, "botQuotaReached"));
    return;
  }

  let refunded = false;
  const refundOnce = async () => {
    if (refunded) return;
    refunded = true;
    await refundScanQuota(link.userId);
  };

  try {
    const filePath = await getFilePath(voice.file_id);
    if (!filePath) {
      await refundOnce();
      await sendMessage(link.externalChatId, t(locale, "botParseFailed"));
      return;
    }
    const audio = await downloadFile(filePath);
    if (!audio) {
      await refundOnce();
      await sendMessage(link.externalChatId, t(locale, "botParseFailed"));
      return;
    }

    // Two-step: Whisper (via OpenRouter STT) transcribes the voice note to
    // text, then the text parser handles the transcript (voice keeps
    // deterministic rescues). See docs/adr/0016-all-ai-through-openrouter.md.
    const b64 = bytesToBase64(audio);
    const parsed = await parseTransactionFromAudio(
      b64,
      voice.mime_type ?? "audio/ogg",
      ctx,
    );
    if (parsed.kind !== "ok") {
      await refundOnce();
      await sendMessage(link.externalChatId, t(locale, "botParseFailed"));
      return;
    }
    const p = parsed.parsed;
    const roomId = findRoomByName(ctx, p.destination_room)?.id ?? null;

    // Tokens burned regardless of confidence — charge any beyond the reserved 1.
    // ponytail: copy of gatedScan's charge tail; share via meterCapture only when
    // a 4th capture surface or rule change forces it (see scan_gate.ts).
    const charged = creditsForTokens(parsed.completionTokens, 1);
    const usedAfter = await chargeExtraCredits(link.userId, charged - 1) ??
      reserve.used;
    const remaining = remainingFromUsed(usedAfter, reserve.cap);

    if (p.rescued) {
      logBotEvent({
        event: "bot_parse_rescued",
        platform: PLATFORM,
        messageType: "voice",
        scope: roomId ? "room" : "personal",
        userId: link.userId,
      });
    }

    if (!p.rescued && p.confidence >= CONFIDENCE_AUTO_SAVE) {
      const result = await commitAndReply({
        link,
        ctx,
        locale,
        type: p.type,
        total: p.total,
        currency: p.currency,
        merchant: p.merchant,
        category: p.category,
        accountName: p.account,
        notes: p.notes,
        items: p.items ?? null,
        roomId,
        confidence: p.confidence,
        sourceType: "voice",
        credits: { charged, remaining },
      });
      if (!result.ok) {
        // No usable transaction was created — refund the scan.
        await refundOnce();
      }
      return;
    }
    // Low confidence — parse succeeded but needs confirmation. Quota stays
    // consumed (a pending row is usable). User confirmation does NOT cost a
    // second scan.
    const summary = richSummary(ctx, locale, {
      type: p.type,
      total: p.total,
      currency: p.currency,
      merchant: p.merchant,
      category: p.category,
      accountName: p.account,
      roomName: roomId ? ctx.rooms.find((r) => r.id === roomId)?.name ?? null : null,
      date: todayYmd(),
    });
    const { date: _droppedDate, ...withoutDate } = p as { date?: string | null } & typeof p;
    await createPending(
      link,
      locale,
      { ...withoutDate, roomId },
      p.confidence,
      summary,
      "voice",
    );
  } catch (e) {
    await refundOnce();
    logBotError(e, { stage: "voice_flow", platform: PLATFORM, userId: link.userId });
    await sendMessage(link.externalChatId, t(locale, "botParseFailed"));
  }
}

// -----------------------------------------------------------------
// Image flow
// -----------------------------------------------------------------
// Extract caption metadata for image submissions: explicit date hint + room
// hint. Receipt OCR remains authoritative for amount/category/account; the
// caption is the only source for the transaction date. Returns nulls when the
// caption doesn't mention either field.
async function detectCaptionMetadata(
  caption: string | null,
  ctx: UserContext,
): Promise<{
  roomId: string | null;
  captionDate: string | null;
  captionNote: string | null;
}> {
  if (!caption || caption.trim().length === 0) {
    return { roomId: null, captionDate: null, captionNote: null };
  }
  try {
    const meta = await parseCaptionMetadata(caption, ctx);
    const roomId = findRoomByName(ctx, meta.destination_room)?.id ?? null;
    return { roomId, captionDate: meta.date, captionNote: meta.note };
  } catch {
    return { roomId: null, captionDate: null, captionNote: null };
  }
}

async function handlePhoto(
  link: MessagingLink,
  ctx: UserContext,
  locale: Locale,
  photoSizes: Array<{ file_id: string; width: number; height: number }>,
  caption: string | null,
): Promise<void> {
  try {
    // Largest variant under ~8MB heuristic — Telegram already keeps photos
    // capped, so pick the largest.
    const largest = [...photoSizes].sort((a, b) => b.width * b.height - a.width * a.height)[0];
    const filePath = await getFilePath(largest.file_id);
    if (!filePath) {
      await sendMessage(link.externalChatId, t(locale, "botParseFailed"));
      return;
    }
    const raw = await downloadFile(filePath);
    if (!raw) {
      await sendMessage(link.externalChatId, t(locale, "botParseFailed"));
      return;
    }
    // Server-side preprocessing — matches the in-app scanner pipeline:
    // resize long edge ≤ 1600, JPEG q85. Keeps payload size sane and gives
    // Claude a consistent input regardless of what Telegram delivered.
    let processed: Uint8Array;
    try {
      processed = await preprocessReceiptImage(raw);
    } catch (e) {
      logBotError(e, { stage: "image_preprocess", platform: PLATFORM, userId: link.userId });
      processed = raw;
    }
    const b64 = bytesToBase64(processed);

    // Extract caption metadata. Receipts default to personal unless the user
    // names a room in the caption. The image transaction date comes from the
    // caption only — OCR `date` is ignored for Telegram image transactions.
    const { roomId: captionRoomId, captionNote } = await detectCaptionMetadata(
      caption,
      ctx,
    );

    // Single gated pipeline shared with the in-app scanner: consume quota →
    // parse (with internal strict-retry) → refund only on AI failure. Quota
    // is charged here regardless of whether the user later confirms.
    const scan = await gatedScan({
      userId: link.userId,
      tier: ctx.tier,
      imageBase64: b64,
      categories: categoriesForScope(ctx, captionRoomId).map((c) => ({
        key: c.key,
        name: c.name,
        kind: c.kind,
      })),
      accounts: ctx.accounts.map((a) => ({ name: a.name })),
    });
    if (scan.kind === "quota_reached") {
      await sendMessage(link.externalChatId, t(locale, "botQuotaReached"));
      return;
    }
    // not_a_transaction / ai_failure — gatedScan already refunded the scan.
    if (scan.kind !== "ok" && scan.kind !== "partial") {
      await sendMessage(link.externalChatId, t(locale, "botParseFailed"));
      return;
    }
    const p: any = scan.kind === "ok" ? scan.parsed : scan.partial;
    const type: "expense" | "income" = p.type === "income" ? "income" : "expense";
    const currency = typeof p.currency === "string" && p.currency.length === 3
      ? p.currency.toUpperCase()
      : ctx.homeCurrency;
    const confidence = typeof p.confidence === "number" ? p.confidence : 0.5;
    // Image transactions persist `created_at` from the database default
    // (`now()`); caption/OCR dates are display-only and never persisted.
    // Structured storage (ADR-0025): merchant/items land in their own
    // columns; notes is the caption remark (minus room/date markers).
    const scanItems = Array.isArray(p.items) ? p.items : null;

    const storeReceipt = canStoreReceipt(ctx.tier);

    // High-confidence + cleanly parsed → auto-save now and store the receipt
    // image (txn id + bytes both in hand). `partial` never auto-saves.
    if (scan.kind === "ok" && confidence >= CONFIDENCE_AUTO_SAVE) {
      const outcome = await commitAndReply({
        link,
        ctx,
        locale,
        type,
        total: Number(p.total),
        currency,
        merchant: p.merchant ?? null,
        category: p.category,
        accountName: p.account,
        notes: captionNote,
        items: scanItems,
        roomId: captionRoomId,
        confidence,
        sourceType: "image",
        credits: { charged: scan.creditsCharged, remaining: scan.creditsRemaining },
      });
      // Save failures are not refunded — the AI call already happened.
      if (outcome.ok && storeReceipt) {
        await storeReceiptForTxn(link.userId, outcome.transactionId, processed);
      }
      return;
    }
    // Low confidence / partial — hold for confirmation. The scan stays
    // consumed; confirming does not cost a second scan. For non-free tiers the
    // photo is stashed now and promoted to the transaction on confirm.
    const summary = richSummary(ctx, locale, {
      type,
      total: Number(p.total),
      currency,
      merchant: p.merchant,
      category: p.category,
      accountName: p.account,
      roomName: captionRoomId
        ? ctx.rooms.find((r) => r.id === captionRoomId)?.name ?? null
        : null,
      date: todayYmd(),
    });
    await createPending(
      link,
      locale,
      {
        type,
        total: Number(p.total),
        currency,
        merchant: p.merchant,
        category: p.category,
        account: p.account,
        roomId: captionRoomId,
        notes: captionNote,
        items: scanItems,
      },
      confidence,
      summary,
      "image",
      storeReceipt ? processed : undefined,
    );
  } catch (e) {
    logBotError(e, { stage: "image_flow", platform: PLATFORM, userId: link.userId });
    await sendMessage(link.externalChatId, t(locale, "botParseFailed"));
  }
}

// -----------------------------------------------------------------
// Callback queries (inline buttons)
// -----------------------------------------------------------------
async function handleCallback(
  callbackId: string,
  link: MessagingLink,
  ctx: UserContext,
  locale: Locale,
  data: string,
  messageId: number,
): Promise<void> {
  const parts = data.split(":");
  const action = parts[0];
  const arg = parts[1] ?? "";
  const arg2 = parts[2] ?? "";
  const arg3 = parts[3] ?? "";
  const arg4 = parts.slice(4).join(":");
  switch (action) {
    case "undo": {
      if (!arg || arg === "pending") {
        // Legacy callback — back when commitAndReply rendered a placeholder
        // before minting the token. Look up the actual token by Telegram
        // message id (set on token after sendMessage returns); fall back to
        // the latest unexpired token for this chat.
        const byMsg = await loadUndoTokenByMessageId(link, messageId);
        const lookup =
          byMsg.kind === "ok" ? byMsg : await latestUndoToken(link);
        if (lookup.kind !== "ok") {
          const text =
            lookup.kind === "expired"
              ? t(locale, "botUndoExpired")
              : t(locale, "botNothingToUndo");
          await editMessage(link.externalChatId, messageId, text);
          await answerCallback(callbackId);
          return;
        }
        const outcome = await performUndo(link, lookup);
        if (outcome.kind === "done") {
          await editMessage(link.externalChatId, messageId, t(locale, "botUndoDone"));
          await answerCallback(callbackId, t(locale, "botUndoDone"));
          return;
        }
        if (outcome.kind === "expired") {
          await editMessage(link.externalChatId, messageId, t(locale, "botUndoExpired"));
        } else if (outcome.kind === "missing") {
          await editMessage(link.externalChatId, messageId, t(locale, "botNothingToUndo"));
        } else {
          await sendMessage(link.externalChatId, t(locale, "botUndoFailed"));
        }
        await answerCallback(callbackId);
        return;
      }
      const lookup = await loadUndoToken(arg, link);
      if (lookup.kind !== "ok") {
        const text =
          lookup.kind === "expired"
            ? t(locale, "botUndoExpired")
            : t(locale, "botNothingToUndo");
        await editMessage(link.externalChatId, messageId, text);
        await answerCallback(callbackId);
        return;
      }
      const outcome = await performUndo(link, lookup);
      if (outcome.kind === "done") {
        await editMessage(link.externalChatId, messageId, t(locale, "botUndoDone"));
        await answerCallback(callbackId, t(locale, "botUndoDone"));
        return;
      }
      if (outcome.kind === "expired") {
        await editMessage(link.externalChatId, messageId, t(locale, "botUndoExpired"));
        await answerCallback(callbackId);
        return;
      }
      if (outcome.kind === "missing") {
        await editMessage(link.externalChatId, messageId, t(locale, "botNothingToUndo"));
        await answerCallback(callbackId);
        return;
      }
      await sendMessage(link.externalChatId, t(locale, "botUndoFailed"));
      await answerCallback(callbackId);
      return;
    }
    case "pconfirm": {
      const sb = serviceClient();
      const { data: row } = await sb
        .from("bot_pending_transactions")
        .select("payload, confidence")
        .eq("id", arg)
        .eq("user_id", link.userId)
        .maybeSingle();
      if (!row) {
        await answerCallback(callbackId);
        return;
      }
      const p: any = row.payload ?? {};
      const sourceType: "text" | "voice" | "image" =
        p.sourceType === "voice" || p.sourceType === "image" ? p.sourceType : "text";
      const stash = typeof p.receiptStash === "string" ? p.receiptStash : null;
      await sb.from("bot_pending_transactions").delete().eq("id", arg);
      // pconfirm never consumes quota — the initial parse already paid for
      // any voice/image scan.
      const outcome = await commitAndReply({
        link,
        ctx,
        locale,
        type: p.type,
        total: Number(p.total),
        currency: p.currency,
        merchant: p.merchant ?? null,
        category: p.category,
        accountName: p.account,
        notes: p.notes ?? null,
        items: Array.isArray(p.items) ? p.items : null,
        roomId: p.roomId ?? null,
        confidence:
          typeof row.confidence === "number" ? row.confidence : null,
        sourceType,
      });
      // Promote the stashed photo onto the saved transaction, or drop it if the
      // save fell through (e.g. the user gets routed to a category picker).
      if (stash) {
        if (outcome.ok) {
          await promotePendingReceipt(link.userId, stash, outcome.transactionId);
        } else {
          await deleteStashedReceipt(stash);
        }
      }
      await answerCallback(callbackId);
      return;
    }
    case "pcancel": {
      await cancelActiveWork(link, locale, { pendingId: arg });
      // The shared helper edits the pending prompt; also reflect on the
      // message the callback came from in case it diverges.
      await editMessage(link.externalChatId, messageId, t(locale, "botCancelled"));
      await answerCallback(callbackId);
      return;
    }
    case "edit": {
      // `edit:<type>:<id>` — t=saved transaction, p=pending.
      const target = parseEditTarget(arg, arg2);
      if (!target) {
        await answerCallback(callbackId);
        return;
      }
      // Saved-txn edits require a still-valid undo-token tying this chat to
      // the transaction. `/end` (and app disconnect) wipes those rows so old
      // Edit buttons stop mutating data after reconnect.
      if (target.type === "t" && !(await hasSavedTxnAuth(link, target.id))) {
        await answerCallback(callbackId);
        return;
      }
      // Edit window gate — 24h personal, 1h room. Pending rows use their own
      // 24h TTL via the same helper.
      const win = await checkEditWindow(link, target);
      if (win.kind === "not_found") {
        await answerCallback(callbackId);
        return;
      }
      if (win.kind === "expired") {
        const url = await deepLinkForTarget(link, target);
        await sendMessage(
          link.externalChatId,
          `${t(locale, "botEditWindowExpired")} ${url}`,
        );
        await answerCallback(callbackId);
        return;
      }
      const editDetail = await buildTargetSummary(ctx, locale, link, target);
      const pickerHeader = editDetail
        ? `${t(locale, "botEditDetail", { summary: editDetail })}\n\n${t(locale, "botEditPicker")}`
        : t(locale, "botEditPicker");
      await sendMessage(
        link.externalChatId,
        pickerHeader,
        [
        [
          {
            text: t(locale, "btnEditAmount"),
            callback_data: `editfield:${target.type}:${target.id}:amount`,
          },
          {
            text: t(locale, "btnEditCategory"),
            callback_data: `editfield:${target.type}:${target.id}:category`,
          },
        ],
        [
          {
            text: t(locale, "btnEditAccount"),
            callback_data: `editfield:${target.type}:${target.id}:account`,
          },
          {
            text: t(locale, "btnEditDestination"),
            callback_data: `editfield:${target.type}:${target.id}:dest`,
          },
        ],
        [
          {
            text: t(locale, "btnEditNotes"),
            callback_data: `editfield:${target.type}:${target.id}:notes`,
          },
        ],
        [
          {
            text: t(locale, "btnEditInApp"),
            callback_data: `editapp:${target.type}:${target.id}`,
          },
          { text: t(locale, "btnCancel"), callback_data: `editcancel:0` },
        ],
        ],
        { html: true },
      );
      await answerCallback(callbackId);
      return;
    }
    case "editfield": {
      // editfield:<type>:<id>:<field>
      const target = parseEditTarget(arg, arg2);
      const field = arg3;
      if (!target || !field) {
        await answerCallback(callbackId);
        return;
      }
      if (target.type === "t" && !(await hasSavedTxnAuth(link, target.id))) {
        await answerCallback(callbackId);
        return;
      }
      const win = await checkEditWindow(link, target);
      if (win.kind === "not_found") {
        await answerCallback(callbackId);
        return;
      }
      if (win.kind === "expired") {
        const url = await deepLinkForTarget(link, target);
        await sendMessage(
          link.externalChatId,
          `${t(locale, "botEditWindowExpired")} ${url}`,
        );
        await answerCallback(callbackId);
        return;
      }
      // Keyboard fields: open a session so the pick callback can resolve.
      const fieldDetail = await buildTargetSummary(ctx, locale, link, target);
      const decoratePrompt = (raw: string) =>
        fieldDetail
          ? `${t(locale, "botEditDetail", { summary: fieldDetail })}\n\n${raw}`
          : raw;
      if (field === "category" || field === "account" || field === "dest") {
        const sessionId = await openEditSession(link, target, field);
        if (!sessionId) {
          await answerCallback(callbackId);
          await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
          return;
        }
        const promptKey =
          field === "category"
            ? "botEditAwaitCategory"
            : field === "account"
              ? "botEditAwaitAccount"
              : "botEditAwaitDestination";
        let keyboard: InlineKeyboard;
        if (field === "category") {
          const meta = await resolveTargetMeta(link, target);
          if (!meta) {
            await answerCallback(callbackId);
            await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
            return;
          }
          keyboard = categoryKeyboard(ctx, meta.roomId, meta.kind);
        } else if (field === "account") {
          keyboard = accountKeyboard(ctx);
        } else {
          keyboard = destinationKeyboard(ctx, locale);
        }
        await sendMessage(
          link.externalChatId,
          decoratePrompt(t(locale, promptKey)),
          keyboard,
          { html: true },
        );
        await answerCallback(callbackId);
        return;
      }
      // Free-text fields: amount, date, notes.
      const ftField: FreeTextField | null =
        field === "amount" || field === "date" || field === "notes" ? field : null;
      if (!ftField) {
        await answerCallback(callbackId);
        return;
      }
      const sessionId = await openEditSession(link, target, ftField);
      if (!sessionId) {
        await answerCallback(callbackId);
        await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
        return;
      }
      const promptKey =
        ftField === "amount"
          ? "botEditAwaitAmount"
          : ftField === "date"
            ? "botEditAwaitDate"
            : "botEditAwaitNotes";
      await sendMessage(
        link.externalChatId,
        decoratePrompt(t(locale, promptKey)),
        undefined,
        { html: true },
      );
      await answerCallback(callbackId);
      return;
    }
    case "pick": {
      // pick:<idx> — applies to the active edit session's keyboard field.
      const idx = Number(arg);
      if (!Number.isFinite(idx) || idx < 0) {
        await answerCallback(callbackId);
        return;
      }
      const session = await loadActiveEditSession(link);
      if (!session) {
        await answerCallback(callbackId);
        return;
      }
      const field = session.awaitingField;
      if (field !== "category" && field !== "account" && field !== "dest") {
        await answerCallback(callbackId);
        return;
      }
      if (
        session.target.type === "t" &&
        !(await hasSavedTxnAuth(link, session.target.id))
      ) {
        await closeEditSession(session.id);
        await answerCallback(callbackId);
        return;
      }
      const win = await checkEditWindow(link, session.target);
      if (win.kind === "not_found") {
        await closeEditSession(session.id);
        await answerCallback(callbackId);
        return;
      }
      if (win.kind === "expired") {
        await closeEditSession(session.id);
        const url = await deepLinkForTarget(link, session.target);
        await sendMessage(
          link.externalChatId,
          `${t(locale, "botEditWindowExpired")} ${url}`,
        );
        await answerCallback(callbackId);
        return;
      }
      const scope =
        field === "category" ? await resolveTargetMeta(link, session.target) : null;
      const resolved = resolvePickValue(ctx, field as KeyboardField, idx, scope);
      if (!resolved) {
        await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
        await closeEditSession(session.id);
        await answerCallback(callbackId);
        return;
      }
      const ok = await applyKeyboardEdit(link, ctx, session.target, resolved);
      await closeEditSession(session.id);
      if (!ok) {
        await sendMessage(link.externalChatId, t(locale, "botEditFailed"));
        await answerCallback(callbackId);
        return;
      }
      const newSummary = await buildTargetSummary(ctx, locale, link, session.target);
      await sendMessage(
        link.externalChatId,
        newSummary
          ? t(locale, "botEditAppliedSummary", { summary: newSummary })
          : t(locale, "botEditApplied"),
        undefined,
        { html: true },
      );
      await refreshOriginalMessage(ctx, link, locale, session.target);
      logBotEvent({
        event: "bot_transaction_edited",
        platform: PLATFORM,
        messageType: "callback",
        userId: link.userId,
        extra: { field, target: session.target.type },
      });
      await answerCallback(callbackId);
      return;
    }
    case "editapp": {
      // editapp:<type>:<id>
      const target = parseEditTarget(arg, arg2);
      if (!target) {
        await answerCallback(callbackId);
        return;
      }
      if (target.type === "t" && !(await hasSavedTxnAuth(link, target.id))) {
        await answerCallback(callbackId);
        return;
      }
      const url = await deepLinkForTarget(link, target);
      await sendMessage(link.externalChatId, `${t(locale, "btnEditInApp")}: ${url}`);
      await answerCallback(callbackId);
      return;
    }
    case "editcancel": {
      const sb = serviceClient();
      await sb
        .from("bot_edit_sessions")
        .delete()
        .eq("platform", PLATFORM)
        .eq("external_chat_id", link.externalChatId)
        .eq("user_id", link.userId);
      await sendMessage(link.externalChatId, t(locale, "botEditCancelled"));
      await answerCallback(callbackId);
      return;
    }
    case "dest": {
      // @deprecated 2026-05-21 — destination picker is no longer offered for
      // new transactions; auto-detection drives it. Kept to drain in-flight
      // `awaiting_destination` rows. Safe to delete with offerDestinationPicker
      // after the deprecation window.
      // Destination picker resolution. `arg` = pending id, `arg2` = room id
      // or "personal".
      if (!arg) {
        await answerCallback(callbackId);
        return;
      }
      const sb = serviceClient();
      const { data: row } = await sb
        .from("bot_pending_transactions")
        .select("payload, confidence")
        .eq("id", arg)
        .eq("user_id", link.userId)
        .maybeSingle();
      if (!row) {
        await answerCallback(callbackId);
        return;
      }
      const p: any = row.payload ?? {};
      const sourceType: "text" | "voice" | "image" =
        p.sourceType === "voice" || p.sourceType === "image" ? p.sourceType : "text";
      let roomId: string | null = null;
      if (arg2 && arg2 !== "p") {
        const roomIdx = Number(arg2);
        if (
          Number.isFinite(roomIdx) &&
          roomIdx >= 0 &&
          roomIdx < ctx.rooms.length
        ) {
          roomId = ctx.rooms[roomIdx].id;
        }
      }
      const confidence =
        typeof row.confidence === "number" ? row.confidence : null;
      // If parse confidence is still low after destination is selected,
      // transition into the standard pending-confirm path instead of saving.
      if (confidence !== null && confidence < CONFIDENCE_AUTO_SAVE) {
        const payload = { ...p, roomId };
        await sb
          .from("bot_pending_transactions")
          .update({ payload, state: "awaiting_user" })
          .eq("id", arg);
        // Re-scope the parsed category to the chosen destination so the
        // confirm step shows a category that will actually save.
        const kindForRemap: "expense" | "income" =
          p.type === "income" ? "income" : "expense";
        const curCat = typeof p.category === "string" ? p.category : "";
        if (curCat && !findCategoryInScope(ctx, curCat, kindForRemap, roomId)) {
          const remapped = remapCategoryAcrossScopes(ctx, curCat, kindForRemap, roomId);
          if (remapped) {
            payload.category = remapped;
            p.category = remapped;
            await sb
              .from("bot_pending_transactions")
              .update({ payload })
              .eq("id", arg);
          }
        }
        const summary = richSummary(ctx, locale, {
          type: p.type,
          total: Number(p.total),
          currency: p.currency,
          merchant: p.merchant ?? null,
          category: p.category,
          accountName: p.account,
          roomId,
          roomName: roomId
            ? ctx.rooms.find((r) => r.id === roomId)?.name ?? null
            : null,
          notes: typeof p.notes === "string" ? p.notes : null,
          date: todayYmd(),
        });
        const msg = await sendMessage(
          link.externalChatId,
          t(locale, "botPendingConfirm", { summary }),
          [
            [
              { text: t(locale, "btnConfirm"), callback_data: `pconfirm:${arg}` },
              { text: t(locale, "btnCancel"), callback_data: `pcancel:${arg}` },
            ],
            [{ text: t(locale, "btnEdit"), callback_data: `edit:p:${arg}` }],
          ],
          { html: true },
        );
        if (msg) {
          await sb
            .from("bot_pending_transactions")
            .update({ bot_message_id: String(msg.message_id) })
            .eq("id", arg);
        }
        await answerCallback(callbackId);
        return;
      }
      // High confidence — commit directly using the chosen destination.
      await sb.from("bot_pending_transactions").delete().eq("id", arg);
      await commitAndReply({
        link,
        ctx,
        locale,
        type: p.type,
        total: Number(p.total),
        currency: p.currency,
        merchant: p.merchant ?? null,
        category: p.category,
        accountName: p.account,
        notes: p.notes ?? null,
        roomId,
        confidence,
        sourceType,
      });
      await answerCallback(callbackId);
      return;
    }
    default:
      await answerCallback(callbackId);
      return;
  }
}

// -----------------------------------------------------------------
// Webhook entry
// -----------------------------------------------------------------
serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("ok", { status: 200 });
  }
  // Webhook secret guard.
  const got = req.headers.get("x-telegram-bot-api-secret-token");
  if (!WEBHOOK_SECRET || got !== WEBHOOK_SECRET) {
    return new Response("forbidden", { status: 403 });
  }
  let update: any;
  try {
    update = await req.json();
  } catch {
    return new Response("bad", { status: 400 });
  }

  try {
    if (update.callback_query) {
      const cb = update.callback_query;
      const chatId = String(cb.message?.chat?.id ?? cb.from.id);
      const link = await resolveChat(PLATFORM, chatId);
      if (!link) {
        // Stale inline button from a previous link — let the user know
        // instead of silently accepting taps that no longer do anything.
        await answerCallback(cb.id, t("en", "botCallbackNotLinked"));
        await sendMessage(chatId, t("en", "botCallbackNotLinked"));
        return new Response("ok");
      }
      const ctx = await loadUserContext(link.userId);
      if (!ctx) {
        await answerCallback(cb.id);
        return new Response("ok");
      }
      const locale = resolveLocale(ctx.language);
      await handleCallback(cb.id, link, ctx, locale, cb.data ?? "", cb.message.message_id);
      return new Response("ok");
    }

    const msg = update.message ?? update.edited_message;
    if (!msg) return new Response("ok");

    const chatId = String(msg.chat.id);
    const text: string | undefined = msg.text;

    // /start handles linking BEFORE rate limiting — a user who pastes an
    // expired code shouldn't get silenced.
    if (text && text.startsWith("/start")) {
      const arg = text.slice(6).trim();
      await handleStart(chatId, arg, {
        username: msg.from?.username,
        first_name: msg.from?.first_name,
      });
      return new Response("ok");
    }

    const link = await resolveChat(PLATFORM, chatId);
    if (!link) {
      await sendMessage(chatId, t("en", "botNotLinked"));
      return new Response("ok");
    }

    // Route low-cost control commands BEFORE the rate limit so a user who's
    // been flooded out can still cancel pending work, undo, disconnect, or
    // read help/today. Only transaction-producing flows hit the limiter.
    if (text && text.startsWith("/")) {
      const cmd = text.split(/\s+/)[0].toLowerCase();
      if (
        cmd === "/help" ||
        cmd === "/today" ||
        cmd === "/end" ||
        cmd === "/unlink" ||
        cmd === "/cancel" ||
        cmd === "/undo"
      ) {
        const ctx = await loadUserContext(link.userId);
        const locale = resolveLocale(ctx?.language);
        switch (cmd) {
          case "/help":
            await sendMessage(chatId, t(locale, "botHelp"));
            return new Response("ok");
          case "/today":
            if (!ctx) return new Response("ok");
            await handleToday(link, ctx, locale);
            return new Response("ok");
          case "/end":
          case "/unlink":
            await handleDisconnect(link, locale);
            return new Response("ok");
          case "/cancel":
            await handleCancel(link, locale);
            return new Response("ok");
          case "/undo":
            await handleUndo(link, locale);
            return new Response("ok");
        }
      }
    }

    // Rate limit after we know who the user is — limits apply per chat.
    const rl = await checkRateLimit(PLATFORM, chatId, link.userId);
    if (!rl.allowed) {
      if (rl.shouldWarn) {
        const ctx = await loadUserContext(link.userId);
        const locale = resolveLocale(ctx?.language);
        await sendMessage(chatId, t(locale, "botRateLimited"));
      }
      return new Response("ok");
    }

    const ctx = await loadUserContext(link.userId);
    if (!ctx) return new Response("ok");
    const locale = resolveLocale(ctx.language);

    if (text && text.startsWith("/")) {
      // Unknown slash command — fall through to help.
      await sendMessage(chatId, t(locale, "botHelp"));
      return new Response("ok");
    }

    if (msg.voice) {
      await handleVoice(link, ctx, locale, msg.voice);
      return new Response("ok");
    }
    if (msg.photo && Array.isArray(msg.photo) && msg.photo.length > 0) {
      const caption = typeof msg.caption === "string" ? msg.caption : null;
      await handlePhoto(link, ctx, locale, msg.photo, caption);
      return new Response("ok");
    }
    if (text && text.trim().length > 0) {
      // If an edit session is open, route the next text into the apply path
      // instead of running it through the transaction parser.
      const editSession = await loadActiveEditSession(link);
      if (editSession) {
        await applyEditFromText(link, ctx, locale, editSession, text);
        return new Response("ok");
      }
      await handleTextMessage(link, ctx, locale, text.trim());
      return new Response("ok");
    }

    await sendMessage(chatId, t(locale, "botUnknown"));
    return new Response("ok");
  } catch (e) {
    logBotError(e, { stage: "webhook", platform: PLATFORM });
    return new Response("ok"); // ack always — TG retries on 5xx.
  }
});
