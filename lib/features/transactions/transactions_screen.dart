import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_radius.dart';
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
import '../../shared/utils/locale_date_format.dart';
import '../../shared/widgets/loit_banner.dart';
import '../../shared/widgets/loit_month_app_bar.dart';
import '../../shared/widgets/loit_empty_state.dart';
import '../../shared/widgets/loit_fab_stack.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_room_origin_badge.dart';
import '../../shared/widgets/loit_sheet.dart';
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

class _TransactionsScreenState extends ConsumerState<TransactionsScreen>
    with TickerProviderStateMixin {
  _SourceFilter _sourceFilter = _SourceFilter.all;

  String? _pendingScrollTxId;
  bool _scrollScheduled = false;
  final GlobalKey _highlightRowKey = GlobalKey(debugLabel: 'tx-highlight-row');

  late final AnimationController _entranceCtrl;
  bool _entranceDone = false;
  Set<String> _seenIds = const {};
  bool _seedComplete = false;
  final Set<String> _flashIds = {};
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _pendingScrollTxId = widget.highlightTxId;
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entranceCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() => _entranceDone = true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
    _entranceCtrl.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  void _trackArrivals(List<Txn> items) {
    final ids = <String>{
      for (final t in items)
        if (t.id != null) t.id!,
    };
    if (!_seedComplete) {
      _seenIds = ids;
      _seedComplete = true;
      return;
    }
    final fresh = ids.difference(_seenIds);
    if (fresh.isEmpty) {
      _seenIds = ids;
      return;
    }
    _seenIds = ids;
    if (_reduceMotion) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _flashIds.addAll(fresh));
      _flashTimer?.cancel();
      _flashTimer = Timer(const Duration(milliseconds: 1300), () {
        if (!mounted) return;
        setState(() => _flashIds.removeAll(fresh));
      });
    });
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
          loading: () => _SkeletonList(c: c),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (items) {
            _maybeScrollToHighlight();
            _trackArrivals(items);
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
            final summaryTriple = _AnimatedSummaryTriple(
              currency: currency,
              income: incomeSum,
              expense: expenseSum,
              net: netTotal,
              labels: (
                income: l.txListIncome,
                expenses: l.txListExpenses,
                total: l.txListTotal,
              ),
              format: _fmt,
              reduceMotion: _reduceMotion,
            );

            if (filtered.isEmpty) {
              final isFiltered = _sourceFilter != _SourceFilter.all;
              return ListView(
                children: [
                  summaryTriple,
                  const SizedBox(height: 24),
                  _FloatingHero(
                    enabled: !_reduceMotion,
                    child: LoitEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: isFiltered
                          ? l.txListNoMatches
                          : l.txListNoTransactions,
                      body: isFiltered
                          ? l.txListEmptySwitchAll
                          : l.txListEmptyAddTransaction,
                      primaryCta: isFiltered
                          ? l.txListShowAll
                          : l.txListNewTransaction,
                      onPrimaryCta: isFiltered
                          ? () => setState(
                              () => _sourceFilter = _SourceFilter.all)
                          : () => context.push('/transactions/new'),
                      secondaryCta:
                          isFiltered ? null : l.txListEmptyScanReceipt,
                      onSecondaryCta:
                          isFiltered ? null : () => context.push('/scan'),
                    ),
                  ),
                ],
              );
            }

            final grouped = _groupByDay(filtered);
            final sortedDays = grouped.entries.toList()
              ..sort((a, b) => b.key.compareTo(a.key));

            int staggerCursor = 0;
            _StaggerSlot staggerOf(int idx) => _StaggerSlot(
                  controller: _entranceCtrl,
                  index: idx,
                  frozen: _entranceDone,
                  reduceMotion: _reduceMotion,
                );
            final daySlivers = <Widget>[];
            for (final entry in sortedDays) {
              final groupIdx = staggerCursor++;
              daySlivers.add(
                SliverToBoxAdapter(
                  child: staggerOf(groupIdx).wrap(
                    LoitGroupLabel(
                      label: _dayLabel(l, entry.key),
                      trailing: _dayTotalsTrailing(
                        context,
                        _dayTotals(entry.value, currency),
                        currency,
                      ),
                    ),
                  ),
                ),
              );
              final rowsStart = staggerCursor;
              staggerCursor += entry.value.length;
              daySlivers.add(SliverList.builder(
                itemCount: entry.value.length,
                itemBuilder: (_, i) {
                  final rowIdx = rowsStart + i;
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
                      final bool isFreshArrival =
                          t.id != null && _flashIds.contains(t.id);
                      Widget rowOrFlash = row;
                      if (isHighlight) {
                        rowOrFlash = _TxFlashWrapper(
                          key: _highlightRowKey,
                          tint: c.brand,
                          child: rowOrFlash,
                        );
                      } else if (isFreshArrival) {
                        rowOrFlash = _TxFlashWrapper(
                          key: ValueKey('arrival-${t.id}'),
                          tint: t.isIncome ? c.info : c.accent,
                          child: rowOrFlash,
                        );
                      }
                      final staggered =
                          staggerOf(rowIdx).wrap(rowOrFlash);
                      if (t.id == null) return staggered;
                      if (t.roomId != null) {
                        return Dismissible(
                          key: ValueKey('tx-${t.id}'),
                          direction: DismissDirection.endToStart,
                          background: _swipeDeleteBackground(c, l),
                          confirmDismiss: (_) async {
                            _showRoomDeleteRedirect(t);
                            return false;
                          },
                          child: staggered,
                        );
                      }
                      return Dismissible(
                        key: ValueKey('tx-${t.id}'),
                        direction: DismissDirection.endToStart,
                        background: _swipeDeleteBackground(c, l),
                        onDismissed: (_) => _deleteWithUndo(t),
                        child: staggered,
                      );
                },
              ));
            }

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
                ...daySlivers,
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

  String _dayLabel(AppLocalizations l, DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (d == today) return l.txListToday;
    if (d == yesterday) return l.txListYesterday;
    return MMMEd(context).format(d);
  }

  String _txSubtitle(Txn t) {
    final time = jm(context).format(t.createdAt.toLocal());
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
    final dur = _reduceMotion ? Duration.zero : LoitMotion.emphasized;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: AnimatedRotation(
            turns: isActive ? 0.0833 : 0.0,
            duration: dur,
            curve: LoitMotion.easeOutExpo,
            child: AnimatedSwitcher(
              duration: LoitMotion.short,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                isActive ? Icons.filter_alt : Icons.filter_alt_outlined,
                key: ValueKey(isActive),
                size: 20,
                color: isActive ? c.accent : null,
              ),
            ),
          ),
          tooltip: l.txListFilterSource,
          onPressed: _openFilterSheet,
        ),
        Positioned(
          top: 10,
          right: 10,
          child: IgnorePointer(
            child: AnimatedScale(
              duration: dur,
              curve: LoitMotion.easeOutExpo,
              scale: isActive ? 1.0 : 0.0,
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

class _StaggerSlot {
  const _StaggerSlot({
    required this.controller,
    required this.index,
    required this.frozen,
    required this.reduceMotion,
  });

  final AnimationController controller;
  final int index;
  final bool frozen;
  final bool reduceMotion;

  Widget wrap(Widget child) {
    if (frozen || reduceMotion) return child;
    final start = (index * 0.05).clamp(0.0, 0.6);
    const span = 0.5;
    final end = (start + span).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: controller,
      curve: Interval(start, end, curve: LoitMotion.easeOutExpo),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (_, c) {
        final t = curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 18),
            child: c,
          ),
        );
      },
      child: child,
    );
  }
}

class _AnimatedSummaryTriple extends StatefulWidget {
  const _AnimatedSummaryTriple({
    required this.currency,
    required this.income,
    required this.expense,
    required this.net,
    required this.labels,
    required this.format,
    required this.reduceMotion,
  });

  final String currency;
  final double income;
  final double expense;
  final double net;
  final ({String income, String expenses, String total}) labels;
  final String Function(double, String) format;
  final bool reduceMotion;

  @override
  State<_AnimatedSummaryTriple> createState() => _AnimatedSummaryTripleState();
}

class _AnimatedSummaryTripleState extends State<_AnimatedSummaryTriple> {
  late double _income = widget.reduceMotion ? widget.income : 0;
  late double _expense = widget.reduceMotion ? widget.expense : 0;
  late double _net = widget.reduceMotion ? widget.net : 0;
  double _prevIncome = 0;
  double _prevExpense = 0;
  double _prevNet = 0;

  @override
  void initState() {
    super.initState();
    _prevIncome = _income;
    _prevExpense = _expense;
    _prevNet = _net;
  }

  @override
  void didUpdateWidget(covariant _AnimatedSummaryTriple old) {
    super.didUpdateWidget(old);
    _prevIncome = _income;
    _prevExpense = _expense;
    _prevNet = _net;
    _income = widget.income;
    _expense = widget.expense;
    _net = widget.net;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final dur = widget.reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 720);
    return Container(
      color: c.canvas,
      padding: const EdgeInsets.fromLTRB(
        LoitSpacing.s5,
        LoitSpacing.s2,
        LoitSpacing.s5,
        LoitSpacing.s4,
      ),
      child: Row(
        children: [
          Expanded(
            child: _AnimatedStatCell(
              label: widget.labels.income,
              from: _prevIncome,
              to: _income,
              color: c.info,
              currency: widget.currency,
              format: widget.format,
              duration: dur,
            ),
          ),
          _Divider(c: c),
          Expanded(
            child: _AnimatedStatCell(
              label: widget.labels.expenses,
              from: _prevExpense,
              to: _expense,
              color: c.danger,
              currency: widget.currency,
              format: widget.format,
              duration: dur,
            ),
          ),
          _Divider(c: c),
          Expanded(
            child: _AnimatedStatCell(
              label: widget.labels.total,
              from: _prevNet,
              to: _net,
              color: _net >= 0 ? c.info : c.danger,
              currency: widget.currency,
              format: widget.format,
              duration: dur,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.c});
  final LoitColors c;
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 28,
        color: c.borderSubtle,
        margin: const EdgeInsets.symmetric(horizontal: LoitSpacing.s3),
      );
}

class _AnimatedStatCell extends StatelessWidget {
  const _AnimatedStatCell({
    required this.label,
    required this.from,
    required this.to,
    required this.color,
    required this.currency,
    required this.format,
    required this.duration,
  });

  final String label;
  final double from;
  final double to;
  final Color color;
  final String currency;
  final String Function(double, String) format;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: LoitTypography.labelS.copyWith(
            color: c.contentTertiary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: from, end: to),
          duration: duration,
          curve: LoitMotion.easeOutExpo,
          builder: (_, value, __) => Text(
            format(value, currency),
            style: LoitTypography.amountDefault.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _FloatingHero extends StatefulWidget {
  const _FloatingHero({required this.child, required this.enabled});
  final Widget child;
  final bool enabled;

  @override
  State<_FloatingHero> createState() => _FloatingHeroState();
}

class _FloatingHeroState extends State<_FloatingHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );
    if (widget.enabled) _ctrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        final t = Curves.easeInOut.transform(_ctrl.value);
        final dy = (t - 0.5) * 8;
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SkeletonList extends StatefulWidget {
  const _SkeletonList({required this.c});
  final LoitColors c;

  @override
  State<_SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<_SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 8,
      padding: const EdgeInsets.symmetric(
        vertical: LoitSpacing.s4,
        horizontal: LoitSpacing.s5,
      ),
      itemBuilder: (_, i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s2),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final t = reduce ? 0.5 : _ctrl.value;
            final alpha = 0.35 + 0.35 * t;
            return Row(
              children: [
                _Bone(
                  c: widget.c,
                  alpha: alpha,
                  width: 36,
                  height: 36,
                  radius: LoitRadius.brFull,
                ),
                const SizedBox(width: LoitSpacing.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bone(
                        c: widget.c,
                        alpha: alpha,
                        width: 160,
                        height: 12,
                        radius: const BorderRadius.all(Radius.circular(4)),
                      ),
                      const SizedBox(height: 8),
                      _Bone(
                        c: widget.c,
                        alpha: alpha * 0.85,
                        width: 100,
                        height: 10,
                        radius: const BorderRadius.all(Radius.circular(4)),
                      ),
                    ],
                  ),
                ),
                _Bone(
                  c: widget.c,
                  alpha: alpha,
                  width: 70,
                  height: 14,
                  radius: const BorderRadius.all(Radius.circular(4)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Bone extends StatelessWidget {
  const _Bone({
    required this.c,
    required this.alpha,
    required this.width,
    required this.height,
    required this.radius,
  });
  final LoitColors c;
  final double alpha;
  final double width;
  final double height;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.borderSubtle.withValues(alpha: alpha),
        borderRadius: radius,
      ),
    );
  }
}
