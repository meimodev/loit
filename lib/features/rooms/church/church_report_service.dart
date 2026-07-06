import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../shared/providers/transactions_provider.dart';
import '../../reports/export_service.dart';

/// Church financial statement (ADR 0019) — a category-grouped Penerimaan /
/// Pengeluaran statement built on top of the room's ordinary transactions.
/// Tables only, no AI narrative. Header is sourced from `org_config`; empty
/// optional fields drop their whole line (never render a bare label).
///
/// Unlike the generic transaction-listing export, this is a financial
/// statement: rows are per-category subtotals, not individual transactions.
class ChurchReportService {
  /// Builds the statement PDF and opens the system share sheet.
  ///
  /// [txns] must already be scoped to the room, the period, and pool funding
  /// by the caller; [categoryNames] maps a transaction's category key to its
  /// display name. [baseCurrency] is the room currency (IDR for church rooms).
  Future<void> generateAndShare({
    required Map<String, dynamic> orgConfig,
    required String baseCurrency,
    required DateTime start,
    required DateTime end,
    required List<Txn> txns,
    required Map<String, String> categoryNames,
    bool asCsv = false,
  }) async {
    final penerimaan = <String, double>{};
    final pengeluaran = <String, double>{};
    for (final t in txns) {
      if (t.isTransfer) continue;
      final name =
          categoryNames[t.category] ?? t.category ?? 'Tanpa Kategori';
      final amt = t.absAmountIn(baseCurrency);
      (t.isIncome ? penerimaan : pengeluaran)
          .update(name, (v) => v + amt, ifAbsent: () => amt);
    }

    if (asCsv) {
      await _shareCsv(orgConfig, start, end, penerimaan, pengeluaran);
      return;
    }

    final font = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();
    final bytes = await buildStatementPdf(
      orgConfig: orgConfig,
      baseCurrency: baseCurrency,
      start: start,
      end: end,
      penerimaan: penerimaan,
      pengeluaran: pengeluaran,
      font: font,
      bold: bold,
    );
    final jemaat = (orgConfig['jemaat_name'] as String?)?.trim();
    final slug = (jemaat == null || jemaat.isEmpty ? 'gereja' : jemaat)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    await Printing.sharePdf(bytes: bytes, filename: 'laporan_$slug.pdf');
  }

  /// Renders the statement PDF to bytes, share/preview agnostic. [font]/[bold]
  /// are optional — omit them (tests/preview) to fall back to built-in fonts.
  Future<Uint8List> buildStatementPdf({
    required Map<String, dynamic> orgConfig,
    required String baseCurrency,
    required DateTime start,
    required DateTime end,
    required Map<String, double> penerimaan,
    required Map<String, double> pengeluaran,
    pw.Font? font,
    pw.Font? bold,
  }) async {
    String money(num v) => formatMoney(v, baseCurrency);
    final periodLabel = _periodLabel(start, end);
    final jemaat = (orgConfig['jemaat_name'] as String?)?.trim();
    final jemaatName = jemaat == null || jemaat.isEmpty ? 'Gereja' : jemaat;
    final totalPen = penerimaan.values.fold<double>(0, (s, v) => s + v);
    final totalPeng = pengeluaran.values.fold<double>(0, (s, v) => s + v);
    final saldo = totalPen - totalPeng;

    final theme = font != null && bold != null
        ? pw.ThemeData.withFont(base: font, bold: bold)
        : null;
    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 36, 32, 36),
        header: (ctx) => pdfReportRunningHeader(ctx, jemaatName, periodLabel),
        footer: (ctx) => pdfReportPageFooter(ctx, label: 'Halaman'),
        build: (context) => [
          pdfReportCover(
            title: 'Laporan Keuangan',
            subtitle: jemaatName,
            fields: [('Periode', periodLabel)],
          ),
          pw.SizedBox(height: 18),
          pdfReportSectionTitle('Ringkasan'),
          pw.SizedBox(height: 6),
          pw.Row(children: [
            pw.Expanded(
                child: pdfReportSummaryCard(
                    'Penerimaan', money(totalPen), pdfReportSuccess)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: pdfReportSummaryCard(
                    'Pengeluaran', money(totalPeng), pdfReportDanger)),
            pw.SizedBox(width: 8),
            pw.Expanded(
                child: pdfReportSummaryCard('Saldo', money(saldo),
                    saldo >= 0 ? pdfReportSuccess : pdfReportDanger)),
          ]),
          pw.SizedBox(height: 18),
          _statementTable('Penerimaan', penerimaan, totalPen, money),
          pw.SizedBox(height: 16),
          _statementTable('Pengeluaran', pengeluaran, totalPeng, money),
        ],
      ),
    );
    return doc.save();
  }

  /// Summary-row CSV twin of the statement PDF: Indonesian headers, raw integer
  /// rupiah (spreadsheet-summable), a jemaat + period metadata block, then one
  /// row per category with per-section totals and the period saldo.
  Future<void> _shareCsv(
    Map<String, dynamic> orgConfig,
    DateTime start,
    DateTime end,
    Map<String, double> penerimaan,
    Map<String, double> pengeluaran,
  ) async {
    final jemaat = (orgConfig['jemaat_name'] as String?)?.trim();
    final name = jemaat == null || jemaat.isEmpty ? 'Gereja' : jemaat;
    final totalPen = penerimaan.values.fold<double>(0, (s, v) => s + v);
    final totalPeng = pengeluaran.values.fold<double>(0, (s, v) => s + v);

    List<MapEntry<String, double>> sorted(Map<String, double> m) =>
        m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final rows = <List<dynamic>>[
      ['Laporan Keuangan', name],
      ['Periode', _periodLabel(start, end)],
      [],
      ['Bagian', 'Kategori', 'Jumlah'],
      for (final e in sorted(penerimaan)) ['Penerimaan', e.key, e.value.round()],
      ['Penerimaan', 'Total Penerimaan', totalPen.round()],
      for (final e in sorted(pengeluaran))
        ['Pengeluaran', e.key, e.value.round()],
      ['Pengeluaran', 'Total Pengeluaran', totalPeng.round()],
      ['Saldo', 'Saldo Periode', (totalPen - totalPeng).round()],
    ];

    final slug = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    await shareCsvRows(rows, 'laporan_$slug');
  }

  /// One statement section: an underlined title, a styled two-column table
  /// (Kategori / Jumlah, biggest first), then a bold total line.
  static pw.Widget _statementTable(
    String title,
    Map<String, double> rows,
    double total,
    String Function(num) money,
  ) {
    final entries = rows.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pdfReportSectionTitle(title),
        pw.SizedBox(height: 6),
        if (entries.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text('—', style: const pw.TextStyle(fontSize: 10)),
          )
        else
          pw.TableHelper.fromTextArray(
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerRight,
            },
            headerStyle: pw.TextStyle(
                color: pdfReportMuted,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: pdfReportSurface),
            cellStyle: pw.TextStyle(color: pdfReportInk, fontSize: 10),
            cellPadding:
                const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            border: pw.TableBorder(
              horizontalInside:
                  pw.BorderSide(color: pdfReportSubtle, width: 0.5),
              top: pw.BorderSide(color: pdfReportSubtle, width: 0.5),
              bottom: pw.BorderSide(color: pdfReportSubtle, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(1.4),
            },
            headers: const ['Kategori', 'Jumlah'],
            data: [for (final e in entries) [e.key, money(e.value)]],
          ),
        pw.SizedBox(height: 6),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Total $title',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
              pw.Text(money(total),
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  static String _periodLabel(DateTime start, DateTime end) {
    final fmt = DateFormat('d MMM yyyy', 'id');
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }
}
