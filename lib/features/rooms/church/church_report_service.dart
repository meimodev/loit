import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../shared/providers/transactions_provider.dart';
import '../../reports/export_service.dart' show formatMoney;

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

    final font = await PdfGoogleFonts.notoSansRegular();
    final bold = await PdfGoogleFonts.notoSansBold();

    String money(num v) => formatMoney(v, baseCurrency);
    final periodLabel = _periodLabel(start, end);

    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: bold),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          _header(orgConfig, periodLabel, bold),
          pw.SizedBox(height: 20),
          _section('PENERIMAAN', penerimaan, money, bold,
              totalLabel: 'Total Penerimaan'),
          pw.SizedBox(height: 16),
          _section('PENGELUARAN', pengeluaran, money, bold,
              totalLabel: 'Total Pengeluaran'),
          pw.SizedBox(height: 16),
          _saldoRow(
            penerimaan.values.fold<double>(0, (s, v) => s + v) -
                pengeluaran.values.fold<double>(0, (s, v) => s + v),
            money,
            bold,
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    final jemaat = (orgConfig['jemaat_name'] as String?)?.trim();
    final slug = (jemaat == null || jemaat.isEmpty ? 'gereja' : jemaat)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    await Printing.sharePdf(bytes: bytes, filename: 'laporan_$slug.pdf');
  }

  static pw.Widget _header(
      Map<String, dynamic> cfg, String period, pw.Font bold) {
    String? f(String k) {
      final v = cfg[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return null;
    }

    final jemaat = f('jemaat_name') ?? 'Gereja';
    final kota = f('kota_kabupaten');
    final phone = f('phone_number');
    final subLine = kota == null ? period : '$kota — $period';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text('LAPORAN KEUANGAN',
            style: pw.TextStyle(font: bold, fontSize: 16)),
        pw.SizedBox(height: 4),
        pw.Text(jemaat, style: pw.TextStyle(font: bold, fontSize: 13)),
        pw.SizedBox(height: 2),
        pw.Text(subLine, style: const pw.TextStyle(fontSize: 10)),
        if (phone != null) ...[
          pw.SizedBox(height: 2),
          pw.Text('Kontak: $phone',
              style: const pw.TextStyle(fontSize: 10)),
        ],
      ],
    );
  }

  static pw.Widget _section(
    String title,
    Map<String, double> rows,
    String Function(num) money,
    pw.Font bold, {
    required String totalLabel,
  }) {
    final entries = rows.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = rows.values.fold<double>(0, (s, v) => s + v);
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(width: 1)),
          ),
          child: pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 11)),
        ),
        pw.SizedBox(height: 6),
        if (entries.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Text('—', style: const pw.TextStyle(fontSize: 10)),
          ),
        for (final e in entries)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                    child: pw.Text(e.key,
                        style: const pw.TextStyle(fontSize: 10))),
                pw.Text(money(e.value),
                    style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        pw.SizedBox(height: 4),
        pw.Container(
          padding: const pw.EdgeInsets.only(top: 4),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(totalLabel, style: pw.TextStyle(font: bold, fontSize: 10)),
              pw.Text(money(total),
                  style: pw.TextStyle(font: bold, fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _saldoRow(
      double saldo, String Function(num) money, pw.Font bold) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Saldo Periode',
              style: pw.TextStyle(font: bold, fontSize: 11)),
          pw.Text(money(saldo), style: pw.TextStyle(font: bold, fontSize: 11)),
        ],
      ),
    );
  }

  static String _periodLabel(DateTime start, DateTime end) {
    final fmt = DateFormat('d MMM yyyy', 'id');
    return '${fmt.format(start)} – ${fmt.format(end)}';
  }
}
