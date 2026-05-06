-- fx_rates is a shared global cache (no user_id).
-- Authenticated users need INSERT + UPDATE to cache fetched exchange rates.
CREATE POLICY "fx_rates_insert_auth" ON fx_rates
  FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "fx_rates_update_auth" ON fx_rates
  FOR UPDATE USING (auth.role() = 'authenticated');
