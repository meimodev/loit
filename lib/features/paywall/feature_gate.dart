import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FeatureFlags {
  final bool unlimitedBudgets;
  final bool customCategories;
  final bool csvExport;
  final bool pdfExport;
  final bool receiptStorage;
  final bool fullHistory;
  /// `null` = unlimited scans. Otherwise the per-month cap.
  final int? scanLimitPerMonth;
  final int budgetCategoryLimit;

  const FeatureFlags({
    required this.unlimitedBudgets,
    required this.customCategories,
    required this.csvExport,
    required this.pdfExport,
    required this.receiptStorage,
    required this.fullHistory,
    required this.scanLimitPerMonth,
    required this.budgetCategoryLimit,
  });

  bool get hasUnlimitedScans => scanLimitPerMonth == null;

  factory FeatureFlags.forTier(String tier) => switch (tier) {
        'pro' || 'team' => const FeatureFlags(
            unlimitedBudgets: true,
            customCategories: true,
            csvExport: true,
            pdfExport: true,
            receiptStorage: true,
            fullHistory: true,
            scanLimitPerMonth: null, // Pro and Team — unlimited scans
            budgetCategoryLimit: 1 << 30,
          ),
        _ => const FeatureFlags(
            unlimitedBudgets: false,
            customCategories: false,
            csvExport: false,
            pdfExport: false,
            receiptStorage: false,
            fullHistory: false,
            scanLimitPerMonth: 8,
            budgetCategoryLimit: 3,
          ),
      };
}

final featureGateProvider = StreamProvider<FeatureFlags>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return Stream.value(FeatureFlags.forTier('free'));
  return Supabase.instance.client
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('id', user.id)
      .map((rows) {
        if (rows.isEmpty) return FeatureFlags.forTier('free');
        return FeatureFlags.forTier(rows.first['tier'] as String? ?? 'free');
      });
});
