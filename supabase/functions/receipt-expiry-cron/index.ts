// Phase 3 Step 3.6: receipt expiry sweeper.
// Runs daily (Supabase Cron, configured in dashboard).
//   1. Deletes receipts whose receipt_expires_at <= now() — both the storage
//      file and the receipt_url/receipt_expires_at columns on transactions.
//   2. Refreshes users.next_receipt_expiry_at with the soonest upcoming
//      expiry (NULL if none).
//
// Push and email warnings are deferred — for now Flutter renders a banner
// driven by next_receipt_expiry_at being within 30 days.
//
// Authorize the cron caller with the SUPABASE_SERVICE_ROLE_KEY in the
// Authorization header (set on the Cron job in the dashboard).
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

serve(async (req) => {
  // Cron caller must present a service_role JWT. Decode the bearer and check
  // the role claim instead of string-equality against env, since Supabase may
  // rotate the injected key independently of the cron config.
  const auth = req.headers.get('Authorization') ?? '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';
  let role = '';
  try {
    const part = token.split('.')[1] ?? '';
    const padded = part + '='.repeat((4 - (part.length % 4)) % 4);
    const json = atob(padded.replace(/-/g, '+').replace(/_/g, '/'));
    role = JSON.parse(json).role ?? '';
  } catch {
    role = '';
  }
  if (role !== 'service_role') {
    return new Response('Unauthorized', { status: 401 });
  }

  const now = new Date();
  let deletedCount = 0;
  let warningUserCount = 0;

  // 1. Delete expired receipts.
  const { data: expired, error: expiredErr } = await supabase
    .from('transactions')
    .select('id, user_id, receipt_url')
    .lte('receipt_expires_at', now.toISOString())
    .not('receipt_url', 'is', null);

  if (expiredErr) {
    return new Response(JSON.stringify({ error: expiredErr.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  for (const txn of expired ?? []) {
    const path = txn.receipt_url as string;
    const { error: removeErr } = await supabase.storage
      .from('receipts')
      .remove([path]);
    if (removeErr) {
      console.error('Storage remove failed', path, removeErr);
      continue;
    }
    await supabase
      .from('transactions')
      .update({ receipt_url: null, receipt_expires_at: null })
      .eq('id', txn.id);
    deletedCount += 1;
  }

  // 2. Refresh next_receipt_expiry_at for every user with at least one
  //    upcoming receipt expiry. Users with none get NULL.
  const { data: upcoming, error: upcomingErr } = await supabase
    .from('transactions')
    .select('user_id, receipt_expires_at')
    .gt('receipt_expires_at', now.toISOString())
    .not('receipt_url', 'is', null)
    .order('receipt_expires_at', { ascending: true });

  if (upcomingErr) {
    return new Response(JSON.stringify({ error: upcomingErr.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const earliestByUser = new Map<string, string>();
  for (const row of upcoming ?? []) {
    const uid = row.user_id as string;
    if (!earliestByUser.has(uid)) {
      earliestByUser.set(uid, row.receipt_expires_at as string);
    }
  }

  // Reset everyone first, then set the ones with upcoming receipts. Two
  // statements keep the logic readable; cron runs once a day so the cost
  // is negligible.
  await supabase
    .from('users')
    .update({ next_receipt_expiry_at: null })
    .not('next_receipt_expiry_at', 'is', null);

  // Notify users whose earliest upcoming receipt expires within 14 days.
  const fourteenDaysMs = 14 * 24 * 60 * 60 * 1000;
  const notifRows: Array<Record<string, unknown>> = [];
  for (const [uid, ts] of earliestByUser.entries()) {
    await supabase
      .from('users')
      .update({ next_receipt_expiry_at: ts })
      .eq('id', uid);
    warningUserCount += 1;

    const expiresAt = new Date(ts);
    if (expiresAt.getTime() - now.getTime() <= fourteenDaysMs) {
      notifRows.push({
        user_id: uid,
        kind: 'receipt',
        title: 'Receipt expiring soon',
        body: `A receipt will be auto-deleted on ${ts.slice(0, 10)} (free-tier 90-day window).`,
        deep_link: '/transactions',
        metadata: { expires_at: ts },
      });
    }
  }
  if (notifRows.length > 0) {
    await supabase.from('notifications').insert(notifRows);
  }

  // 3. Sweep stashed receipts for expired/unconfirmed Telegram pendings. The
  //    SQL cleanup cron deliberately skips stash-bearing rows (it can't touch
  //    storage), so this owns their full lifecycle: delete the blob, then the
  //    row. Non-stash expired pendings are left for the SQL sweep.
  let stashSwept = 0;
  const { data: stalePendings } = await supabase
    .from('bot_pending_transactions')
    .select('id, payload')
    .lte('expires_at', now.toISOString());
  for (const row of stalePendings ?? []) {
    const stash = (row.payload as Record<string, unknown> | null)?.receiptStash;
    if (typeof stash !== 'string') continue;
    await supabase.storage.from('receipts').remove([stash]);
    await supabase.from('bot_pending_transactions').delete().eq('id', row.id);
    stashSwept += 1;
  }

  return new Response(
    JSON.stringify({
      deleted: deletedCount,
      users_with_upcoming: warningUserCount,
      stash_swept: stashSwept,
    }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
});
