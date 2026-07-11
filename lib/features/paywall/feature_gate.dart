import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/pricing_constants.dart';

class FeatureFlags {
  final bool csvExport;
  final bool pdfExport;
  final bool receiptStorage;
  /// `null` = unlimited scans. Otherwise the per-month cap.
  /// Free 5, Lite 30, Pro 150. Team tier dropped — any legacy `team` row is
  /// migrated to `pro` by the drop_team migration.
  final int? scanLimitPerMonth;

  const FeatureFlags({
    required this.csvExport,
    required this.pdfExport,
    required this.receiptStorage,
    required this.scanLimitPerMonth,
  });

  bool get hasUnlimitedScans => scanLimitPerMonth == null;

  // Room creation cap is per-user (base + purchased slots, ADR-0020) and lives
  // on `UserProfile` (roomsCreatedTotal / effectiveRoomCap), not here — it can't
  // be a static per-tier flag once slots are buyable.
  //
  // The budget cap likewise lives on `UserProfile.budgetLimit` (free 3, paid
  // 999), which is the rule `budgets_screen` actually enforces.

  factory FeatureFlags.forTier(String tier) => switch (tier) {
        'pro' => const FeatureFlags(
            csvExport: true,
            pdfExport: true,
            receiptStorage: true,
            scanLimitPerMonth: PricingConstants.scanCapPro,
          ),
        'lite' => const FeatureFlags(
            csvExport: true,
            pdfExport: false,
            receiptStorage: true,
            scanLimitPerMonth: PricingConstants.scanCapLite,
          ),
        _ => const FeatureFlags(
            csvExport: false,
            pdfExport: false,
            receiptStorage: false,
            scanLimitPerMonth: PricingConstants.scanCapFree,
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
