import { createClient, SupabaseClient } from "npm:@supabase/supabase-js@2.46.1";

let _client: SupabaseClient | null = null;

export function serviceClient(): SupabaseClient {
  if (_client) return _client;
  _client = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
  return _client;
}
