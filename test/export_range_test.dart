import 'package:flutter_test/flutter_test.dart';
import 'package:loit/features/reports/export_range.dart';
import 'package:loit/shared/providers/transactions_provider.dart';

Txn _tx(String id, String date, {String? accountId, String type = 'expense'}) =>
    Txn.fromRow({
      'id': id,
      'amount': 1000,
      'currency': 'IDR',
      'created_at': date,
      'account_id': accountId,
      'type': type,
    });

void main() {
  group('exportPresetRange', () {
    final now = DateTime(2026, 6, 15);

    test('month is the current calendar month', () {
      final r = exportPresetRange(ExportRangePreset.month, now);
      expect(r.start, DateTime(2026, 6, 1));
      expect(r.end, DateTime(2026, 6, 30));
    });

    test('quarter is the current calendar quarter', () {
      // June → Q2 (Apr 1 – Jun 30).
      final r = exportPresetRange(ExportRangePreset.quarter, now);
      expect(r.start, DateTime(2026, 4, 1));
      expect(r.end, DateTime(2026, 6, 30));
    });

    test('year is Jan 1 – Dec 31', () {
      final r = exportPresetRange(ExportRangePreset.year, now);
      expect(r.start, DateTime(2026, 1, 1));
      expect(r.end, DateTime(2026, 12, 31));
    });

    test('custom has no computed range', () {
      expect(() => exportPresetRange(ExportRangePreset.custom, now),
          throwsArgumentError);
    });
  });

  group('statementScopedTxns', () {
    final start = DateTime(2026, 6, 1);
    final end = DateTime(2026, 6, 30);

    final inPeriodRoom =
        _tx('a', '2026-06-10T12:00:00', accountId: 'room1');
    final inPeriodOther =
        _tx('b', '2026-06-10T12:00:00', accountId: 'personal');
    final beforePeriod =
        _tx('c', '2026-05-31T12:00:00', accountId: 'room1');
    final afterPeriod =
        _tx('d', '2026-07-01T00:00:00', accountId: 'room1');
    final all = [inPeriodRoom, inPeriodOther, beforePeriod, afterPeriod];

    test('keeps only pool-funded rows in the period', () {
      final out = statementScopedTxns(
        all: all,
        roomAccountIds: {'room1'},
        start: start,
        end: end,
      );
      expect(out.map((t) => t.id), ['a']);
    });

    test('falls back to all in-period rows when no Room account exists', () {
      final out = statementScopedTxns(
        all: all,
        roomAccountIds: const {},
        start: start,
        end: end,
      );
      expect(out.map((t) => t.id), ['a', 'b']);
    });

    test('end day is inclusive, next day excluded', () {
      final lastDay = _tx('e', '2026-06-30T23:30:00', accountId: 'room1');
      final out = statementScopedTxns(
        all: [lastDay, afterPeriod],
        roomAccountIds: {'room1'},
        start: start,
        end: end,
      );
      expect(out.map((t) => t.id), ['e']);
    });
  });
}
