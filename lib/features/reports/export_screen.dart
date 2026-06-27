import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/utils/locale_date_format.dart';

import '../../core/services/analytics_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/export_task_provider.dart';
import '../../shared/providers/room_accounts_provider.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/widgets/loit_button.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../paywall/feature_gate.dart';
import '../rooms/church/church_report_service.dart';
import 'export_range.dart';
import 'export_service.dart';

enum _ExportFormat { csv, pdf }

/// What a church room produces: the default flat transaction listing, or the
/// church financial statement (Laporan Keuangan). Non-church surfaces only ever
/// produce [transactions]; the selector is church-only (ADR 0019).
enum _ExportType { transactions, statement }

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key, this.roomId});

  final String? roomId;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  late DateTimeRange _range;
  _ExportFormat _format = _ExportFormat.csv;
  // Default range is the current month, which is exactly the `month` preset.
  ExportRangePreset _preset = ExportRangePreset.month;
  // Church-only: null until the user picks, so church defaults to [statement]
  // (its headline deliverable) without an initState provider read.
  _ExportType? _pickedType;
  // Statement generation runs locally with a button spinner (not the async
  // export-task banner the listing path uses).
  bool _statementBusy = false;

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
    final l10n = context.l10n;
    final roomId = widget.roomId;
    final txns = roomId != null
        ? (ref.watch(roomTransactionsProvider(roomId)).value ?? const [])
        : (ref.watch(transactionsProvider).value ?? const []);
    final profile = ref.watch(userProfileProvider).value;
    final tier = profile?.tier ?? 'free';
    final flags = FeatureFlags.forTier(tier);

    final roomDetail = roomId != null
        ? ref.watch(roomDetailProvider(roomId)).value
        : null;
    final roomName = roomDetail?['name'] as String?;
    final isChurch = (roomDetail?['org_type'] as String?) == 'church';
    // Church defaults to the statement; everything else is listing-only.
    final type = isChurch
        ? (_pickedType ?? _ExportType.statement)
        : _ExportType.transactions;
    final isStatement = type == _ExportType.statement;

    final rangeEnd = DateTime(
        _range.end.year, _range.end.month, _range.end.day, 23, 59, 59);
    final filtered = txns.where((t) =>
        !t.createdAt.isBefore(_range.start) &&
        !t.createdAt.isAfter(rangeEnd)).toList();

    // Church statement scope: pool-funded Room-account rows in the period.
    // Falls back to all rows if the room has no Room account yet, so a
    // statement still renders (mirrors the old ChurchReportScreen).
    final roomAccounts = isChurch
        ? (ref.watch(roomAccountsProvider(roomId!)).value ?? const [])
        : const [];
    final roomAccountIds = <String>{for (final a in roomAccounts) a.id as String};
    final statementTxns = isStatement
        ? statementScopedTxns(
            all: txns,
            roomAccountIds: roomAccountIds,
            start: _range.start,
            end: _range.end,
          )
        : const <Txn>[];

    final accounts = ref.watch(accountsProvider).value ?? const [];
    final balances = ref.watch(accountBalancesProvider);
    final accountSnapshots = [
      for (final a in accounts)
        if (a.archivedAt == null)
          AccountSnapshot(
            name: a.name,
            kind: a.kind,
            balanceHome: balances[a.id] ?? a.initialBalance,
          ),
    ];
    final exportState = ref.watch(exportTaskProvider);
    final isBusy = exportState is ExportTaskRunning;

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l10n.exportScreenTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final rid = widget.roomId;
          if (rid != null) {
            ref.invalidate(roomTransactionsProvider(rid));
            ref.invalidate(roomDetailProvider(rid));
            await ref.read(roomTransactionsProvider(rid).future);
          } else {
            await ref.read(transactionsProvider.notifier).refresh();
          }
          ref.invalidate(accountsProvider);
        },
        child: ListView(
        padding: const EdgeInsets.only(bottom: 120),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (isChurch) ...[
            LoitGroupLabel(label: l10n.exportTypeLabel),
            Container(
              padding: const EdgeInsets.fromLTRB(LoitSpacing.s4,
                  LoitSpacing.s3, LoitSpacing.s4, LoitSpacing.s4),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(bottom: BorderSide(color: c.borderSubtle)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _FormatTile(
                      label: l10n.exportTypeTransactions,
                      sub: 'CSV / PDF',
                      selected: !isStatement,
                      onTap: () => setState(
                          () => _pickedType = _ExportType.transactions),
                    ),
                  ),
                  const SizedBox(width: LoitSpacing.s3),
                  Expanded(
                    child: _FormatTile(
                      label: l10n.exportTypeStatement,
                      sub: 'PDF',
                      selected: isStatement,
                      onTap: () => setState(
                          () => _pickedType = _ExportType.statement),
                    ),
                  ),
                ],
              ),
            ),
          ],
          LoitGroupLabel(label: l10n.exportScreenDateRange),
          _PresetRow(
            selected: _preset,
            onPreset: _applyPreset,
            onCustom: _pickRange,
          ),
          _LineRow(
            label: l10n.exportScreenDateRange,
            value:
                '${yMMMd(context).format(_range.start)} — ${yMMMd(context).format(_range.end)}',
            onTap: _pickRange,
          ),
          if (!isStatement) ...[
            LoitGroupLabel(label: l10n.exportScreenFormat),
            Container(
              padding: const EdgeInsets.fromLTRB(LoitSpacing.s4,
                  LoitSpacing.s3, LoitSpacing.s4, LoitSpacing.s4),
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
          ],
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
                      l10n.exportScreenReady,
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
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(LoitSpacing.s4),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border(top: BorderSide(color: c.borderSubtle)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LoitButton.primary(
                size: LoitButtonSize.l,
                fullWidth: true,
                loading: isStatement ? _statementBusy : isBusy,
                label: isStatement
                    ? '${l10n.exportStatementAction} (${statementTxns.length} ${l10n.exportScreenTransactions})'
                    : '${l10n.exportScreenExport} ${filtered.length} ${l10n.exportScreenTransactions}',
                onPressed: (isStatement
                        ? _statementBusy
                        : (filtered.isEmpty || isBusy))
                    ? null
                    : () => isStatement
                        ? _generateStatement(roomDetail, statementTxns)
                        : _doExport(
                            filtered,
                            profile?.homeCurrency ?? 'IDR',
                            flags,
                            roomName,
                            accountSnapshots,
                          ),
              ),
              if (!isStatement && isBusy) ...[
                const SizedBox(height: LoitSpacing.s2),
                Text(
                  l10n.exportScreenExporting,
                  style: LoitTypography.bodyS
                      .copyWith(color: c.contentSecondary),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _applyPreset(ExportRangePreset p) {
    setState(() {
      _preset = p;
      _range = exportPresetRange(p, DateTime.now());
    });
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final lastDate = DateTime(now.year, now.month + 1, 0);
    final initial = DateTimeRange(
      start: _range.start.isBefore(DateTime(2020))
          ? DateTime(2020)
          : _range.start,
      end: _range.end.isAfter(lastDate) ? lastDate : _range.end,
    );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: lastDate,
      initialDateRange: initial,
    );
    if (picked != null) {
      setState(() {
        _range = picked;
        _preset = ExportRangePreset.custom;
      });
    }
  }

  /// Church financial statement (Laporan Keuangan). Reuses [ChurchReportService]
  /// verbatim; [statementTxns] is already period- and pool-scoped by the caller.
  Future<void> _generateStatement(
    Map<String, dynamic>? roomDetail,
    List<Txn> statementTxns,
  ) async {
    setState(() => _statementBusy = true);
    try {
      final orgConfig =
          (roomDetail?['org_config'] as Map?)?.cast<String, dynamic>() ?? {};
      final baseCurrency = (roomDetail?['base_currency'] as String?) ?? 'IDR';

      final cats = ref.read(userCategoriesProvider).value ?? const [];
      // Catch-all rows store English names localized elsewhere by suffix;
      // relabel them to the church terms (ADR 0021) for the statement.
      final categoryNames = <String, String>{
        for (final cat in cats)
          if (cat.roomId == widget.roomId)
            cat.key: cat.key.endsWith(':income_other')
                ? 'Penerimaan lain'
                : cat.key.endsWith(':other')
                    ? 'Lainnya'
                    : cat.name,
      };

      await ChurchReportService().generateAndShare(
        orgConfig: orgConfig,
        baseCurrency: baseCurrency,
        start: _range.start,
        end: _range.end,
        txns: statementTxns,
        categoryNames: categoryNames,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membuat laporan: $e')));
      }
    } finally {
      if (mounted) setState(() => _statementBusy = false);
    }
  }

  Future<void> _doExport(
    List<Txn> filtered,
    String home,
    FeatureFlags flags,
    String? roomName,
    List<AccountSnapshot> accounts,
  ) async {
    final l10n = context.l10n;
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
          SnackBar(
              content: Text(l10n.exportScreenFailed('PDF range exceeds 12 months'))),
        );
        return;
      }
    }
    final isRoom = widget.roomId != null;
    final scope = ExportScope(
      label: isRoom ? (roomName ?? 'Room') : 'Personal',
      isRoom: isRoom,
      start: _range.start,
      end: _range.end,
      homeCurrency: home,
      accounts: accounts,
    );
    unawaited(
      ref.read(exportTaskProvider.notifier).start(
            transactions: filtered,
            scope: scope,
            isPdf: isPdf,
          ),
    );
    if (mounted) context.pop();
  }
}

/// Quick preset chips above the custom range row. Tapping a preset fills the
/// range; the custom chip opens the picker. Shared by every export surface.
class _PresetRow extends StatelessWidget {
  const _PresetRow({
    required this.selected,
    required this.onPreset,
    required this.onCustom,
  });
  final ExportRangePreset selected;
  final ValueChanged<ExportRangePreset> onPreset;
  final VoidCallback onCustom;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          LoitSpacing.s4, LoitSpacing.s3, LoitSpacing.s4, LoitSpacing.s3),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.borderSubtle)),
      ),
      child: Wrap(
        spacing: LoitSpacing.s2,
        runSpacing: LoitSpacing.s2,
        children: [
          _PresetChip(
            label: l10n.exportPresetThisMonth,
            selected: selected == ExportRangePreset.month,
            onTap: () => onPreset(ExportRangePreset.month),
          ),
          _PresetChip(
            label: l10n.exportPresetThisQuarter,
            selected: selected == ExportRangePreset.quarter,
            onTap: () => onPreset(ExportRangePreset.quarter),
          ),
          _PresetChip(
            label: l10n.exportPresetThisYear,
            selected: selected == ExportRangePreset.year,
            onTap: () => onPreset(ExportRangePreset.year),
          ),
          _PresetChip(
            label: l10n.exportPresetCustom,
            selected: selected == ExportRangePreset.custom,
            onTap: onCustom,
          ),
        ],
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return InkWell(
      onTap: onTap,
      borderRadius: LoitRadius.brM,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: LoitSpacing.s3, vertical: LoitSpacing.s2),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6F4F0) : c.canvas,
          borderRadius: LoitRadius.brM,
          border: Border.all(
            color: selected ? c.brand : c.borderSubtle,
            width: 1.5,
          ),
        ),
        child: Text(label,
            style: LoitTypography.bodyS.copyWith(
              color: selected ? c.brand : c.contentPrimary,
              fontWeight: FontWeight.w600,
            )),
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.label,
    required this.value,
    this.onTap,
  });
  final String label;
  final String value;
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
                  color: c.contentPrimary,
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
