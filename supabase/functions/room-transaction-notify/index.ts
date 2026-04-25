import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';
import { JWT } from 'npm:google-auth-library@9.15.1';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

const serviceAccount = JSON.parse(
  atob(Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON_BASE64')!),
);

const jwt = new JWT({
  email: serviceAccount.client_email,
  key: serviceAccount.private_key,
  scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
});

type NotifyBody = {
  room_id: string;
  actor_id: string;
  merchant?: string | null;
  amount: number | string;
  currency: string;
};

async function getAccessToken(): Promise<string> {
  const tokens = await jwt.authorize();
  if (!tokens.access_token) {
    throw new Error('Could not obtain Firebase access token');
  }
  return tokens.access_token;
}

async function getAuthenticatedUserId(req: Request): Promise<string | null> {
  const authHeader = req.headers.get('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return null;
  }

  const token = authHeader.replace('Bearer ', '');
  const {
    data: { user },
  } = await supabase.auth.getUser(token);

  return user?.id ?? null;
}

async function sendMessage(
  accessToken: string,
  pushTokenId: string,
  deviceToken: string,
  body: NotifyBody,
): Promise<void> {
  const endpoint = `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;
  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      message: {
        token: deviceToken,
        notification: {
          title: body.merchant ?? 'New expense',
          body: `${body.amount} ${body.currency}`,
        },
        data: {
          room_id: body.room_id,
          actor_id: body.actor_id,
          amount: String(body.amount),
          currency: body.currency,
          type: 'room_transaction',
        },
        android: {
          priority: 'high',
          notification: {
            channel_id: 'room_activity',
          },
        },
      },
    }),
  });

  if (response.ok) {
    return;
  }

  const errorText = await response.text();
  if (
    errorText.includes('UNREGISTERED') ||
    errorText.includes('registration-token-not-registered')
  ) {
    await supabase.from('push_tokens').delete().eq('id', pushTokenId);
    return;
  }

  throw new Error(`FCM send failed: ${errorText}`);
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response('Method not allowed', {
      status: 405,
      headers: corsHeaders,
    });
  }

  try {
    const authenticatedUserId = await getAuthenticatedUserId(req);
    if (!authenticatedUserId) {
      return new Response('Unauthorized', {
        status: 401,
        headers: corsHeaders,
      });
    }

    const body = (await req.json()) as NotifyBody;
    if (
      !body.room_id ||
      !body.actor_id ||
      body.amount === undefined ||
      !body.currency
    ) {
      return new Response('Invalid payload', {
        status: 400,
        headers: corsHeaders,
      });
    }

    if (body.actor_id !== authenticatedUserId) {
      return new Response('Forbidden', {
        status: 403,
        headers: corsHeaders,
      });
    }

    const { data: memberships, error: membershipError } = await supabase
      .from('room_members')
      .select('user_id')
      .eq('room_id', body.room_id)
      .eq('user_id', authenticatedUserId)
      .limit(1);

    if (membershipError) {
      throw membershipError;
    }

    if (!memberships || memberships.length === 0) {
      return new Response('Forbidden', {
        status: 403,
        headers: corsHeaders,
      });
    }

    const { data: members, error: membersError } = await supabase
      .from('room_members')
      .select('user_id')
      .eq('room_id', body.room_id)
      .neq('user_id', body.actor_id);

    if (membersError) {
      throw membersError;
    }

    const userIds = (members ?? []).map((member) => member.user_id as string);
    if (userIds.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      });
    }

    const { data: tokens, error: tokensError } = await supabase
      .from('push_tokens')
      .select('id, token')
      .in('user_id', userIds);

    if (tokensError) {
      throw tokensError;
    }

    if (!tokens || tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
        },
      });
    }

    const accessToken = await getAccessToken();
    const results = await Promise.allSettled(
      tokens.map((row) =>
        sendMessage(accessToken, row.id as string, row.token as string, body),
      ),
    );

    const failures = results.filter((result) => result.status === 'rejected');
    if (failures.length > 0) {
      throw (failures[0] as PromiseRejectedResult).reason;
    }

    return new Response(JSON.stringify({ sent: tokens.length }), {
      status: 200,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unexpected error';
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: {
        ...corsHeaders,
        'Content-Type': 'application/json',
      },
    });
  }
});
