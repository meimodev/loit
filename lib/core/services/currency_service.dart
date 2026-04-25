import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
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

    Log.d(_tag, 'Getting rate $from→$to (tier=$tier)');
    final cached = await _getCachedRate(from, to);
    final threshold = _staleness[tier]!;

    if (cached != null) {
      final age = DateTime.now().toUtc().difference(cached.$2);
      if (age < threshold) {
        Log.d(_tag, 'Cache hit $from→$to rate=${cached.$1}');
        return FxRate(rate: cached.$1, isStale: false);
      }
    }

    try {
      final rate = tier == UserTier.free
          ? await _fetchFrankfurter(from, to)
          : await _fetchOxr(from, to);
      await _cacheRate(from, to, rate);
      Log.i(_tag, 'Fetched $from→$to rate=$rate');
      return FxRate(rate: rate, isStale: false);
    } catch (e) {
      if (cached != null) {
        Log.w(_tag, 'Fetch failed, using stale rate $from→$to', error: e);
        return FxRate(rate: cached.$1, isStale: true);
      }
      Log.e(_tag, 'FX fetch failed, no cache', error: e);
      rethrow;
    }
  }

  Future<double> _fetchFrankfurter(String from, String to) async {
    final uri = Uri.parse('https://api.frankfurter.app/latest?from=$from&to=$to');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Frankfurter fetch failed');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['rates'][to] as num).toDouble();
  }

  Future<double> _fetchOxr(String from, String to) async {
    final uri = Uri.parse(
      'https://openexchangerates.org/api/latest.json'
      '?app_id=${Env.openExchangeRatesAppId}&base=$from&symbols=$to',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('OXR fetch failed');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['rates'][to] as num).toDouble();
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

  Future<void> _cacheRate(String from, String to, double rate) async {
    await _supabase.from('fx_rates').upsert({
      'base_currency': from,
      'target_currency': to,
      'rate': rate,
      'fetched_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
