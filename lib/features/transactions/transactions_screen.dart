import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/selected_month_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/loit_banner.dart';
import '../../shared/widgets/loit_month_app_bar.dart';
import '../../shared/widgets/loit_chip.dart';
import '../../shared/widgets/loit_empty_state.dart';
import '../../shared/widgets/loit_fab_stack.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_tx_row.dart';

/// LOIT Transactions feed. Grouped by day, filter chips, search, multi-select.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  String _filter = 'all';

  // Multi-select
  bool _multiMode = false;
  final Set<String> _selected = {};

  void _toggleMulti(String? id) {
    if (id == null) return;
    setState(() {
      if (_selected.contains(id)) {
        _selected.remove(id);
        if (_selected.isEmpty) _multiMode = false;
      } else {
        _selected.add(id);
        _multiMode = true;
      }
    });
  }

  void _exitMulti() {
    setState(() {
      _multiMode = false;
      _selected.clear();
    });
  }

  Future<void> _bulkDelete() async {
    final notifier = ref.read(transactionsProvider.notifier);
    final ids = _selected.toList();
    _exitMulti();
    for (final id in ids) {
      try {
        await notifier.deleteTransaction(id);
      } catch (_) {}
    }
    await notifier.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final txns = ref.watch(transactionsProvider);
    final profile = ref.watch(userProfileProvider).value;
    final currency = profile?.homeCurrency ?? 'IDR';
    final month = ref.watch(selectedMonthProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: _multiMode
          ? _multiAppBar(context)
          : LoitMonthAppBar(
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, size: 20),
                  tooltip: 'Search',
                  onPressed: () => context.push('/transactions/search'),
                ),
                IconButton(
                  icon: const Icon(Icons.checklist_rounded, size: 20),
                  tooltip: 'Select',
                  onPressed: () => setState(() => _multiMode = true),
                ),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(transactionsProvider.notifier).refresh(),
        child: txns.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (items) {
            final monthItems = items.where((t) {
              final d = t.createdAt.toLocal();
              return d.year == month.year && d.month == month.month;
            }).toList();
            final filtered = _applyFilter(monthItems);

            if (filtered.isEmpty) {
              return ListView(
                children: [
                  _filterRow(),
                  const SizedBox(height: 24),
                  LoitEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: _filter == 'all'
                        ? 'No transactions yet'
                        : 'No $_filter transactions',
                    body: 'Add an expense or scan a receipt to get started.',
                    primaryCta: 'Add expense',
                    onPrimaryCta: () => context.push('/transactions/new'),
                    secondaryCta: 'Scan receipt',
                    onSecondaryCta: () => context.push('/scan'),
                  ),
                ],
              );
            }

            final grouped = _groupByDay(filtered);

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _filterRow()),
                if (_overBudgetCount(filtered) > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        LoitSpacing.s5,
                        LoitSpacing.s3,
                        LoitSpacing.s5,
                        LoitSpacing.s3,
                      ),
                      child: LoitBanner(
                        kind: LoitBannerKind.warning,
                        title:
                            '${_overBudgetCount(filtered)} categories trending high',
                        body: 'Tap a budget to drill down.',
                        actionLabel: 'View budgets',
                        onAction: () => context.push('/budgets'),
                      ),
                    ),
                  ),
                for (final entry in grouped.entries) ...[
                  SliverToBoxAdapter(
                    child: LoitGroupLabel(label: _dayLabel(entry.key)),
                  ),
                  SliverList.builder(
                    itemCount: entry.value.length,
                    itemBuilder: (_, i) {
                      final t = entry.value[i];
                      final selected = t.id != null && _selected.contains(t.id);
                      return LoitTxRow(
                        merchant: t.merchant ?? t.category ?? 'Transaction',
                        categoryKey: t.category,
                        subtitle: _txSubtitle(t),
                        amount: _fmt(t.amount, t.currency),
                        showDivider: i != entry.value.length - 1,
                        trailingBadge: _multiMode
                            ? Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 22,
                                color:
                                    selected ? c.brand : c.contentTertiary,
                              )
                            : null,
                        onTap: () {
                          if (_multiMode) {
                            _toggleMulti(t.id);
                          } else if (t.id != null) {
                            context.push('/transactions/${t.id}');
                          }
                        },
                      );
                    },
                  ),
                ],
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(LoitSpacing.s5),
                    child: Text(
                      '${filtered.length} of ${items.length} total · ${_fmt(_sum(filtered), currency)}',
                      style: LoitTypography.bodyS
                          .copyWith(color: c.contentTertiary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: _multiMode
          ? null
          : LoitFabStack(
              onPrimary: () => context.push('/transactions/new'),
              onSecondary: () => context.push('/scan'),
              primaryTooltip: 'Add expense',
              secondaryTooltip: 'Scan receipt',
              primaryIcon: Icons.add,
              secondaryIcon: Icons.document_scanner_outlined,
            ),
      bottomSheet: _multiMode ? _selectionBar(context) : null,
    );
  }

  PreferredSizeWidget _multiAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _exitMulti,
      ),
      title: Text('${_selected.length} selected'),
    );
  }

  Widget _selectionBar(BuildContext context) {
    final c = context.loitColors;
    return Material(
      color: c.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            LoitSpacing.s5,
            LoitSpacing.s3,
            LoitSpacing.s5,
            LoitSpacing.s3,
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  onPressed: _selected.isEmpty
                      ? null
                      : () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title:
                                  Text('Delete ${_selected.length} items?'),
                              content: const Text('This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true) await _bulkDelete();
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterRow() {
    const filters = ['all', 'dining', 'groceries', 'transport', 'shopping'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        LoitSpacing.s5,
        LoitSpacing.s4,
        LoitSpacing.s5,
        LoitSpacing.s3,
      ),
      child: Row(
        children: [
          for (final f in filters) ...[
            LoitChip(
              label: f == 'all' ? 'All' : _capitalize(f),
              selected: _filter == f,
              onTap: () => setState(() => _filter = f),
            ),
            const SizedBox(width: LoitSpacing.s3),
          ],
        ],
      ),
    );
  }

  List<Txn> _applyFilter(List<Txn> items) {
    if (_filter == 'all') return items;
    return items.where((t) => (t.category ?? '').toLowerCase() == _filter)
        .toList();
  }

  Map<DateTime, List<Txn>> _groupByDay(List<Txn> items) {
    final map = <DateTime, List<Txn>>{};
    for (final t in items) {
      final d = t.createdAt.toLocal();
      final key = DateTime(d.year, d.month, d.day);
      (map[key] ??= []).add(t);
    }
    return map;
  }

  int _overBudgetCount(List<Txn> _) => 0; // wired later via budgets_provider

  double _sum(List<Txn> items) =>
      items.fold(0.0, (s, t) => s + (t.amountHome ?? t.amount));

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (d == today) return 'Today';
    if (d == yesterday) return 'Yesterday';
    return DateFormat.MMMEd().format(d);
  }

  String _txSubtitle(Txn t) {
    final time = DateFormat.jm().format(t.createdAt.toLocal());
    final cat = (t.category ?? 'other');
    return '${_capitalize(cat)} · $time';
  }

  String _fmt(double v, String currency) {
    final fmt = NumberFormat.simpleCurrency(name: currency, decimalDigits: 0);
    return fmt.format(v);
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
