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
  /// Free 5, Lite 30, Pro 150. Team tier dropped — any legacy `team` row is
  /// migrated to `pro` by the drop_team migration.
  final int? scanLimitPerMonth;
  final int budgetCategoryLimit;

  /// `null` = unlimited rooms. Otherwise the maximum number of rooms the
  /// user may belong to / create.
  final int? roomLimit;

  const FeatureFlags({
    required this.unlimitedBudgets,
    required this.customCategories,
    required this.csvExport,
    required this.pdfExport,
    required this.receiptStorage,
    required this.fullHistory,
    required this.scanLimitPerMonth,
    required this.budgetCategoryLimit,
    required this.roomLimit,
  });

  bool get hasUnlimitedScans => scanLimitPerMonth == null;
  bool get hasUnlimitedRooms => roomLimit == null;

  factory FeatureFlags.forTier(String tier) => switch (tier) {
        'pro' => const FeatureFlags(
            unlimitedBudgets: true,
            customCategories: true,
            csvExport: true,
            pdfExport: true,
            receiptStorage: true,
            fullHistory: true,
            scanLimitPerMonth: 150,
            budgetCategoryLimit: 1 << 30,
            roomLimit: null,
          ),
        'lite' => const FeatureFlags(
            unlimitedBudgets: true,
            customCategories: true,
            csvExport: true,
            pdfExport: false,
            receiptStorage: true,
            fullHistory: true,
            scanLimitPerMonth: 30,
            budgetCategoryLimit: 1 << 30,
            roomLimit: 3,
          ),
        _ => const FeatureFlags(
            unlimitedBudgets: false,
            customCategories: false,
            csvExport: false,
            pdfExport: false,
            receiptStorage: false,
            fullHistory: false,
            scanLimitPerMonth: 5,
            budgetCategoryLimit: 3,
            roomLimit: 1,
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
