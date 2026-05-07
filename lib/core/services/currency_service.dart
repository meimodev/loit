import 'package:supabase_flutter/supabase_flutter.dart';
import 'log_service.dart';

enum UserTier {
  free, pro, team;

  static UserTier fromString(String value) => switch (value) {
    'pro' => pro,
    'team' => team,
    _ => free,
  };
}

class FxRate {
  final double rate;
  final bool isStale;
  const FxRate({required this.rate, required this.isStale});
}

/// Client-side FX service. Reads `fx_rates` table directly when fresh; on
/// cache miss or staleness invokes the `fx-rate` edge function (which holds
/// the OXR secret + enforces tier-based source selection).
class CurrencyService {
  static const _tag = 'CurrencyService';
  static const _staleness = {
    UserTier.free: Duration(hours: 25),
    UserTier.pro: Duration(minutes: 35),
    UserTier.team: Duration(minutes: 35),
  };

  final _supabase = Supabase.instance.client;

  Future<FxRate> getRate({
    required String from,
    required String to,
    required UserTier tier,
  }) async {
    if (from == to) return const FxRate(rate: 1.0, isStale: false);

    final cached = await _getCachedRate(from, to);
    final threshold = _staleness[tier]!;

    if (cached != null) {
      final age = DateTime.now().toUtc().difference(cached.$2);
      if (age < threshold) {
        return FxRate(rate: cached.$1, isStale: false);
      }
    }

    try {
      final res = await _supabase.functions.invoke(
        'fx-rate',
        body: {'from': from, 'to': to},
      );
      final data = res.data;
      if (data is! Map || data['rate'] is! num) {
        throw StateError('fx-rate: malformed response: $data');
      }
      final rate = (data['rate'] as num).toDouble();
      final isStale = data['isStale'] == true;
      Log.i(_tag, 'fx-rate $from→$to rate=$rate stale=$isStale '
          'src=${data['source']}');
      return FxRate(rate: rate, isStale: isStale);
    } catch (e) {
      if (cached != null) {
        Log.w(_tag, 'fx-rate invoke failed, using stale cache $from→$to',
            error: e);
        return FxRate(rate: cached.$1, isStale: true);
      }
      Log.e(_tag, 'fx-rate invoke failed, no cache', error: e);
      rethrow;
    }
  }

  /// Batch rate fetch for room/report aggregations. Distinct pairs only.
  /// Returned map keyed by `'$from→$to'`.
  Future<Map<String, FxRate>> getRates({
    required Set<(String, String)> pairs,
    required UserTier tier,
  }) async {
    final out = <String, FxRate>{};
    for (final (from, to) in pairs) {
      try {
        out['$from→$to'] = await getRate(from: from, to: to, tier: tier);
      } catch (_) {
        // Best-effort — skip pairs that fail; caller decides UX.
      }
    }
    return out;
  }

  Future<(double, DateTime)?> _getCachedRate(String from, String to) async {
    final result = await _supabase
        .from('fx_rates')
        .select('rate, fetched_at')
        .eq('base_currency', from)
        .eq('target_currency', to)
        .maybeSingle();
    if (result == null) return null;
    return (
      (result['rate'] as num).toDouble(),
      DateTime.parse(result['fetched_at'] as String),
    );
  }
}
