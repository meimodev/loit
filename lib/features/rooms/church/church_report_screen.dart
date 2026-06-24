import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/loit_colors.dart';
import '../../../core/theme/loit_radius.dart';
import '../../../core/theme/loit_spacing.dart';
import '../../../core/theme/loit_typography.dart';
import '../../../shared/providers/room_accounts_provider.dart';
import '../../../shared/providers/room_providers.dart';
import '../../../shared/providers/transactions_provider.dart';
import '../../../shared/providers/user_categories_provider.dart';
import '../../../shared/widgets/loit_button.dart';
import 'church_report_service.dart';

enum _Period { month, quarter, year }

/// Church financial statement entry: pick a period, generate the PDF, share.
/// Reachable only from a church room (ADR 0019).
///
// ponytail: copy hardcoded Indonesian — church domain is Indonesian-only.
class ChurchReportScreen extends ConsumerStatefulWidget {
  const ChurchReportScreen({super.key, required this.roomId});
  final String roomId;

  @override
  ConsumerState<ChurchReportScreen> createState() => _ChurchReportScreenState();
}

class _ChurchReportScreenState extends ConsumerState<ChurchReportScreen> {
  _Period _period = _Period.month;
  bool _busy = false;

  (DateTime, DateTime) _range() {
    final now = DateTime.now();
    switch (_period) {
      case _Period.month:
        return (DateTime(now.year, now.month, 1),
            DateTime(now.year, now.month + 1, 0));
      case _Period.quarter:
        final q = ((now.month - 1) ~/ 3) * 3 + 1;
        return (DateTime(now.year, q, 1), DateTime(now.year, q + 3, 0));
      case _Period.year:
        return (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(title: const Text('Laporan Keuangan')),
      body: ListView(
        padding: const EdgeInsets.all(LoitSpacing.s4),
        children: [
          Text('PERIODE',
              style: LoitTypography.labelS
                  .copyWith(color: c.contentSecondary, letterSpacing: 0.5)),
          const SizedBox(height: LoitSpacing.s2),
          _periodTile(_Period.month, 'Bulan Ini'),
          _periodTile(_Period.quarter, 'Triwulan Ini'),
          _periodTile(_Period.year, 'Tahun Ini'),
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
            label: 'Generate PDF',
            onPressed: _busy ? null : _generate,
          ),
        ),
      ),
    );
  }

  Widget _periodTile(_Period p, String label) {
    final c = context.loitColors;
    final selected = _period == p;
    return Padding(
      padding: const EdgeInsets.only(bottom: LoitSpacing.s2),
      child: InkWell(
        borderRadius: LoitRadius.brM,
        onTap: () => setState(() => _period = p),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: LoitSpacing.s4, vertical: LoitSpacing.s3),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: LoitRadius.brM,
            border: Border.all(
                color: selected ? c.brand : c.borderSubtle,
                width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 20,
                  color: selected ? c.brand : c.contentTertiary),
              const SizedBox(width: LoitSpacing.s3),
              Text(label,
                  style:
                      LoitTypography.bodyM.copyWith(color: c.contentPrimary)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generate() async {
    setState(() => _busy = true);
    try {
      final roomId = widget.roomId;
      final room = ref.read(roomDetailProvider(roomId)).value;
      final orgConfig =
          (room?['org_config'] as Map?)?.cast<String, dynamic>() ?? {};
      final baseCurrency = (room?['base_currency'] as String?) ?? 'IDR';

      final accounts =
          ref.read(roomAccountsProvider(roomId)).value ?? const [];
      final roomAccountIds = {for (final a in accounts) a.id};

      final allTxns =
          ref.read(roomTransactionsProvider(roomId)).value ?? const <Txn>[];
      final (start, end) = _range();
      final endExclusive = end.add(const Duration(days: 1));

      // Pool-funded movements in the period. If the room has no Room account
      // yet, fall back to all income/expense rows so a report still renders.
      final txns = allTxns.where((t) {
        final ts = t.createdAt.toLocal();
        if (ts.isBefore(start) || !ts.isBefore(endExclusive)) return false;
        if (roomAccountIds.isEmpty) return true;
        return t.accountId != null && roomAccountIds.contains(t.accountId);
      }).toList();

      final cats = ref.read(userCategoriesProvider).value ?? const [];
      final categoryNames = <String, String>{
        for (final cat in cats)
          if (cat.roomId == roomId) cat.key: cat.name,
      };

      await ChurchReportService().generateAndShare(
        orgConfig: orgConfig,
        baseCurrency: baseCurrency,
        start: start,
        end: end,
        txns: txns,
        categoryNames: categoryNames,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal membuat laporan: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
