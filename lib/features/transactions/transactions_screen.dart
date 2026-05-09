import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/selected_month_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/loit_banner.dart';
import '../../shared/widgets/loit_month_app_bar.dart';
import '../../shared/widgets/loit_empty_state.dart';
import '../../shared/widgets/loit_fab_stack.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_room_origin_badge.dart';
import '../../shared/widgets/loit_sheet.dart';
import '../../shared/widgets/loit_stat_triple.dart';
import '../../shared/widgets/loit_tx_row.dart';
import '../rooms/room_colors.dart';
import 'notes_breakdown.dart';

enum _SourceFilter { all, personal, rooms }

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key, this.highlightTxId});
  final String? highlightTxId;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  _SourceFilter _sourceFilter = _SourceFilter.all;

  String? _pendingScrollTxId;
  bool _scrollScheduled = false;
  final GlobalKey _highlightRowKey = GlobalKey(debugLabel: 'tx-highlight-row');

  @override
  void initState() {
    super.initState();
    _pendingScrollTxId = widget.highlightTxId;
  }

  void _maybeScrollToHighlight() {
    if (_pendingScrollTxId == null || _scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _highlightRowKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOut,
          alignment: 0.3,
        );
      }
      if (mounted) setState(() => _pendingScrollTxId = null);
    });
  }

  void _showRoomDeleteRedirect(Txn t) {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final roomName = t.roomName ?? l.txListRoom;
    final roomId = t.roomId;
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(l.txListRoomDeleteSnackbar(roomName)),
        action: roomId == null
            ? null
            : SnackBarAction(
                label: l.txListOpenRoom,
                onPressed: () =>
                    context.go('/rooms/$roomId?highlight=${t.id}'),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final txns = ref.watch(transactionsProvider);
    final profile = ref.watch(userProfileProvider).value;
    final currency = profile?.homeCurrency ?? 'IDR';
    final month = ref.watch(selectedMonthProvider);
    final allAccounts = ref.watch(accountsProvider).value ?? const [];
    final accountMap = {for (final a in allAccounts) a.id: a};
    final myRooms = ref.watch(myRoomsProvider).value ?? const [];
    final roomNameById = <String, String>{
      for (final r in myRooms)
        if (r['id'] is String && r['name'] is String)
          r['id'] as String: r['name'] as String,
    };

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: LoitMonthAppBar(
        actions: [
          _buildFilterAction(context),
          IconButton(
            icon: const Icon(Icons.search, size: 20),
            tooltip: l.txListSearch,
            onPressed: () => context.push('/transactions/search'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(transactionsProvider.notifier).refresh(),
        child: txns.when(
          skipLoadingOnReload: true,
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (items) {
            _maybeScrollToHighlight();
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

            var incomeSum = 0.0, expenseSum = 0.0;
            for (final t in filtered) {
              if (t.isTransfer) continue;
              final v = t.absAmountIn(currency);
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
                  label: l.txListIncome,
                  amount: _fmt(incomeSum, currency),
                  color: c.info,
                ),
                LoitStat(
                  label: l.txListExpenses,
                  amount: _fmt(expenseSum, currency),
                  color: c.danger,
                ),
                LoitStat(
                  label: l.txListTotal,
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
                  const SizedBox(height: 24),
                  LoitEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: isFiltered
                        ? l.txListNoMatches
                        : l.txListNoTransactions,
                    body: isFiltered
                        ? l.txListEmptySwitchAll
                        : l.txListEmptyAddTransaction,
                    primaryCta:
                        isFiltered ? l.txListShowAll : l.txListNewTransaction,
                    onPrimaryCta: isFiltered
                        ? () => setState(
                            () => _sourceFilter = _SourceFilter.all)
                        : () => context.push('/transactions/new'),
                    secondaryCta: isFiltered ? null : l.txListEmptyScanReceipt,
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
                        title: l.txListCategoriesTrending(
                            _overBudgetCount(filtered)),
                        body: l.txListTapBudget,
                        actionLabel: l.txListViewBudgets,
                        onAction: () => context.push('/budgets'),
                      ),
                    ),
                  ),
                for (final entry in sortedDays) ...[
                  SliverToBoxAdapter(
                    child: LoitGroupLabel(
                      label: _dayLabel(l, entry.key),
                      trailing: _dayTotalsTrailing(
                        context,
                        _dayTotals(entry.value, currency),
                        currency,
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: entry.value.length,
                    itemBuilder: (_, i) {
                      final t = entry.value[i];
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
                      final isRoomTx = t.roomId != null;
                      final roomAccent = isRoomTx
                          ? RoomColors.forId(t.roomId!)
                          : null;
                      final roomBadge = isRoomTx
                          ? LoitRoomOriginBadge(
                              accent: roomAccent!,
                              name: t.roomName ??
                                  roomNameById[t.roomId!] ??
                                  l.txListRoom,
                            )
                          : null;
                      final row = LoitTxRow(
                        title: breakdownTitle(t.notes),
                        categoryKey: t.isTransfer ? null : t.category,
                        subtitle: _txSubtitle(t),
                        amount: _fmt(t.amount, t.currency),
                        subAmount: (t.currency != currency &&
                                t.fxSnapshot.containsKey(currency))
                            ? '≈ ${_fmt(t.absAmountIn(currency), currency)}'
                            : null,
                        isIncome: t.isIncome,
                        isTransfer: t.isTransfer,
                        accountLabel: accountLabel,
                        showDivider: i != entry.value.length - 1,
                        trailingBadge: animatedBadge,
                        roomBadge: roomBadge,
                        accentStripeColor: roomAccent,
                        onTap: () {
                          if (isRoomTx) {
                            final qp = <String, String>{
                              'from': 'transactions',
                              if (t.id != null) 'highlight': t.id!,
                            };
                            final qs = qp.entries
                                .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
                                .join('&');
                            context.go('/rooms/${t.roomId}?$qs');
                          } else if (t.id != null) {
                            context.push('/transactions/${t.id}');
                          } else {
                            context.push('/transactions/pending', extra: t);
                          }
                        },
                      );
                      final bool isHighlight = widget.highlightTxId != null &&
                          t.id != null &&
                          widget.highlightTxId == t.id;
                      final Widget rowOrFlash = isHighlight
                          ? _TxFlashWrapper(
                              key: _highlightRowKey,
                              tint: c.brand,
                              child: row,
                            )
                          : row;
                      if (t.id == null) return rowOrFlash;
                      if (t.roomId != null) {
                        return Dismissible(
                          key: ValueKey('tx-${t.id}'),
                          direction: DismissDirection.endToStart,
                          background: _swipeDeleteBackground(c, l),
                          confirmDismiss: (_) async {
                            _showRoomDeleteRedirect(t);
                            return false;
                          },
                          child: rowOrFlash,
                        );
                      }
                      return Dismissible(
                        key: ValueKey('tx-${t.id}'),
                        direction: DismissDirection.endToStart,
                        background: _swipeDeleteBackground(c, l),
                        onDismissed: (_) => _deleteWithUndo(t),
                        child: rowOrFlash,
                      );
                    },
                  ),
                ],
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(LoitSpacing.s5),
                    child: Text(
                      '${l.txListFooter(filtered.length, items.length)} · ${_fmt(_sum(filtered, currency), currency)}',
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
      floatingActionButton: LoitFabStack(
        onPrimary: () => context.push('/transactions/new'),
        primaryTooltip: l.txListNewTransaction,
        primaryIcon: Icons.add,
      ),
    );
  }

  Widget _swipeDeleteBackground(LoitColors c, AppLocalizations l) {
    return Container(
      color: c.danger,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: LoitSpacing.s5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.delete_outline, color: Colors.white),
          const SizedBox(width: LoitSpacing.s2),
          Text(l.txListDelete, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Future<void> _deleteWithUndo(Txn t) async {
    final l = context.l10n;
    final id = t.id;
    if (id == null) return;
    final notifier = ref.read(transactionsProvider.notifier);
    try {
      await notifier.deleteTransaction(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.txListDeleteFailed(e.toString()))));
      }
      return;
    }
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    late ScaffoldFeatureController<SnackBar, SnackBarClosedReason> ctrl;
    ctrl = messenger.showSnackBar(
      SnackBar(
        content: Text(l.txListDeleted),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: l.txListUndo,
          onPressed: () async {
            ctrl.close();
            final payload = <String, dynamic>{
              'amount': t.amount,
              'currency': t.currency,
              'fx_snapshot': t.fxSnapshot,
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
                  SnackBar(content: Text(l.txListUndoFailed(e.toString()))),
                );
              }
            }
          },
        ),
      ),
    );
    Timer(const Duration(seconds: 3), () {
      try {
        ctrl.close();
      } catch (_) {}
    });
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

  int _overBudgetCount(List<Txn> _) => 0;

  double _sum(List<Txn> items, String home) =>
      items.fold(0.0, (s, t) => s + t.amountIn(home));

  String _dayLabel(AppLocalizations l, DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (d == today) return l.txListToday;
    if (d == yesterday) return l.txListYesterday;
    return DateFormat.MMMEd().format(d);
  }

  String _txSubtitle(Txn t) {
    final time = DateFormat.jm().format(t.createdAt.toLocal());
    final label = ref.read(categoryLabelProvider(
        CategoryLabelKey(key: t.category)));
    return '$label · $time';
  }

  String _fmt(double v, String currency) => formatMoney(v, currency);

  ({double income, double expense}) _dayTotals(List<Txn> items, String home) {
    var income = 0.0, expense = 0.0;
    for (final t in items) {
      if (t.isTransfer) continue;
      final v = t.absAmountIn(home);
      if (t.isIncome) {
        income += v;
      } else {
        expense += v;
      }
    }
    return (income: income, expense: expense);
  }

  Widget _buildFilterAction(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final isActive = _sourceFilter != _SourceFilter.all;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(
            isActive ? Icons.filter_alt : Icons.filter_alt_outlined,
            size: 20,
            color: isActive ? c.accent : null,
          ),
          tooltip: l.txListFilterSource,
          onPressed: _openFilterSheet,
        ),
        if (isActive)
          Positioned(
            top: 10,
            right: 10,
            child: IgnorePointer(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: 1.5),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openFilterSheet() async {
    final l = context.l10n;
    final picked = await showLoitSheet<_SourceFilter>(
      context,
      builder: (sheetCtx) => LoitSheet(
        title: l.txListFilterTransactions,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _filterTile(
              sheetCtx,
              icon: Icons.all_inclusive,
              label: l.txListAll,
              value: _SourceFilter.all,
            ),
            _filterTile(
              sheetCtx,
              icon: Icons.person_outline,
              label: l.txListPersonal,
              value: _SourceFilter.personal,
            ),
            _filterTile(
              sheetCtx,
              icon: Icons.groups_outlined,
              label: l.txListRooms,
              value: _SourceFilter.rooms,
            ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() => _sourceFilter = picked);
    }
  }

  Widget _filterTile(
    BuildContext sheetCtx, {
    required IconData icon,
    required String label,
    required _SourceFilter value,
  }) {
    final c = context.loitColors;
    final selected = _sourceFilter == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: selected ? c.accent : c.contentSecondary),
      title: Text(
        label,
        style: LoitTypography.bodyM.copyWith(
          color: selected ? c.accent : c.contentPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      trailing: selected ? Icon(Icons.check, color: c.accent, size: 20) : null,
      onTap: () => Navigator.of(sheetCtx).pop(value),
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
    final l = context.l10n;
    return Tooltip(
      message: l.txListNotSynced,
      child: Icon(Icons.cloud_off_rounded, size: 16, color: c.warning),
    );
  }
}

class _TxFlashWrapper extends StatefulWidget {
  const _TxFlashWrapper({super.key, required this.child, required this.tint});
  final Widget child;
  final Color tint;

  @override
  State<_TxFlashWrapper> createState() => _TxFlashWrapperState();
}

class _TxFlashWrapperState extends State<_TxFlashWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 200,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 300,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 200,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 500,
      ),
    ]).animate(_ctrl);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) => Stack(
        children: [
          child!,
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                color: widget.tint.withValues(alpha: 0.24 * _anim.value),
              ),
            ),
          ),
        ],
      ),
      child: widget.child,
    );
  }
}
