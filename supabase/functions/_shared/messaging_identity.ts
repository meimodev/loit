import { serviceClient } from "./supabase.ts";

export type Platform = "telegram" | "whatsapp";

export interface MessagingLink {
  userId: string;
  platform: Platform;
  externalChatId: string;
  metadata: Record<string, unknown>;
}

// Look up the LOIT user for an external chat. Returns null if not linked.
export async function resolveChat(
  platform: Platform,
  externalChatId: string,
): Promise<MessagingLink | null> {
  const sb = serviceClient();
  const { data, error } = await sb
    .from("user_messaging_links")
    .select("user_id, platform, external_chat_id, metadata")
    .eq("platform", platform)
    .eq("external_chat_id", externalChatId)
    .maybeSingle();
  if (error || !data) return null;
  // Touch last_used_at — fire-and-forget.
  sb.from("user_messaging_links")
    .update({ last_used_at: new Date().toISOString() })
    .eq("platform", platform)
    .eq("external_chat_id", externalChatId)
    .then(() => {});
  return {
    userId: data.user_id,
    platform: data.platform,
    externalChatId: data.external_chat_id,
    metadata: data.metadata ?? {},
  };
}

// Consume a one-time link code issued by `generate_telegram_link_code`.
// Returns the user_id if the code matches, else null.
export async function consumeLinkCode(
  platform: Platform,
  rawCode: string,
  externalChatId: string,
  metadata: Record<string, unknown>,
): Promise<string | null> {
  const sb = serviceClient();
  // sha256(rawCode) — Web Crypto.
  const buf = new TextEncoder().encode(rawCode);
  const hash = await crypto.subtle.digest("SHA-256", buf);
  const hex = Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  const nowIso = new Date().toISOString();

  const { data: code } = await sb
    .from("messaging_link_codes")
    .select("id, user_id, expires_at, consumed_at")
    .eq("platform", platform)
    .eq("code_hash", hex)
    .maybeSingle();
  if (!code) return null;
  if (code.consumed_at) return null;
  if (new Date(code.expires_at).getTime() < Date.now()) return null;

  const userId = code.user_id;

  // Upsert the link, then mark code consumed.
  const { error: linkErr } = await sb
    .from("user_messaging_links")
    .upsert(
      {
        user_id: userId,
        platform,
        external_chat_id: externalChatId,
        metadata,
        linked_at: nowIso,
        last_used_at: nowIso,
        disclosure_accepted_at: nowIso,
      },
      { onConflict: "platform,external_chat_id" },
    );
  if (linkErr) return null;

  await sb
    .from("messaging_link_codes")
    .update({ consumed_at: nowIso })
    .eq("id", code.id);

  return userId;
}

// Tear down a chat link plus all bot-side state scoped to that chat/user.
// Used by `/end` and `/unlink` — must match app-side `disconnect_messaging_link`
// so disconnect semantics are identical on both surfaces.
export async function disconnectChat(
  platform: Platform,
  externalChatId: string,
  userId: string,
): Promise<void> {
  const sb = serviceClient();
  await sb
    .from("bot_pending_transactions")
    .delete()
    .eq("platform", platform)
    .eq("external_chat_id", externalChatId)
    .eq("user_id", userId);
  await sb
    .from("bot_edit_sessions")
    .delete()
    .eq("platform", platform)
    .eq("external_chat_id", externalChatId)
    .eq("user_id", userId);
  await sb
    .from("bot_transaction_undo_tokens")
    .delete()
    .eq("platform", platform)
    .eq("external_chat_id", externalChatId)
    .eq("user_id", userId);
  await sb
    .from("messaging_link_codes")
    .update({ consumed_at: new Date().toISOString() })
    .eq("platform", platform)
    .eq("user_id", userId)
    .is("consumed_at", null);
  await sb
    .from("user_messaging_links")
    .delete()
    .eq("platform", platform)
    .eq("external_chat_id", externalChatId);
}

export async function unlinkChat(
  platform: Platform,
  externalChatId: string,
  userId: string,
): Promise<void> {
  await disconnectChat(platform, externalChatId, userId);
}
