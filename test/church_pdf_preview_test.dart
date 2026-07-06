// Render smoke-check for the two beautified church PDFs: each builds to valid,
// non-empty PDF bytes (cover + summary cards + section bodies exercised).
// Offline — built-in fonts, no network, no disk writes.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:loit/features/rooms/church/church_report_service.dart';
import 'package:loit/features/rooms/church/church_realisasi_service.dart';
import 'package:loit/shared/providers/transactions_provider.dart';

void main() {
  final org = {'jemaat_name': 'Jemaat GMIM Imanuel Winangun'};
  final start = DateTime(2026, 5, 1);
  final end = DateTime(2026, 5, 31);

  setUpAll(() => initializeDateFormatting('id'));

  bool isPdf(List<int> b) =>
      b.length > 1000 && b[0] == 0x25 && b[1] == 0x50; // "%P"

  test('Laporan Keuangan builds a PDF', () async {
    final bytes = await ChurchReportService().buildStatementPdf(
      orgConfig: org,
      baseCurrency: 'IDR',
      start: start,
      end: end,
      penerimaan: {'Persembahan Minggu': 4250000, 'Perpuluhan': 2100000},
      pengeluaran: {'Operasional': 1200000, 'Diakonia': 650000},
    );
    expect(isPdf(bytes), isTrue);
  });

  test('Laporan Realisasi builds a PDF, unclassified included', () async {
    final unclassified = Txn(
      id: 'x1',
      amount: 500000,
      currency: 'IDR',
      fxSnapshot: const {},
      category: 'other',
      notes: 'Setoran tanpa keterangan',
      receiptUrl: null,
      aiParsed: false,
      isManualFallback: false,
      createdAt: DateTime(2026, 5, 14),
    );
    final bytes = await ChurchRealisasiService().buildRealisasiPdf(
      orgConfig: org,
      baseCurrency: 'IDR',
      start: start,
      end: end,
      incomeDirect: {'1.3.50.01': 4250000, '1.3.51.00': 2100000},
      expenseDirect: {'1.3.02.01': 650000},
      unclassified: [unclassified],
    );
    expect(isPdf(bytes), isTrue);
  });
}
