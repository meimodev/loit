import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
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
import '../../shared/widgets/loit_sheet.dart';
import '../../shared/widgets/loit_stat_triple.dart';
import '../../shared/widgets/loit_tx_row.dart';
import '../rooms/room_colors.dart';
import 'notes_breakdown.dart';

/// Source filter applied to the transactions feed.
enum _SourceFilter { all, personal, rooms }

/// LOIT Transactions feed. Owns monthly summary (Income / Expenses / Total),
/// filter chips, grouped-by-day rows, search, and add/scan FABs.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key, this.highlightTxId});
  final String? highlightTxId;

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  // Source filter (all / personal-only / rooms-only)
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    final roomName = t.roomName ?? 'the room';
    final roomId = t.roomId;
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 5),
        content: Text(
            'This transaction belongs to "$roomName". Delete it from the room.'),
        action: roomId == null
            ? null
            : SnackBarAction(
                label: 'Open room',
                onPressed: () =>
                    context.go('/rooms/$roomId?highlight=${t.id}'),
              ),
      ),
    );
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
    // Fallback room-name lookup when the transactions join did not embed
    // the related room (e.g. RLS edge cases or stale optimistic rows).
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
            tooltip: 'Search',
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
                      // Trailing badge keeps only the sync indicator.
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
                          ? _RoomOriginBadge(
                              accent: roomAccent!,
                              name: t.roomName ??
                                  roomNameById[t.roomId!] ??
                                  'Room',
                            )
                          : null;
                      final row = LoitTxRow(
                        title: breakdownTitle(t.notes),
                        categoryKey: t.isTransfer ? null : t.category,
                        subtitle: _txSubtitle(t),
                        amount: _fmt(t.amount, t.currency),
                        subAmount: (t.currency != currency &&
                                t.amountHome != null)
                            ? '≈ ${_fmt(t.amountHome!.abs(), currency)}'
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
                            // Room-inherited txn: jump to room detail under
                            // the Rooms tab so the bottom-nav active branch
                            // matches the destination.
                            context.go('/rooms/${t.roomId}');
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
                      // Swipe-to-delete only when the row has been synced
                      // (has id). Unsynced rows can't be deleted server-side
                      // yet.
                      if (t.id == null) return rowOrFlash;
                      // Room-inherited rows are owned by the originating room;
                      // delete must happen there, not from the personal list.
                      if (t.roomId != null) {
                        return Dismissible(
                          key: ValueKey('tx-${t.id}'),
                          direction: DismissDirection.endToStart,
                          background: _swipeDeleteBackground(c),
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
                        background: _swipeDeleteBackground(c),
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
      floatingActionButton: LoitFabStack(
        onPrimary: () => context.push('/transactions/new'),
        primaryTooltip: 'New transaction',
        primaryIcon: Icons.add,
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
    final label = ref.read(categoryLabelProvider(
        CategoryLabelKey(key: t.category)));
    return '$label · $time';
  }

  String _fmt(double v, String currency) => formatMoney(v, currency);

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

  Widget _buildFilterAction(BuildContext context) {
    final c = context.loitColors;
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
          tooltip: 'Filter source',
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
    final picked = await showLoitSheet<_SourceFilter>(
      context,
      builder: (sheetCtx) => LoitSheet(
        title: 'Filter transactions',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _filterTile(
              sheetCtx,
              icon: Icons.all_inclusive,
              label: 'All',
              value: _SourceFilter.all,
            ),
            _filterTile(
              sheetCtx,
              icon: Icons.person_outline,
              label: 'Personal',
              value: _SourceFilter.personal,
            ),
            _filterTile(
              sheetCtx,
              icon: Icons.groups_outlined,
              label: 'Rooms',
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

/// Plays a one-shot two-pulse flash overlay over its child once on mount.
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
