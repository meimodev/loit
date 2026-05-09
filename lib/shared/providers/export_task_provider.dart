import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/reports/export_service.dart';
import 'transactions_provider.dart';

sealed class ExportTaskState {
  const ExportTaskState();
}

class ExportTaskIdle extends ExportTaskState {
  const ExportTaskIdle();
}

class ExportTaskRunning extends ExportTaskState {
  const ExportTaskRunning({required this.label, required this.isPdf});
  final String label;
  final bool isPdf;
}

class ExportTaskReady extends ExportTaskState {
  const ExportTaskReady({required this.file, required this.isPdf});
  final File file;
  final bool isPdf;
}

class ExportTaskFailed extends ExportTaskState {
  const ExportTaskFailed(this.message);
  final String message;
}

class ExportTaskNotifier extends Notifier<ExportTaskState> {
  @override
  ExportTaskState build() => const ExportTaskIdle();

  bool get isRunning => state is ExportTaskRunning;

  Future<void> start({
    required List<Txn> transactions,
    required ExportScope scope,
    required bool isPdf,
  }) async {
    if (isRunning) return;
    state = ExportTaskRunning(label: scope.label, isPdf: isPdf);
    try {
      final svc = ExportService();
      final file = isPdf
          ? await svc.exportPdf(transactions, scope)
          : await svc.exportCsv(transactions, scope);
      state = ExportTaskReady(file: file, isPdf: isPdf);
    } catch (e) {
      state = ExportTaskFailed(e.toString());
    }
  }

  void consume() {
    state = const ExportTaskIdle();
  }
}

final exportTaskProvider =
    NotifierProvider<ExportTaskNotifier, ExportTaskState>(
  ExportTaskNotifier.new,
);
