import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/pricing_constants.dart';

class FeatureFlags {
  final bool unlimitedBudgets;
  final bool customCategories;
  final bool csvExport;
  final bool pdfExport;
  final bool receiptStorage;
  final bool fullHistory;
  /// `null` = unlimited scans. Otherwise the per-month cap.
  /// Free 5, Lite 30, Pro 150. Team tier dropped — any legacy `team` row is
  /// migrated to `pro` by the drop_team migration.
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

  // Room creation cap is per-user (base + purchased slots, ADR-0020) and lives
  // on `UserProfile` (roomsCreatedTotal / effectiveRoomCap), not here — it can't
  // be a static per-tier flag once slots are buyable.

  factory FeatureFlags.forTier(String tier) => switch (tier) {
        'pro' => const FeatureFlags(
            unlimitedBudgets: true,
            customCategories: true,
            csvExport: true,
            pdfExport: true,
            receiptStorage: true,
            fullHistory: true,
            scanLimitPerMonth: PricingConstants.scanCapPro,
            budgetCategoryLimit: 1 << 30,
          ),
        'lite' => const FeatureFlags(
            unlimitedBudgets: true,
            customCategories: true,
            csvExport: true,
            pdfExport: false,
            receiptStorage: true,
            fullHistory: true,
            scanLimitPerMonth: PricingConstants.scanCapLite,
            budgetCategoryLimit: 1 << 30,
          ),
        _ => const FeatureFlags(
            unlimitedBudgets: false,
            customCategories: false,
            csvExport: false,
            pdfExport: false,
            receiptStorage: false,
            fullHistory: false,
            scanLimitPerMonth: PricingConstants.scanCapFree,
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
