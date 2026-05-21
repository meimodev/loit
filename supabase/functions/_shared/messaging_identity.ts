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
//
// Delegates to the `consume_messaging_link_code` Postgres RPC so code
// validation, previous-owner cleanup, link replacement, and code
// consumption commit (or roll back) as a single transaction. The old
// multi-statement path could leave a chat orphaned if the new link
// upsert failed after the previous owner had already been torn down.
export async function consumeLinkCode(
  platform: Platform,
  rawCode: string,
  externalChatId: string,
  metadata: Record<string, unknown>,
): Promise<string | null> {
  const sb = serviceClient();
  const { data, error } = await sb.rpc("consume_messaging_link_code", {
    p_platform: platform,
    p_raw_code: rawCode,
    p_external_chat_id: externalChatId,
    p_metadata: metadata ?? {},
  });
  if (error) {
    console.error("consume_messaging_link_code failed", error);
    return null;
  }
  if (!data) return null;
  return data as string;
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

  const { error: pendingErr } = await sb
    .from("bot_pending_transactions")
    .delete()
    .eq("platform", platform)
    .eq("external_chat_id", externalChatId)
    .eq("user_id", userId);
  if (pendingErr) {
    throw new Error(
      `disconnectChat: bot_pending_transactions cleanup failed: ${pendingErr.message}`,
    );
  }

  const { error: editErr } = await sb
    .from("bot_edit_sessions")
    .delete()
    .eq("platform", platform)
    .eq("external_chat_id", externalChatId)
    .eq("user_id", userId);
  if (editErr) {
    throw new Error(
      `disconnectChat: bot_edit_sessions cleanup failed: ${editErr.message}`,
    );
  }

  const { error: undoErr } = await sb
    .from("bot_transaction_undo_tokens")
    .delete()
    .eq("platform", platform)
    .eq("external_chat_id", externalChatId)
    .eq("user_id", userId);
  if (undoErr) {
    throw new Error(
      `disconnectChat: bot_transaction_undo_tokens cleanup failed: ${undoErr.message}`,
    );
  }

  const { error: codeErr } = await sb
    .from("messaging_link_codes")
    .update({ consumed_at: new Date().toISOString() })
    .eq("platform", platform)
    .eq("user_id", userId)
    .is("consumed_at", null);
  if (codeErr) {
    throw new Error(
      `disconnectChat: messaging_link_codes invalidation failed: ${codeErr.message}`,
    );
  }

  const { error: linkErr } = await sb
    .from("user_messaging_links")
    .delete()
    .eq("platform", platform)
    .eq("external_chat_id", externalChatId);
  if (linkErr) {
    throw new Error(
      `disconnectChat: user_messaging_links delete failed: ${linkErr.message}`,
    );
  }
}

export async function unlinkChat(
  platform: Platform,
  externalChatId: string,
  userId: string,
): Promise<void> {
  await disconnectChat(platform, externalChatId, userId);
}
