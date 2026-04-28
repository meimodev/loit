// Phase 3 Step 3.7: recurring bills materializer.
// Daily cron. For every active recurring_bills row whose next_due_date <= today:
//   1. Insert a draft transaction (notes = "Recurring: <merchant>").
//   2. Advance next_due_date by frequency.
// Auth via Bearer SUPABASE_SERVICE_ROLE_KEY header (set on Cron job).
import { serve } from 'https://deno.land/std@0.224.0/http/server.ts';
import { createClient } from 'npm:@supabase/supabase-js@2.46.1';

const supabase = createClient(
  Deno.env.get('SUPABASE_URL')!,
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
);

function advance(date: string, freq: string): string {
  const d = new Date(date + 'T00:00:00Z');
  if (freq === 'weekly') d.setUTCDate(d.getUTCDate() + 7);
  else if (freq === 'monthly') d.setUTCMonth(d.getUTCMonth() + 1);
  else if (freq === 'yearly') d.setUTCFullYear(d.getUTCFullYear() + 1);
  return d.toISOString().slice(0, 10);
}

serve(async (req) => {
  const auth = req.headers.get('Authorization') ?? '';
  const expected = `Bearer ${Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!}`;
  if (auth !== expected) return new Response('Unauthorized', { status: 401 });

  const today = new Date().toISOString().slice(0, 10);
  const { data: due, error } = await supabase
    .from('recurring_bills')
    .select('id, user_id, merchant, amount, currency, category, frequency, next_due_date')
    .eq('is_active', true)
    .lte('next_due_date', today);

  if (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }

  let materialized = 0;
  for (const bill of due ?? []) {
    const { error: insErr } = await supabase.from('transactions').insert({
      user_id: bill.user_id,
      merchant: bill.merchant,
      amount: bill.amount,
      currency: bill.currency,
      category: bill.category,
      notes: `Recurring: ${bill.merchant ?? bill.category ?? 'bill'}`,
      ai_parsed: false,
      is_manual_fallback: false,
    });
    if (insErr) {
      console.error('Insert txn failed', bill.id, insErr);
      continue;
    }
    const next = advance(bill.next_due_date as string, bill.frequency as string);
    await supabase
      .from('recurring_bills')
      .update({ next_due_date: next })
      .eq('id', bill.id);
    materialized += 1;
  }

  return new Response(
    JSON.stringify({ materialized }),
    { status: 200, headers: { 'Content-Type': 'application/json' } },
  );
});
