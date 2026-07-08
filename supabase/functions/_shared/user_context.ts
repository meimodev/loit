import { serviceClient } from "./supabase.ts";

export interface CategoryRef {
  key: string;
  name: string;
  kind: "expense" | "income";
  scope: "user" | "room";
  roomId?: string;
}

export interface AccountRef {
  id: string;
  name: string;
  currency: string;
  kind: "asset" | "debt";
}

export interface RoomRef {
  id: string;
  name: string;
}

// A Room account (pool) — same shape as a personal AccountRef plus its room.
export interface RoomAccountRef extends AccountRef {
  roomId: string;
}

export interface UserContext {
  userId: string;
  email: string | null;
  tier: string;
  language: string;
  homeCurrency: string;
  hideAmounts: boolean;
  scansUsed: number;
  scanTopupBonus: number;
  scanResetDate: string | null;
  accounts: AccountRef[];
  categories: CategoryRef[];
  rooms: RoomRef[];
  // Active Room accounts (pools) across the member's active rooms. The default
  // funding source for a room-targeted capture (ADR-0023).
  roomAccounts: RoomAccountRef[];
}

export async function loadUserContext(userId: string): Promise<UserContext | null> {
  const sb = serviceClient();
  const { data: u } = await sb
    .from("users")
    .select(
      "id, email, tier, language, home_currency, hide_amounts, scans_used_this_month, scan_topup_bonus_this_month, scan_reset_date",
    )
    .eq("id", userId)
    .maybeSingle();
  if (!u) return null;

  const { data: accs } = await sb
    .from("accounts")
    .select("id, name, currency, kind, archived_at")
    .eq("user_id", userId);
  const accounts: AccountRef[] = (accs ?? [])
    .filter((a) => !a.archived_at)
    .map((a) => ({ id: a.id, name: a.name, currency: a.currency, kind: a.kind }));

  const { data: ucats } = await sb
    .from("user_categories")
    .select("key, name, kind")
    .eq("user_id", userId);
  const userCategories: CategoryRef[] = (ucats ?? []).map((c) => ({
    key: c.key,
    name: c.name,
    kind: c.kind,
    scope: "user",
  }));

  // Rooms via room_members membership.
  const { data: memberships } = await sb
    .from("room_members")
    .select("room_id, rooms!inner(id, name, is_archived)")
    .eq("user_id", userId);
  // Active-only, mirroring the accounts filter above: ctx.rooms is the set of
  // valid transaction targets, so archived rooms drop out of every resolver
  // (parse-voice destination + telegram-bot pickers). A summary of a tx whose
  // room was since archived resolves roomName to null and degrades cleanly.
  // ponytail: add a direct-fetch room fallback (like archived accounts) only if
  // the bot ever summarizes historical room transactions.
  const rooms: RoomRef[] = (memberships ?? [])
    .filter((m: any) => !m.rooms.is_archived)
    .map((m: any) => ({
      id: m.rooms.id,
      name: m.rooms.name,
    }));

  let roomCategories: CategoryRef[] = [];
  let roomAccounts: RoomAccountRef[] = [];
  if (rooms.length > 0) {
    const roomIds = rooms.map((r) => r.id);
    const { data: rcats } = await sb
      .from("room_categories")
      .select("room_id, key, name, kind")
      .in("room_id", roomIds);
    roomCategories = (rcats ?? []).map((c: any) => ({
      key: c.key,
      name: c.name,
      kind: c.kind,
      scope: "room",
      roomId: c.room_id,
    }));

    // Room accounts (pools). Oldest-first so "first active" is deterministic,
    // matching the client's first-active-pool heuristic (ADR-0023).
    const { data: raccs } = await sb
      .from("accounts")
      .select("id, name, currency, kind, room_id, archived_at")
      .in("room_id", roomIds)
      .order("created_at", { ascending: true });
    roomAccounts = (raccs ?? [])
      .filter((a: any) => !a.archived_at)
      .map((a: any) => ({
        id: a.id,
        name: a.name,
        currency: a.currency,
        kind: a.kind,
        roomId: a.room_id,
      }));
  }

  return {
    userId: u.id,
    email: (u.email as string | null) ?? null,
    tier: u.tier,
    language: u.language ?? "en",
    homeCurrency: u.home_currency ?? "IDR",
    hideAmounts: !!u.hide_amounts,
    scansUsed: u.scans_used_this_month ?? 0,
    scanTopupBonus: u.scan_topup_bonus_this_month ?? 0,
    scanResetDate: u.scan_reset_date ?? null,
    accounts,
    categories: [...userCategories, ...roomCategories],
    rooms,
    roomAccounts,
  };
}

// Categories visible for a given destination scope.
// - roomId null → only user-scoped categories
// - roomId set  → only categories scoped to that specific room
export function categoriesForScope(
  ctx: UserContext,
  roomId: string | null,
): CategoryRef[] {
  if (roomId) {
    return ctx.categories.filter(
      (c) => c.scope === "room" && c.roomId === roomId,
    );
  }
  return ctx.categories.filter((c) => c.scope === "user");
}

// Find a category by key/kind constrained to the destination scope. Returns
// null if the category doesn't exist in that scope — callers should treat
// this as a validation failure rather than silently widening scope.
export function findCategoryInScope(
  ctx: UserContext,
  key: string,
  kind: "expense" | "income",
  roomId: string | null,
): CategoryRef | null {
  return (
    categoriesForScope(ctx, roomId).find(
      (c) => c.key === key && c.kind === kind,
    ) ?? null
  );
}

// Best-effort remap of a category key from one scope to another by matching
// on name + kind. Used when a user re-routes a parsed personal transaction
// into a room: the personal category key is unlikely to exist in the room's
// own category set, but the same display name often does.
export function remapCategoryAcrossScopes(
  ctx: UserContext,
  fromKey: string,
  kind: "expense" | "income",
  toRoomId: string | null,
): string | null {
  const src = ctx.categories.find((c) => c.key === fromKey);
  if (!src) return null;
  const target = categoriesForScope(ctx, toRoomId).find(
    (c) =>
      c.kind === kind && c.name.toLowerCase() === src.name.toLowerCase(),
  );
  return target?.key ?? null;
}
