# Transaction account-ownership is checked against the row subject, not the session actor

**Status:** accepted

The `enforce_transaction_account_ownership()` BEFORE-INSERT trigger validates that a transaction's `account_id` is legitimately usable by the transaction. For a **room** account it originally asked `is_room_member(v_room_id)`, which resolves membership against `auth.uid()` — the *session actor*. That silently assumed every writer carries an end-user JWT.

It doesn't. All server-side capture writers run as **service role** (`serviceClient()`): the Telegram bot (`telegram_text` / `telegram_voice` / `telegram_image`), `parse-voice`, and `scan-receipt`. Under service role `auth.uid()` is `NULL`, so `is_room_member` returned false and every room-scoped insert raised *"account_id is a room account the user cannot access"*. The Telegram pipeline surfaced this to users as *"transaksi tidak ditemukan"* — a message that pointed at parsing, when the parse had actually succeeded and only the save failed.

**Decision:** the trigger now checks that **`NEW.user_id`** (the transaction's owner — the row subject) is a member of the room that owns the account, via an inline `EXISTS` on `room_members`. Ownership is a property of the row being written, not of whoever executes the write.

**Considered and rejected:**
- *Set `request.jwt.claim.sub` per write in each service-role function* so `auth.uid()` resolves — brittle under connection pooling and silently re-breaks the moment a new service-role writer forgets it.
- *Early-exit the trigger for `service_role`* — throws away the integrity guarantee (a mismatched `room_id`/`account_id` would slip through) for exactly the writers that most need it, since they bypass RLS.

**Consequences:** no client regression — RLS already forces `NEW.user_id = auth.uid()` on client writes, so row-subject and session-actor checks are equivalent there. `is_room_member()` is deliberately left unchanged; it remains correct for RLS policies, which run as the end user. Any future service-role writer of room transactions is now covered automatically.
