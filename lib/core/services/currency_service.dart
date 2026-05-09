import 'package:supabase_flutter/supabase_flutter.dart';
import 'log_service.dart';

/// Client-side FX service. Reads USD-base rates from `fx_rates` table and
/// derives cross-rates locally via `from→to = rate_per_usd[to] / rate_per_usd[from]`.
///
/// Rates are refreshed every 3h by the `fx-rate-refresh` edge function (cron).
/// If the cache is older than [_staleThreshold], `refreshIfStale()` invokes
/// the user-callable `fx-rate` edge function as a fallback.
class CurrencyService {
  static const _tag = 'CurrencyService';
  static const _staleThreshold = Duration(hours: 4);

  final _supabase = Supabase.instance.client;

  /// Loads all USD-base rates from `fx_rates`. Map shape: `{currency: rate_per_usd}`.
  /// `USD` is implicitly 1.0 and always present.
  Future<Map<String, double>> loadUsdBaseRates() async {
    final rows = await _supabase
        .from('fx_rates')
        .select('currency, rate_per_usd');
    final out = <String, double>{};
    for (final r in rows as List<dynamic>) {
      final m = r as Map<String, dynamic>;
      out[m['currency'] as String] = (m['rate_per_usd'] as num).toDouble();
    }
    out['USD'] = 1.0;
    return out;
  }

  /// Reads `max(fetched_at)` and triggers a server-side refresh if older than
  /// [_staleThreshold]. Safe to call frequently — server is idempotent.
  Future<void> refreshIfStale() async {
    final row = await _supabase
        .from('fx_rates')
        .select('fetched_at')
        .order('fetched_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (row == null) {
      await _invokeRefresh();
      return;
    }
    final fetchedAt = DateTime.parse(row['fetched_at'] as String);
    final age = DateTime.now().toUtc().difference(fetchedAt);
    if (age > _staleThreshold) {
      Log.i(_tag, 'fx_rates stale (age=${age.inMinutes}min) → invoking fx-rate');
      await _invokeRefresh();
    }
  }

  Future<void> _invokeRefresh() async {
    try {
      await _supabase.functions.invoke('fx-rate');
    } catch (e) {
      Log.w(_tag, 'fx-rate refresh failed', error: e);
    }
  }

  /// Cross-rate from `from` to `to` derived via USD.
  /// Returns 1.0 if `from == to`.
  static double convert({
    required String from,
    required String to,
    required Map<String, double> rates,
  }) {
    if (from == to) return 1.0;
    final usdToFrom = rates[from];
    final usdToTo = rates[to];
    if (usdToFrom == null || usdToTo == null || usdToFrom <= 0) {
      throw StateError('Missing fx rate for $from or $to');
    }
    return usdToTo / usdToFrom;
  }

  /// Builds the per-transaction snapshot: `{target: rate from `from` to target}`
  /// for every code in [supported]. The base currency itself maps to 1.0.
  static Map<String, double> buildSnapshot({
    required String from,
    required Map<String, double> rates,
    required List<String> supported,
  }) {
    final out = <String, double>{};
    for (final code in supported) {
      out[code] = convert(from: from, to: code, rates: rates);
    }
    return out;
  }
}
