// Daily cron — downgrades users whose `tier_expires_at` has passed.
//
// Required while RevenueCat runs in "limited mode" (no Play Developer API
// service account on RC's side). Without service account, RevenueCat
// cannot reliably surface EXPIRATION events for Google Play subscriptions.
// We compensate by sweeping the users table once per day and downgrading
// anyone past their stored expiry timestamp.
//
// Schedule via Supabase dashboard:
//   Edge Functions → subscription-downgrade-cron → Schedule → cron `0 3 * * *`
//   (03:00 UTC daily; pick whatever low-traffic hour suits)
//
// Idempotent — running twice in one day is harmless.

import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

serve(async () => {
  const nowIso = new Date().toISOString();

  // Find paid users whose entitlement window has closed.
  const { data: lapsed, error } = await supabase
    .from('users')
    .select('id, tier, tier_expires_at')
    .neq('tier', 'free')
    .not('tier_expires_at', 'is', null)
    .lt('tier_expires_at', nowIso);

  if (error) {
    console.error('lapsed query failed:', error);
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
    });
  }

  if (!lapsed || lapsed.length === 0) {
    return new Response(JSON.stringify({ ok: true, downgraded: 0 }));
  }

  const ids = lapsed.map((u) => u.id);
  const { error: updateErr } = await supabase
    .from('users')
    .update({ tier: 'free', tier_expires_at: null })
    .in('id', ids);

  if (updateErr) {
    console.error('downgrade update failed:', updateErr);
    return new Response(JSON.stringify({ error: updateErr.message }), {
      status: 500,
    });
  }

  console.log(`Downgraded ${ids.length} users:`, ids);
  return new Response(
    JSON.stringify({ ok: true, downgraded: ids.length, ids }),
  );
});
