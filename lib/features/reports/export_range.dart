import 'package:flutter/material.dart' show DateTimeRange;

import '../../shared/providers/transactions_provider.dart';

/// Quick date-range presets shared by every export surface. [custom] means the
/// range came from the picker, so no preset chip is highlighted and it has no
/// computed range.
enum ExportRangePreset { month, quarter, year, custom }

/// Resolves a preset to a concrete inclusive [DateTimeRange] relative to [now].
/// Quarter/year are calendar-based (current quarter, Jan 1 – Dec 31).
DateTimeRange exportPresetRange(ExportRangePreset p, DateTime now) {
  switch (p) {
    case ExportRangePreset.month:
      return DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
      );
    case ExportRangePreset.quarter:
      final q = ((now.month - 1) ~/ 3) * 3 + 1;
      return DateTimeRange(
        start: DateTime(now.year, q, 1),
        end: DateTime(now.year, q + 3, 0),
      );
    case ExportRangePreset.year:
      return DateTimeRange(
        start: DateTime(now.year, 1, 1),
        end: DateTime(now.year, 12, 31),
      );
    case ExportRangePreset.custom:
      throw ArgumentError('custom has no computed range');
  }
}

/// Church financial statement (Laporan Keuangan) scope: pool-funded rows in
/// the selected period. Keeps the day end-inclusive in local time and filters
/// to Room-account membership, falling back to all rows when the room has no
/// Room account yet so a statement still renders (ADR 0019 / 0021).
List<Txn> statementScopedTxns({
  required List<Txn> all,
  required Set<String> roomAccountIds,
  required DateTime start,
  required DateTime end,
}) {
  final endExclusive =
      DateTime(end.year, end.month, end.day).add(const Duration(days: 1));
  return all.where((t) {
    final ts = t.createdAt.toLocal();
    if (ts.isBefore(start) || !ts.isBefore(endExclusive)) return false;
    if (roomAccountIds.isEmpty) return true;
    return t.accountId != null && roomAccountIds.contains(t.accountId);
  }).toList();
}
