import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json', ...CORS_HEADERS },
  });
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: CORS_HEADERS });
  if (req.method !== 'POST') return json({ error: 'Method Not Allowed' }, 405);

  const authHeader = req.headers.get('Authorization');
  if (!authHeader) return json({ error: 'Unauthorized' }, 401);

  const { data: { user } } = await supabase.auth.getUser(
    authHeader.replace('Bearer ', ''),
  );
  if (!user) return json({ error: 'Unauthorized' }, 401);

  const { room_id, invited_email } = await req.json();
  if (!room_id || !invited_email) {
    return json({ error: 'room_id and invited_email required' }, 400);
  }

  // Caller must be a room member
  const { data: member } = await supabase
    .from('room_members')
    .select('role')
    .eq('room_id', room_id)
    .eq('user_id', user.id)
    .maybeSingle();
  if (!member) return json({ error: 'Forbidden' }, 403);

  // Look up invitee — must already have an account
  const { data: invitee } = await supabase
    .from('users')
    .select('id')
    .eq('email', invited_email)
    .maybeSingle();
  if (!invitee) return json({ error: 'User not found' }, 404);

  // Insert pending invite (partial unique index enforces one pending per user+room)
  const token = crypto.randomUUID();
  const { error } = await supabase.from('room_invites').insert({
    room_id,
    invited_user_id: invitee.id,
    invite_token: token,
    expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
  });

  if (error) {
    if (error.code === '23505') {
      return json({ error: 'User already has a pending invite' }, 409);
    }
    return json({ error: error.message }, 500);
  }

  // Notify invitee in-app.
  const { data: room } = await supabase
    .from('rooms')
    .select('name')
    .eq('id', room_id)
    .maybeSingle();
  await supabase.from('notifications').insert({
    user_id: invitee.id,
    kind: 'invite',
    title: 'Room invitation',
    body: `You've been invited to join ${room?.name ?? 'a room'}.`,
    deep_link: '/rooms',
    metadata: { room_id, invite_token: token },
  });

  return json({
    invite_token: token,
    invite_url: `https://loit.app/invite/${token}`,
  });
});
