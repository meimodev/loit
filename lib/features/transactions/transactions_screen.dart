import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/selected_month_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/loit_banner.dart';
import '../../shared/widgets/loit_chip.dart';
import '../../shared/widgets/loit_month_app_bar.dart';
import '../../shared/widgets/loit_empty_state.dart';
import '../../shared/widgets/loit_fab_stack.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_stat_triple.dart';
import '../../shared/widgets/loit_tx_row.dart';
import '../rooms/room_colors.dart';
import 'notes_breakdown.dart';

/// Source filter applied to the transactions feed.
enum _SourceFilter { all, personal, rooms }

/// LOIT Transactions feed. Owns monthly summary (Income / Expenses / Total),
/// filter chips, grouped-by-day rows, search, and add/scan FABs.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  // Multi-select
  bool _multiMode = false;
  final Set<String> _selected = {};

  // Source filter (all / personal-only / rooms-only)
  _SourceFilter _sourceFilter = _SourceFilter.all;

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
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final txns = ref.watch(transactionsProvider);
    final profile = ref.watch(userProfileProvider).value;
    final currency = profile?.homeCurrency ?? 'IDR';
    final month = ref.watch(selectedMonthProvider);
    // Use full accountsProvider (includes archived) so archived-account transactions
    // still display their account label.
    final allAccounts = ref.watch(accountsProvider).value ?? const [];
    final accountMap = {for (final a in allAccounts) a.id: a};

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
            final filtered = monthItems.where((t) {
              switch (_sourceFilter) {
                case _SourceFilter.all:
                  return true;
                case _SourceFilter.personal:
                  return t.roomId == null;
                case _SourceFilter.rooms:
                  return t.roomId != null;
              }
            }).toList();

            // Monthly summary respects the active source filter so totals
            // reconcile with the rows visible below.
            var incomeSum = 0.0, expenseSum = 0.0;
            for (final t in filtered) {
              if (t.isTransfer) continue;
              final v = (t.amountHome ?? t.amount).abs();
              if (t.isIncome) {
                incomeSum += v;
              } else {
                expenseSum += v;
              }
            }
            final netTotal = incomeSum - expenseSum;
            final summaryTriple = LoitStatTriple(
              stats: [
                LoitStat(
                  label: 'Income',
                  amount: _fmt(incomeSum, currency),
                  color: c.info,
                ),
                LoitStat(
                  label: 'Expenses',
                  amount: _fmt(expenseSum, currency),
                  color: c.danger,
                ),
                LoitStat(
                  label: 'Total',
                  amount: _fmt(netTotal, currency),
                  color: netTotal >= 0 ? c.info : c.danger,
                ),
              ],
            );

            if (filtered.isEmpty) {
              final isFiltered = _sourceFilter != _SourceFilter.all;
              return ListView(
                children: [
                  summaryTriple,
                  _filterChips(context),
                  const SizedBox(height: 24),
                  LoitEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: isFiltered
                        ? 'No transactions match this filter'
                        : 'No transactions yet',
                    body: isFiltered
                        ? 'Try switching to All to see every transaction this month.'
                        : 'Add a transaction or scan a receipt to get started.',
                    primaryCta:
                        isFiltered ? 'Show all' : 'New transaction',
                    onPrimaryCta: isFiltered
                        ? () => setState(
                            () => _sourceFilter = _SourceFilter.all)
                        : () => context.push('/transactions/new'),
                    secondaryCta: isFiltered ? null : 'Scan receipt',
                    onSecondaryCta:
                        isFiltered ? null : () => context.push('/scan'),
                  ),
                ],
              );
            }

            final grouped = _groupByDay(filtered);
            final sortedDays = grouped.entries.toList()
              ..sort((a, b) => b.key.compareTo(a.key));

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: summaryTriple),
                SliverToBoxAdapter(child: _filterChips(context)),
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
                for (final entry in sortedDays) ...[
                  SliverToBoxAdapter(
                    child: LoitGroupLabel(
                      label: _dayLabel(entry.key),
                      trailing: _dayTotalsTrailing(
                        context,
                        _dayTotals(entry.value),
                        currency,
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: entry.value.length,
                    itemBuilder: (_, i) {
                      final t = entry.value[i];
                      final selected = t.id != null && _selected.contains(t.id);
                      final fromName = t.accountId != null
                          ? accountMap[t.accountId]?.name
                          : null;
                      final toName = t.toAccountId != null
                          ? accountMap[t.toAccountId]?.name
                          : null;
                      final accountLabel =
                          t.isTransfer && fromName != null && toName != null
                          ? '$fromName → $toName'
                          : fromName;
                      // Trailing badge keeps only the sync indicator. Multi-
                      // select checkbox slides in from the leading edge.
                      final Widget? badgeChild = t.id == null
                          ? const _SyncBadge(key: ValueKey('sync'))
                          : null;
                      final animatedBadge = AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        transitionBuilder: (child, anim) => ScaleTransition(
                          scale: anim,
                          child: FadeTransition(opacity: anim, child: child),
                        ),
                        child: badgeChild ??
                            const SizedBox.shrink(key: ValueKey('none')),
                      );
                      final leadingSelector = _multiMode
                          ? Padding(
                              key: ValueKey(
                                  selected ? 'sel-check' : 'sel-radio'),
                              padding: const EdgeInsets.only(
                                  left: LoitSpacing.s5, right: LoitSpacing.s2),
                              child: Icon(
                                selected
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                size: 22,
                                color: selected
                                    ? c.brand
                                    : c.contentTertiary,
                              ),
                            )
                          : null;
                      final isRoomTx = t.roomId != null;
                      final roomAccent = isRoomTx
                          ? RoomColors.forId(t.roomId!)
                          : null;
                      final roomBadge = isRoomTx
                          ? _RoomOriginBadge(
                              accent: roomAccent!,
                              name: t.roomName ?? 'Room',
                            )
                          : null;
                      final row = LoitTxRow(
                        title: breakdownTitle(t.notes),
                        categoryKey: t.isTransfer ? null : t.category,
                        subtitle: _txSubtitle(t),
                        amount: _fmt(t.amount, t.currency),
                        isIncome: t.isIncome,
                        isTransfer: t.isTransfer,
                        accountLabel: accountLabel,
                        showDivider: i != entry.value.length - 1,
                        trailingBadge: animatedBadge,
                        leadingSelector: leadingSelector,
                        roomBadge: roomBadge,
                        accentStripeColor: roomAccent,
                        onTap: () {
                          if (_multiMode) {
                            _toggleMulti(t.id);
                          } else if (isRoomTx) {
                            // Room-inherited txn: jump to the room detail
                            // rather than the personal txn detail.
                            context.push('/rooms/${t.roomId}');
                          } else if (t.id != null) {
                            context.push('/transactions/${t.id}');
                          } else {
                            context.push('/transactions/pending', extra: t);
                          }
                        },
                        onLongPress: t.id == null
                            ? null
                            : () {
                                HapticFeedback.mediumImpact();
                                if (!_multiMode) {
                                  setState(() {
                                    _multiMode = true;
                                    _selected.add(t.id!);
                                  });
                                } else {
                                  _toggleMulti(t.id);
                                }
                              },
                      );
                      // Selection tint with smooth bg transition.
                      final tinted = AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        color: selected
                            ? c.brand.withValues(alpha: 0.08)
                            : Colors.transparent,
                        child: row,
                      );
                      // Swipe-to-delete only when not in multi-select and the
                      // row has been synced (has id). Unsynced rows can't be
                      // deleted server-side yet.
                      if (_multiMode || t.id == null) return tinted;
                      return Dismissible(
                        key: ValueKey('tx-${t.id}'),
                        direction: DismissDirection.endToStart,
                        background: _swipeDeleteBackground(c),
                        onDismissed: (_) => _deleteWithUndo(t),
                        child: tinted,
                      );
                    },
                  ),
                ],
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(LoitSpacing.s5),
                    child: Text(
                      '${filtered.length} of ${items.length} total · ${_fmt(_sum(filtered), currency)}',
                      style: LoitTypography.bodyS.copyWith(
                        color: c.contentTertiary,
                      ),
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
              primaryTooltip: 'New transaction',
              primaryIcon: Icons.add,
            ),
      bottomNavigationBar: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, anim) => SizeTransition(
          sizeFactor: anim,
          axisAlignment: -1,
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: _multiMode
            ? _selectionBar(context)
            : const SizedBox.shrink(key: ValueKey('no-bar')),
      ),
    );
  }

  Widget _swipeDeleteBackground(LoitColors c) {
    return Container(
      color: c.danger,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: LoitSpacing.s5),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.delete_outline, color: Colors.white),
          SizedBox(width: LoitSpacing.s2),
          Text('Delete', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _deleteWithUndo(Txn t) async {
    final id = t.id;
    if (id == null) return;
    final notifier = ref.read(transactionsProvider.notifier);
    try {
      await notifier.deleteTransaction(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
      return;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> ctrl;
    ctrl = messenger.showSnackBar(
      SnackBar(
        content: const Text('Transaction deleted'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            ctrl.close();
            final payload = <String, dynamic>{
              'amount': t.amount,
              'currency': t.currency,
              if (t.amountHome != null) 'amount_home_currency': t.amountHome,
              if (t.fxRate != null) 'fx_rate': t.fxRate,
              'type': t.type,
              if (t.accountId != null) 'account_id': t.accountId,
              if (t.toAccountId != null) 'to_account_id': t.toAccountId,
              if (t.category != null) 'category': t.category,
              if (t.notes != null) 'notes': t.notes,
              'ai_parsed': t.aiParsed,
              'is_manual_fallback': t.isManualFallback,
              'created_at': t.createdAt.toUtc().toIso8601String(),
              if (t.roomId != null) 'room_id': t.roomId,
            };
            try {
              await notifier.addTransaction(payload);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Undo failed: $e')),
                );
              }
            }
          },
        ),
      ),
    );
    // Backstop timer: Flutter disables SnackBar auto-dismiss when accessible
    // navigation (e.g. TalkBack) is on. Force-close after the same duration
    // so the toast never lingers.
    Timer(const Duration(seconds: 3), () {
      try {
        ctrl.close();
      } catch (_) {}
    });
  }

  PreferredSizeWidget _multiAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.close), onPressed: _exitMulti),
      title: Text('${_selected.length} selected'),
    );
  }

  Widget _selectionBar(BuildContext context) {
    final c = context.loitColors;
    return Material(
      key: const ValueKey('select-bar'),
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
                          final count = _selected.length;
                          final ok = await showDialog<bool>(
                            context: context,
                            useRootNavigator: true,
                            builder: (dialogCtx) => AlertDialog(
                              title: Text('Delete $count items?'),
                              content: const Text('This cannot be undone.'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, false),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (ok == true && mounted) await _bulkDelete();
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

  ({double income, double expense}) _dayTotals(List<Txn> items) {
    var income = 0.0, expense = 0.0;
    for (final t in items) {
      if (t.isTransfer) continue;
      final v = (t.amountHome ?? t.amount).abs();
      if (t.isIncome) {
        income += v;
      } else {
        expense += v;
      }
    }
    return (income: income, expense: expense);
  }

  Widget _filterChips(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LoitSpacing.s5,
        LoitSpacing.s2,
        LoitSpacing.s5,
        LoitSpacing.s2,
      ),
      child: Row(
        children: [
          LoitChip(
            label: 'All',
            selected: _sourceFilter == _SourceFilter.all,
            onTap: () =>
                setState(() => _sourceFilter = _SourceFilter.all),
          ),
          const SizedBox(width: LoitSpacing.s2),
          LoitChip(
            label: 'Personal',
            leading: Icons.person_outline,
            selected: _sourceFilter == _SourceFilter.personal,
            onTap: () =>
                setState(() => _sourceFilter = _SourceFilter.personal),
          ),
          const SizedBox(width: LoitSpacing.s2),
          LoitChip(
            label: 'Rooms',
            leading: Icons.groups_outlined,
            selected: _sourceFilter == _SourceFilter.rooms,
            onTap: () =>
                setState(() => _sourceFilter = _SourceFilter.rooms),
          ),
        ],
      ),
    );
  }

  Widget? _dayTotalsTrailing(
    BuildContext context,
    ({double income, double expense}) totals,
    String currency,
  ) {
    if (totals.income == 0 && totals.expense == 0) return null;
    final c = context.loitColors;
    final net = totals.income - totals.expense;
    final color = net >= 0 ? c.info : c.danger;
    final sign = net > 0 ? '+' : (net < 0 ? '−' : '');
    return Text(
      '$sign${_fmt(net.abs(), currency)}',
      style: LoitTypography.labelS.copyWith(color: color),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Tooltip(
      message: 'Not synced',
      child: Icon(Icons.cloud_off_rounded, size: 16, color: c.warning),
    );
  }
}

/// Compact pill rendered below the transaction subtitle to surface the
/// originating room. Tinted by the room's accent so the row reads as
/// "inherited from room" at a glance.
class _RoomOriginBadge extends StatelessWidget {
  const _RoomOriginBadge({required this.accent, required this.name});

  final Color accent;
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: LoitTypography.labelS.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
