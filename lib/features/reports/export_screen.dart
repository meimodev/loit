import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/services/analytics_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/loit_button.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../paywall/feature_gate.dart';
import 'export_service.dart';

enum _ExportFormat { csv, pdf }

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  late DateTimeRange _range;
  _ExportFormat _format = _ExportFormat.csv;
  bool _includeReceipts = true;
  bool _includeCategories = true;
  bool _includeNotes = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _range = DateTimeRange(
      start: DateTime(now.year, now.month, 1),
      end: DateTime(now.year, now.month + 1, 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final txns = ref.watch(transactionsProvider).value ?? const [];
    final profile = ref.watch(userProfileProvider).value;
    final tier = profile?.tier ?? 'free';
    final flags = FeatureFlags.forTier(tier);
    final filtered = txns.where((t) =>
        !t.createdAt.isBefore(_range.start) &&
        !t.createdAt.isAfter(_range.end)).toList();

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Export'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        children: [
          const LoitGroupLabel(label: 'Period'),
          _LineRow(
            label: 'Range',
            value:
                '${DateFormat.yMMMd().format(_range.start)} — ${DateFormat.yMMMd().format(_range.end)}',
            onTap: _pickRange,
          ),
          _LineRow(
            label: 'Compare to',
            value: 'Off',
            valueColor: c.contentTertiary,
            onTap: null,
          ),
          const LoitGroupLabel(label: 'Format'),
          Container(
            padding: const EdgeInsets.fromLTRB(
                LoitSpacing.s4, LoitSpacing.s3, LoitSpacing.s4, LoitSpacing.s4),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(bottom: BorderSide(color: c.borderSubtle)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FormatTile(
                    label: 'CSV',
                    sub: 'data',
                    selected: _format == _ExportFormat.csv,
                    onTap: () =>
                        setState(() => _format = _ExportFormat.csv),
                  ),
                ),
                const SizedBox(width: LoitSpacing.s3),
                Expanded(
                  child: _FormatTile(
                    label: 'PDF',
                    sub: flags.pdfExport ? 'report' : 'Pro',
                    selected: _format == _ExportFormat.pdf,
                    onTap: () =>
                        setState(() => _format = _ExportFormat.pdf),
                  ),
                ),
              ],
            ),
          ),
          const LoitGroupLabel(label: 'Include'),
          _CheckRow(
            label: 'All transactions',
            value: true,
            onChanged: null,
          ),
          _CheckRow(
            label: 'Receipts',
            value: _includeReceipts,
            onChanged: (v) =>
                setState(() => _includeReceipts = v),
          ),
          _CheckRow(
            label: 'Categories',
            value: _includeCategories,
            onChanged: (v) =>
                setState(() => _includeCategories = v),
          ),
          _CheckRow(
            label: 'Notes',
            value: _includeNotes,
            onChanged: (v) => setState(() => _includeNotes = v),
            isLast: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                LoitSpacing.s4, LoitSpacing.s4, LoitSpacing.s4, 0),
            child: Container(
              padding: const EdgeInsets.all(LoitSpacing.s3),
              decoration: BoxDecoration(
                color: c.muted,
                borderRadius: LoitRadius.brM,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: c.brand),
                  const SizedBox(width: LoitSpacing.s2),
                  Expanded(
                    child: Text(
                      'Export shared via system sheet. Files larger than 10 MB are linked.',
                      style: LoitTypography.bodyS
                          .copyWith(color: c.contentSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(LoitSpacing.s4),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(top: BorderSide(color: c.borderSubtle)),
          ),
          child: LoitButton.primary(
            size: LoitButtonSize.l,
            fullWidth: true,
            loading: _busy,
            label: 'Export ${filtered.length} transactions',
            onPressed: filtered.isEmpty || _busy
                ? null
                : () => _doExport(filtered, profile?.homeCurrency ?? 'IDR', flags),
          ),
        ),
      ),
    );
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _range,
    );
    if (picked != null) setState(() => _range = picked);
  }

  Future<void> _doExport(
    List<Txn> filtered,
    String home,
    FeatureFlags flags,
  ) async {
    final isPdf = _format == _ExportFormat.pdf;
    final allowed = isPdf ? flags.pdfExport : flags.csvExport;
    if (!allowed) {
      await Analytics.paywallSeen('export');
      if (mounted) context.push('/paywall', extra: 'export');
      return;
    }
    if (isPdf) {
      final months = (_range.end.year - _range.start.year) * 12 +
          (_range.end.month - _range.start.month);
      if (months > ExportService.maxPdfMonths) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('PDF range exceeds 12 months — pick a smaller range')),
        );
        return;
      }
    }
    setState(() => _busy = true);
    try {
      final svc = ExportService();
      final file = isPdf
          ? await svc.exportPdf(
              filtered,
              home,
              filtered.fold<double>(
                  0, (s, t) => s + (t.amountHome ?? t.amount)),
            )
          : await svc.exportCsv(filtered);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: isPdf ? 'LOIT report' : 'LOIT export',
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: LoitSpacing.s4, vertical: LoitSpacing.s4),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(bottom: BorderSide(color: c.borderSubtle)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: LoitTypography.bodyM
                      .copyWith(color: c.contentPrimary)),
            ),
            Text(value,
                style: LoitTypography.bodyM.copyWith(
                  color: valueColor ?? c.contentPrimary,
                  fontWeight: FontWeight.w600,
                )),
            if (onTap != null) ...[
              const SizedBox(width: LoitSpacing.s2),
              Icon(Icons.chevron_right,
                  size: 18, color: c.contentTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

class _FormatTile extends StatelessWidget {
  const _FormatTile({
    required this.label,
    required this.sub,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return InkWell(
      onTap: onTap,
      borderRadius: LoitRadius.brM,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s4),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6F4F0) : c.canvas,
          borderRadius: LoitRadius.brM,
          border: Border.all(
            color: selected ? c.brand : c.borderSubtle,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(label,
                style: LoitTypography.bodyM.copyWith(
                  color: selected ? c.brand : c.contentPrimary,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 2),
            Text(sub,
                style: LoitTypography.bodyS
                    .copyWith(color: c.contentSecondary)),
          ],
        ),
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final disabled = onChanged == null;
    return InkWell(
      onTap: disabled ? null : () => onChanged!(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: LoitSpacing.s4, vertical: LoitSpacing.s3),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(
              bottom: isLast
                  ? BorderSide.none
                  : BorderSide(color: c.borderSubtle)),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              onChanged: disabled ? null : (v) => onChanged!(v ?? false),
            ),
            const SizedBox(width: LoitSpacing.s2),
            Expanded(
              child: Text(label,
                  style: LoitTypography.bodyM
                      .copyWith(color: c.contentPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}
