import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../shared/providers/transactions_provider.dart';

class ExportService {
  static const int maxPdfMonths = 12;

  Future<File> exportCsv(List<Txn> transactions) async {
    final rows = <List<dynamic>>[
      ['Date', 'Merchant', 'Amount', 'Currency', 'Category', 'Notes'],
      ...transactions.map((t) => [
            t.createdAt.toIso8601String(),
            t.merchant ?? '',
            t.amount,
            t.currency,
            t.category ?? '',
            t.notes ?? '',
          ]),
    ];
    final csvString = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/loit_export_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    return file.writeAsString(csvString);
  }

  /// [transactions] must span at most [maxPdfMonths] months — enforce in UI.
  Future<File> exportPdf(
    List<Txn> transactions,
    String homeCurrency,
    double totalHome,
  ) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (ctx) => [
          pw.Header(level: 0, text: 'LOIT — Expense Report'),
          pw.Text('Total: ${totalHome.toStringAsFixed(2)} $homeCurrency'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: const ['Date', 'Merchant', 'Amount', 'Category'],
            data: transactions
                .map((t) => [
                      t.createdAt.toIso8601String().substring(0, 10),
                      t.merchant ?? '',
                      '${t.amount} ${t.currency}',
                      t.category ?? '',
                    ])
                .toList(),
          ),
        ],
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/loit_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
    return file.writeAsBytes(await doc.save());
  }
}
