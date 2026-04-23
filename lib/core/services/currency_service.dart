import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

class FxRate {
  final double rate;
  final bool isStale;
  const FxRate({required this.rate, required this.isStale});
}

class CurrencyService {
  // Free tier uses Frankfurter — treat as stale after 25 hours.
  static const Duration _freeTierStaleness = Duration(hours: 25);
  // Pro/Team use Open Exchange Rates (30-min refresh) — treat as stale after 35 minutes.
  static const Duration _paidTierStaleness = Duration(minutes: 35);

  static const String _frankfurterBase = 'https://api.frankfurter.app';
  static const String _oxrBase         = 'https://openexchangerates.org/api';

  final _supabase = Supabase.instance.client;

  Duration _stalenessDuration(String tier) =>
      (tier == 'pro' || tier == 'team') ? _paidTierStaleness : _freeTierStaleness;

  Future<FxRate> getRate({
    required String from,
    required String to,
    required String userTier,
  }) async {
    if (from == to) return const FxRate(rate: 1.0, isStale: false);

    final cached = await _getCachedRate(from, to);
    final threshold = _stalenessDuration(userTier);

    if (cached != null) {
      final age = DateTime.now().toUtc().difference(cached.$2);
      if (age < threshold) return FxRate(rate: cached.$1, isStale: false);
    }

    try {
      final rate = await _fetchRate(from, to, userTier);
      await _cacheRate(from, to, rate);
      return FxRate(rate: rate, isStale: false);
    } catch (_) {
      if (cached != null) return FxRate(rate: cached.$1, isStale: true);
      rethrow;
    }
  }

  Future<double> _fetchRate(String from, String to, String tier) async {
    // If the paid-tier app ID is not present in the client build, fall back
    // to Frankfurter rather than failing outright — matches the server-side
    // secret-only preference documented in env.dart.
    final canUseOxr =
        (tier == 'pro' || tier == 'team') && Env.openExchangeRatesAppId.isNotEmpty;
    return canUseOxr
        ? _fetchFromOpenExchangeRates(from, to)
        : _fetchFromFrankfurter(from, to);
  }

  Future<double> _fetchFromFrankfurter(String from, String to) async {
    final uri = Uri.parse('$_frankfurterBase/latest?from=$from&to=$to');
    final res = await http.get(uri).timeout(const Duration(seconds: 10));
    if (res.statusCode != 200) throw Exception('Frankfurter fetch failed');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['rates'][to] as num).toDouble();
  }

  Future<double> _fetchFromOpenExchangeRates(String from, String to) async {
    final appId = Env.openExchangeRatesAppId;
    final uri = Uri.parse('$_oxrBase/latest.json?app_id=$appId&base=$from&symbols=$to');
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
