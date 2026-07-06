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
import '../rooms/church/church_realisasi_service.dart';
import '../rooms/church/church_report_service.dart';
import 'export_range.dart';
import 'export_service.dart';

enum _ExportFormat { csv, pdf }

/// What a church room produces: the default flat transaction listing, the
/// church financial statement (Laporan Keuangan), or the AI-classified
/// Laporan Realisasi Mata Anggaran (ADR 0026). Non-church surfaces only ever
/// produce [transactions]; the selector is church-only (ADR 0019).
enum _ExportType { transactions, statement, realisasi }

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
    final isRealisasi = type == _ExportType.realisasi;
    // Both church PDF reports (statement + realisasi) share pool+period scoping;
    // only the flat listing keeps the raw format/CSV controls.
    final isPdfReport = isStatement || isRealisasi;

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
    final statementTxns = isPdfReport
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
              decoration: BoxDecoration(
                color: c.surface,
                border: Border(bottom: BorderSide(color: c.borderSubtle)),
              ),
              child: Column(
                children: [
                  _TypeRow(
                    label: l10n.exportTypeTransactions,
                    selected: type == _ExportType.transactions,
                    onTap: () => setState(
                        () => _pickedType = _ExportType.transactions),
                  ),
                  Divider(
                      height: 1, indent: LoitSpacing.s4, color: c.borderSubtle),
                  _TypeRow(
                    label: l10n.exportTypeStatement,
                    selected: isStatement,
                    onTap: () =>
                        setState(() => _pickedType = _ExportType.statement),
                  ),
                  Divider(
                      height: 1, indent: LoitSpacing.s4, color: c.borderSubtle),
                  _TypeRow(
                    label: l10n.exportTypeRealisasi,
                    badge: 'AI',
                    selected: isRealisasi,
                    onTap: () =>
                        setState(() => _pickedType = _ExportType.realisasi),
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
          // Format selector shows for every type now — the two church reports
          // gained CSV twins, so CSV/PDF is a choice for all of them.
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
                loading: isPdfReport ? _statementBusy : isBusy,
                label: isRealisasi
                    ? '${l10n.exportStatementAction} · ${l10n.exportTypeRealisasi} (${statementTxns.length} ${l10n.exportScreenTransactions})'
                    : isStatement
                        ? '${l10n.exportStatementAction} (${statementTxns.length} ${l10n.exportScreenTransactions})'
                        : '${l10n.exportScreenExport} ${filtered.length} ${l10n.exportScreenTransactions}',
                onPressed: (isPdfReport
                        ? (_statementBusy || statementTxns.isEmpty)
                        : (filtered.isEmpty || isBusy))
                    ? null
                    : () => isRealisasi
                        ? _generateRealisasi(roomDetail, statementTxns, flags)
                        : isStatement
                            ? _generateStatement(
                                roomDetail, statementTxns, flags)
                            : _doExport(
                                filtered,
                                profile?.homeCurrency ?? 'IDR',
                                flags,
                                roomName,
                                accountSnapshots,
                              ),
              ),
              if (type == _ExportType.transactions && isBusy) ...[
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
  /// Report-CSV respects the [FeatureFlags.csvExport] gate exactly like Daftar
  /// Transaksi (moot for church — Pro has it — but kept consistent). Returns
  /// true (and opens the paywall) when a CSV export is not allowed.
  Future<bool> _csvGateBlocked(FeatureFlags flags) async {
    if (_format != _ExportFormat.csv || flags.csvExport) return false;
    await Analytics.paywallSeen('export');
    if (mounted) context.push('/paywall', extra: 'export');
    return true;
  }

  Future<void> _generateStatement(
    Map<String, dynamic>? roomDetail,
    List<Txn> statementTxns,
    FeatureFlags flags,
  ) async {
    if (await _csvGateBlocked(flags)) return;
    final asCsv = _format == _ExportFormat.csv;
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
        asCsv: asCsv,
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

  /// Laporan Realisasi Mata Anggaran (ADR 0026). Confirms the (estimated) AI
  /// Credit cost, runs the server classifier, then builds the PDF from the
  /// returned mapping. Stateless: every run re-classifies and re-charges.
  Future<void> _generateRealisasi(
    Map<String, dynamic>? roomDetail,
    List<Txn> statementTxns,
    FeatureFlags flags,
  ) async {
    if (await _csvGateBlocked(flags)) return;
    final asCsv = _format == _ExportFormat.csv;
    final nonTransfer =
        statementTxns.where((t) => !t.isTransfer && t.id != null).toList();
    if (nonTransfer.isEmpty) return;
    // Pre-call estimate only (~15 completion tokens/item / 1024 per credit).
    // The real charge is token-metered server-side and may differ (ADR 0017).
    final estCredits = (nonTransfer.length * 15 / 1024).ceil().clamp(1, 999);

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Laporan Realisasi?'),
        content: Text(
          'AI akan memetakan ${nonTransfer.length} transaksi ke mata anggaran '
          'GMIM. Perkiraan biaya ≈ $estCredits Kredit AI (biaya sebenarnya '
          'dihitung setelah AI selesai).',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Buat')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _statementBusy = true);
    try {
      final service = ChurchRealisasiService();
      final result = await service.classify(nonTransfer);

      final orgConfig =
          (roomDetail?['org_config'] as Map?)?.cast<String, dynamic>() ?? {};
      final baseCurrency = (roomDetail?['base_currency'] as String?) ?? 'IDR';
      await service.generateAndShare(
        orgConfig: orgConfig,
        baseCurrency: baseCurrency,
        start: _range.start,
        end: _range.end,
        txns: nonTransfer,
        mapping: result.mapping,
        asCsv: asCsv,
      );

      // Refresh the credits meter (the classifier spent the user's credits).
      ref.invalidate(userProfileProvider);
      if (mounted) {
        final remaining = result.creditsRemaining;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(remaining == null
              ? '${result.creditsCharged} Kredit AI terpakai.'
              : '${result.creditsCharged} Kredit AI terpakai · $remaining tersisa.'),
        ));
        context.pop();
      }
    } on RealisasiQuotaException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Kredit AI habis. Isi ulang untuk membuat laporan.')));
        await Analytics.paywallSeen('scan');
        if (mounted) context.push('/paywall', extra: 'scan');
      }
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

/// Single-select row for the church report type. A stacked list reads cleaner
/// one-handed than three cramped column tiles, and lets the long labels breathe
/// without wrapping. Format (CSV/PDF) is chosen separately below, so no sub.
class _TypeRow extends StatelessWidget {
  const _TypeRow({
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: LoitSpacing.s4, vertical: LoitSpacing.s4),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? c.brand : c.contentTertiary,
            ),
            const SizedBox(width: LoitSpacing.s3),
            Expanded(
              child: Text(label,
                  style: LoitTypography.bodyM.copyWith(
                    color: selected ? c.brand : c.contentPrimary,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: LoitSpacing.s2, vertical: 2),
                decoration: BoxDecoration(
                  color: c.muted,
                  borderRadius: LoitRadius.brS,
                ),
                child: Text(badge!,
                    style: LoitTypography.labelS
                        .copyWith(color: c.contentSecondary)),
              ),
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
