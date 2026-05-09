import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportedCurrency {
  final String code;
  final String name;
  final String symbol;
  final int displayOrder;

  const SupportedCurrency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.displayOrder,
  });

  factory SupportedCurrency.fromRow(Map<String, dynamic> r) => SupportedCurrency(
        code: r['code'] as String,
        name: r['name'] as String,
        symbol: r['symbol'] as String,
        displayOrder: (r['display_order'] as num).toInt(),
      );
}

class SupportedCurrencies {
  final List<SupportedCurrency> all;
  final Map<String, SupportedCurrency> byCode;

  const SupportedCurrencies({required this.all, required this.byCode});

  List<String> get codes => all.map((c) => c.code).toList(growable: false);
}

/// Loads the registry once at app start. The list is small (~63 rows) and
/// doesn't change often; cached for the session via `keepAlive`.
final supportedCurrenciesProvider = FutureProvider<SupportedCurrencies>((ref) async {
  final rows = await Supabase.instance.client
      .from('supported_currencies')
      .select('code, name, symbol, display_order')
      .order('display_order', ascending: true);
  final list = (rows as List<dynamic>)
      .map((r) => SupportedCurrency.fromRow(r as Map<String, dynamic>))
      .toList(growable: false);
  return SupportedCurrencies(
    all: list,
    byCode: {for (final c in list) c.code: c},
  );
});
