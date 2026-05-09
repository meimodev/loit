import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/services/room_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/budgets_provider.dart';
import '../../shared/providers/home_currency_provider.dart';
import '../../shared/providers/presence_provider.dart';
import '../../shared/providers/room_aggregations_provider.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/selected_month_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/loit_empty_state.dart';
import '../rooms/room_colors.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  const RoomDetailScreen({
    super.key,
    required this.roomId,
    this.initialTab = 0,
    this.highlightTxId,
    this.fromTab,
  });
  final String roomId;
  final int initialTab;
  final String? highlightTxId;
  final String? fromTab;

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  late int _tab =
      widget.highlightTxId != null ? 0 : widget.initialTab.clamp(0, 2);
  String? _pendingScrollTxId;
  bool _scrollScheduled = false;
  final GlobalKey _highlightRowKey = GlobalKey(debugLabel: 'highlight-row');

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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction not in recent feed'),
          ),
        );
      }
      if (mounted) setState(() => _pendingScrollTxId = null);
    });
  }

  void _handleBack() {
    if (widget.fromTab == 'transactions') {
      context.go('/transactions');
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go('/rooms');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
    final feedAsync = ref.watch(roomFeedProvider(widget.roomId));
    final budgetsAsync = ref.watch(roomBudgetsProvider(widget.roomId));
    final user = ref.watch(currentUserProvider);

    if (feedAsync.hasValue && _tab == 0) {
      _maybeScrollToHighlight();
    }

    return roomAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
          appBar: AppBar(), body: Center(child: Text('Error: $e'))),
      data: (room) {
        final name = room['name'] as String? ?? 'Room';
        final isCreator = room['created_by'] == user?.id;
        final isArchived = room['is_archived'] as bool? ?? false;
        final members = (room['room_members'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
        final accent = RoomColors.forId(widget.roomId);
        final currency = room['base_currency'] as String? ?? 'IDR';
        String fmt(double v) => formatMoney(v, currency);

        return PopScope(
          canPop: widget.fromTab != 'transactions',
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            _handleBack();
          },
          child: Scaffold(
          backgroundColor: c.canvas,
          body: SafeArea(
            child: Column(
              children: [
                _Header(
                  name: name,
                  accent: accent,
                  members: members,
                  isCreator: isCreator,
                  isArchived: isArchived,
                  onBack: _handleBack,
                  onInvite: () =>
                      context.push('/rooms/${widget.roomId}/invite'),
                  onArchive: () => _confirmArchive(context),
                  onLeave: () => _confirmLeave(context),
                  onMembers: () => _showMembers(context, members),
                  onReports: () =>
                      context.push('/rooms/${widget.roomId}/reports'),
                ),
                _TabStrip(
                  active: _tab,
                  onTap: (i) => setState(() => _tab = i),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(roomFeedProvider(widget.roomId));
                      ref.invalidate(roomDetailProvider(widget.roomId));
                      ref.invalidate(roomBudgetsProvider(widget.roomId));
                      ref.invalidate(userCategoriesProvider);
                    },
                    child: _tabBody(
                      feedAsync: feedAsync,
                      budgetsAsync: budgetsAsync,
                      members: members,
                      currentUserId: user?.id,
                      isCreator: isCreator,
                      accent: accent,
                      fmt: fmt,
                      currency: currency,
                      isArchived: isArchived,
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: isArchived
              ? null
              : _tab == 0
                  ? FloatingActionButton(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      onPressed: () => _addExpense(room),
                      child: const Icon(Icons.add),
                    )
                  : _tab == 1
                      ? FloatingActionButton(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                          onPressed: () => context.push(
                            '/rooms/${widget.roomId}/budgets/new',
                            extra: <String, dynamic>{'currency': currency},
                          ),
                          child: const Icon(Icons.add),
                        )
                      : _tab == 2 && isCreator
                          ? FloatingActionButton(
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              onPressed: () => context.push(
                                  '/rooms/${widget.roomId}/categories/new'),
                              child: const Icon(Icons.add),
                            )
                          : null,
        ),
        );
      },
    );
  }

  Widget _tabBody({
    required AsyncValue<List<Map<String, dynamic>>> feedAsync,
    required AsyncValue<List<Map<String, dynamic>>> budgetsAsync,
    required List<Map<String, dynamic>> members,
    required String? currentUserId,
    required bool isCreator,
    required Color accent,
    required String Function(double) fmt,
    required String currency,
    required bool isArchived,
  }) {
    switch (_tab) {
      case 1:
        return _BudgetTab(
            roomId: widget.roomId,
            budgetsAsync: budgetsAsync,
            fmt: fmt,
            currency: currency,
            isArchived: isArchived);
      case 2:
        return _CategoriesTab(
            roomId: widget.roomId,
            isCreator: isCreator,
            isArchived: isArchived);
      case 0:
      default:
        return _FeedTab(
          roomId: widget.roomId,
          feedAsync: feedAsync,
          members: members,
          accent: accent,
          fmt: fmt,
          isArchived: isArchived,
          currentUserId: currentUserId,
          isCreator: isCreator,
          highlightTxId: widget.highlightTxId,
          highlightRowKey: _highlightRowKey,
        );
    }
  }

  void _addExpense(Map<String, dynamic> room) {
    context.push(
      '/transactions/new',
      extra: <String, dynamic>{
        '_room_id': room['id'],
        '_room_name': room['name'],
        'currency': room['base_currency'] ?? 'IDR',
      },
    );
  }

  Future<void> _confirmArchive(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archive room?'),
        content: const Text(
            'Members will retain read-only access. This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Archive')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await RoomService().archiveRoom(widget.roomId);
      ref.invalidate(myRoomsProvider);
      ref.invalidate(roomDetailProvider(widget.roomId));
    }
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave room?'),
        content: const Text('You can rejoin via a new invite.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await RoomService().leaveRoom(widget.roomId);
      ref.invalidate(myRoomsProvider);
      if (context.mounted) context.go('/rooms');
    }
  }

  void _showMembers(BuildContext context, List<Map<String, dynamic>> members) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Consumer(
          builder: (ctx, ref, _) {
            final onlineIds =
                ref.watch(onlineUsersProvider).value ?? const <String>{};
            final c = ctx.loitColors;
            final onlineCount = members
                .where((m) => onlineIds.contains(m['user_id'] as String?))
                .length;
            return ListView(
              shrinkWrap: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Members',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16)),
                      const Spacer(),
                      if (onlineCount > 0)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF22C55E),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text('$onlineCount online',
                                style: TextStyle(
                                    color: c.contentSecondary, fontSize: 13)),
                          ],
                        ),
                    ],
                  ),
                ),
                for (final m in members)
                  ListTile(
                    leading: _MemberAvatar(member: m, size: 36),
                    title: Text(_memberName(m)),
                    subtitle: onlineIds.contains(m['user_id'] as String?)
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('Online',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                            ],
                          )
                        : null,
                    trailing: Text((m['role'] as String?) ?? 'member'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _memberName(Map<String, dynamic> m) {
  final n = ((m['users']?['name'] as String?) ?? '').trim();
  if (n.isNotEmpty) return n;
  final email = ((m['users']?['email'] as String?) ?? '').trim();
  if (email.contains('@')) return email.split('@').first;
  if (email.isNotEmpty) return email;
  return 'Unknown';
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.accent,
    required this.members,
    required this.isCreator,
    required this.isArchived,
    required this.onBack,
    required this.onInvite,
    required this.onArchive,
    required this.onLeave,
    required this.onMembers,
    required this.onReports,
  });
  final String name;
  final Color accent;
  final List<Map<String, dynamic>> members;
  final bool isCreator;
  final bool isArchived;
  final VoidCallback onBack;
  final VoidCallback onInvite;
  final VoidCallback onArchive;
  final VoidCallback onLeave;
  final VoidCallback onMembers;
  final VoidCallback onReports;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      padding: const EdgeInsets.fromLTRB(
          LoitSpacing.s3, LoitSpacing.s2, LoitSpacing.s3, LoitSpacing.s3),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 22),
                onPressed: onBack,
              ),
              Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: accent, shape: BoxShape.circle),
              ),
              const SizedBox(width: LoitSpacing.s2),
              Expanded(
                child: Text(
                  name,
                  style: LoitTypography.titleM.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.15),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isArchived)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.muted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('ARCHIVED',
                        style: LoitTypography.labelS.copyWith(
                            color: c.contentSecondary, letterSpacing: 0.4)),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.bar_chart, size: 20),
                tooltip: 'Reports',
                onPressed: onReports,
              ),
              if (!isArchived)
                IconButton(
                    icon: const Icon(Icons.person_add_alt, size: 20),
                    tooltip: 'Invite',
                    onPressed: onInvite),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 22),
                onSelected: (v) {
                  switch (v) {
                    case 'members':
                      onMembers();
                    case 'archive':
                      onArchive();
                    case 'leave':
                      onLeave();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: 'members',
                      child: Text('Members (${members.length})')),
                  if (isCreator && !isArchived)
                    const PopupMenuItem(
                        value: 'archive', child: Text('Archive room')),
                  if (!isCreator)
                    const PopupMenuItem(
                        value: 'leave', child: Text('Leave room')),
                ],
              ),
            ],
          ),
          const SizedBox(height: LoitSpacing.s2),
          Padding(
            padding: const EdgeInsets.only(left: LoitSpacing.s2),
            child: Row(
              children: [
                _AvatarStack(members: members),
                const SizedBox(width: LoitSpacing.s2),
                Expanded(
                  child: Consumer(builder: (_, ref, __) {
                    final onlineIds = ref.watch(onlineUsersProvider).value ??
                        const <String>{};
                    final onlineCount = members
                        .where((m) => onlineIds.contains(m['user_id'] as String?))
                        .length;
                    final base =
                        '${members.length} member${members.length == 1 ? '' : 's'}';
                    return Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: base,
                            style: LoitTypography.bodyS
                                .copyWith(color: c.contentSecondary),
                          ),
                          if (onlineCount > 0) ...[
                            TextSpan(
                              text: '  · ',
                              style: LoitTypography.bodyS
                                  .copyWith(color: c.contentTertiary),
                            ),
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: SizedBox(
                                  width: 8,
                                  height: 8,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF22C55E),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            TextSpan(
                              text: '$onlineCount online',
                              style: LoitTypography.bodyS.copyWith(
                                  color: c.contentPrimary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members});
  final List<Map<String, dynamic>> members;

  @override
  Widget build(BuildContext context) {
    final shown = members.take(3).toList();
    return SizedBox(
      width: shown.isEmpty ? 0 : (28.0 + (shown.length - 1) * 18.0),
      height: 28,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * 18.0,
              child: _MemberAvatar(member: shown[i], size: 28),
            ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends ConsumerWidget {
  const _MemberAvatar({required this.member, required this.size});
  final Map<String, dynamic> member;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final url = member['users']?['avatar_url'] as String?;
    final name = _memberName(member);
    final color = RoomColors.forId(name);
    final userId = member['user_id'] as String?;
    final onlineIds = ref.watch(onlineUsersProvider).value ?? const <String>{};
    final isOnline = userId != null && onlineIds.contains(userId);

    final dotSize = (size * 0.32).clamp(8.0, 14.0);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: c.surface, width: 2),
              image: url != null && url.isNotEmpty
                  ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: url == null || url.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.4,
                        fontWeight: FontWeight.w600),
                  )
                : null,
          ),
          if (isOnline)
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.active, required this.onTap});
  final int active;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    const labels = ['Feed', 'Budget', 'Categories'];
    return Container(
      margin: const EdgeInsets.fromLTRB(
          LoitSpacing.s4, LoitSpacing.s3, LoitSpacing.s4, LoitSpacing.s2),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: c.muted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i == active ? c.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    labels[i],
                    style: LoitTypography.bodyS.copyWith(
                      color: i == active
                          ? c.contentPrimary
                          : c.contentSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedTab extends ConsumerWidget {
  const _FeedTab({
    required this.roomId,
    required this.feedAsync,
    required this.members,
    required this.accent,
    required this.fmt,
    required this.isArchived,
    required this.currentUserId,
    required this.isCreator,
    this.highlightTxId,
    this.highlightRowKey,
  });
  final String roomId;
  final AsyncValue<List<Map<String, dynamic>>> feedAsync;
  final List<Map<String, dynamic>> members;
  final Color accent;
  final String Function(double) fmt;
  final bool isArchived;
  final String? currentUserId;
  final bool isCreator;
  final String? highlightTxId;
  final GlobalKey? highlightRowKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingRoomTxDeletesProvider);
    final month = ref.watch(selectedMonthProvider);
    final monthBar = _MonthBar(month: month);
    final fxAsync = ref.watch(roomFxRatesProvider(roomId));
    return feedAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (allTxns) {
        final visible = allTxns
            .where((t) => !pending.contains(t['id'] as String?))
            .toList();
        // Read-time conversion: each row keeps its original currency, but
        // totals are normalized to room.base_currency for the summary card.
        final fxRates = fxAsync.value;
        double expensesTotal = 0;
        double incomeTotal = 0;
        int expensesCount = 0;
        int incomeCount = 0;
        for (final t in visible) {
          final amt = (t['amount'] as num?)?.toDouble() ?? 0;
          final type = (t['type'] as String?) ??
              (amt > 0 ? 'income' : 'expense');
          if (type == 'transfer') continue;
          final txCur = (t['currency'] as String?) ?? (fxRates?.baseCurrency ?? 'IDR');
          final converted = fxRates?.convert(amt.abs(), txCur) ?? amt.abs();
          if (type == 'income') {
            incomeTotal += converted;
            incomeCount++;
          } else {
            expensesTotal += converted;
            expensesCount++;
          }
        }
        final summaryCard = _TotalSpentCard(
          total: expensesTotal,
          income: incomeTotal,
          expensesCount: expensesCount,
          incomeCount: incomeCount,
          fmt: fmt,
          isStale: fxRates?.isStale ?? false,
        );
        final txns = visible.where((t) {
          final dt = DateTime.tryParse((t['created_at'] as String?) ?? '');
          if (dt == null) return false;
          return dt.year == month.year && dt.month == month.month;
        }).toList();
        if (txns.isEmpty) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
                LoitSpacing.s4, 0, LoitSpacing.s4, 100),
            children: [
              summaryCard,
              monthBar,
              Padding(
                padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s7),
                child: LoitEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: isArchived ? 'No activity' : 'No activity this month',
                  body: isArchived
                      ? 'This room is archived'
                      : 'Try a different month or log a new expense.',
                ),
              ),
            ],
          );
        }
        final grouped = _groupByDay(txns);
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              LoitSpacing.s4, 0, LoitSpacing.s4, 100),
          children: [
            summaryCard,
            monthBar,
            for (final entry in grouped.entries) ...[
              Padding(
                padding: const EdgeInsets.only(
                    top: LoitSpacing.s4, bottom: 6, left: 4),
                child: Text(
                  entry.key.toUpperCase(),
                  style: LoitTypography.labelS.copyWith(
                      color: Theme.of(context)
                          .extension<LoitColors>()!
                          .contentSecondary,
                      letterSpacing: 0.5),
                ),
              ),
              _DayGroup(
                  roomId: roomId,
                  txns: entry.value,
                  fmt: fmt,
                  currentUserId: currentUserId,
                  isCreator: isCreator,
                  highlightTxId: highlightTxId,
                  highlightRowKey: highlightRowKey),
            ],
          ],
        );
      },
    );
  }

  Map<String, List<Map<String, dynamic>>> _groupByDay(
      List<Map<String, dynamic>> txns) {
    final out = <String, List<Map<String, dynamic>>>{};
    final now = DateTime.now();
    for (final t in txns) {
      final dt = DateTime.tryParse((t['created_at'] as String?) ?? '');
      String key;
      if (dt == null) {
        key = 'Earlier';
      } else {
        final d = DateTime(dt.year, dt.month, dt.day);
        final today = DateTime(now.year, now.month, now.day);
        final diff = today.difference(d).inDays;
        if (diff == 0) {
          key = 'Today';
        } else if (diff == 1) {
          key = 'Yesterday';
        } else {
          key = DateFormat.MMMd().format(dt);
        }
      }
      out.putIfAbsent(key, () => []).add(t);
    }
    return out;
  }
}

class _MonthBar extends ConsumerWidget {
  const _MonthBar({required this.month});
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final notifier = ref.read(selectedMonthProvider.notifier);
    return Container(
      margin: const EdgeInsets.only(top: LoitSpacing.s2),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.borderSubtle),
        borderRadius: LoitRadius.brM,
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 22),
            color: c.contentSecondary,
            onPressed: notifier.prev,
          ),
          Expanded(
            child: Center(
              child: Text(
                DateFormat.yMMM().format(month),
                style: LoitTypography.bodyM.copyWith(
                  color: c.contentPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 22),
            color: c.contentSecondary,
            onPressed: notifier.next,
          ),
        ],
      ),
    );
  }
}

class _TotalSpentCard extends StatelessWidget {
  const _TotalSpentCard({
    required this.total,
    required this.income,
    required this.expensesCount,
    required this.incomeCount,
    required this.fmt,
    this.isStale = false,
  });
  final double total;
  final double income;
  final int expensesCount;
  final int incomeCount;
  final String Function(double) fmt;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final incomeColor = const Color(0xFF2F8F5E);
    final expenseColor = c.danger;
    return Container(
      margin: const EdgeInsets.only(top: LoitSpacing.s3),
      padding: const EdgeInsets.all(LoitSpacing.s3),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.borderSubtle),
        borderRadius: LoitRadius.brM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isStale)
            Padding(
              padding: const EdgeInsets.only(bottom: LoitSpacing.s2),
              child: Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: c.contentTertiary),
                  const SizedBox(width: 4),
                  Text(
                    'Rates may be outdated',
                    style: LoitTypography.bodyS
                        .copyWith(color: c.contentTertiary),
                  ),
                ],
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SummaryStat(
                  label: 'EXPENSES',
                  value: fmt(total),
                  icon: Icons.trending_down,
                  tint: expenseColor,
                  count: expensesCount,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: LoitSpacing.s3),
                color: c.borderSubtle,
              ),
              Expanded(
                child: _SummaryStat(
                  label: 'INCOME',
                  value: fmt(income),
                  icon: Icons.trending_up,
                  tint: incomeColor,
                  count: incomeCount,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.count,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: c.contentSecondary),
            const SizedBox(width: 4),
            Text(label,
                style: LoitTypography.labelS.copyWith(
                    color: c.contentSecondary, letterSpacing: 0.4)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: c.muted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count',
                  style: LoitTypography.labelS.copyWith(
                      color: c.contentSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()])),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: LoitTypography.titleM.copyWith(
            color: tint,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}


class _DayGroup extends StatelessWidget {
  const _DayGroup(
      {required this.roomId,
      required this.txns,
      required this.fmt,
      required this.currentUserId,
      required this.isCreator,
      this.highlightTxId,
      this.highlightRowKey});
  final String roomId;
  final List<Map<String, dynamic>> txns;
  final String Function(double) fmt;
  final String? currentUserId;
  final bool isCreator;
  final String? highlightTxId;
  final GlobalKey? highlightRowKey;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.borderSubtle),
        borderRadius: LoitRadius.brM,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < txns.length; i++)
            _RoomTxRow(
              key: (highlightTxId != null &&
                      highlightTxId == txns[i]['id'] &&
                      highlightRowKey != null)
                  ? highlightRowKey
                  : null,
              roomId: roomId,
              tx: txns[i],
              isLast: i == txns.length - 1,
              fmt: fmt,
              currentUserId: currentUserId,
              isCreator: isCreator,
              highlightTxId: highlightTxId,
            ),
        ],
      ),
    );
  }
}

class _RoomTxRow extends ConsumerStatefulWidget {
  const _RoomTxRow({
      super.key,
      required this.roomId,
      required this.tx,
      required this.isLast,
      required this.fmt,
      required this.currentUserId,
      required this.isCreator,
      this.highlightTxId});
  final String roomId;
  final Map<String, dynamic> tx;
  final bool isLast;
  final String Function(double) fmt;
  final String? currentUserId;
  final bool isCreator;
  final String? highlightTxId;

  @override
  ConsumerState<_RoomTxRow> createState() => _RoomTxRowState();
}

class _RoomTxRowState extends ConsumerState<_RoomTxRow>
    with SingleTickerProviderStateMixin {
  AnimationController? _flashCtrl;
  Animation<double>? _flashAnim;
  bool _didFlash = false;

  @override
  void initState() {
    super.initState();
    _maybeStartFlash();
  }

  @override
  void didUpdateWidget(covariant _RoomTxRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeStartFlash();
  }

  void _maybeStartFlash() {
    if (_didFlash) return;
    final txId = widget.tx['id'] as String?;
    if (txId == null || widget.highlightTxId != txId) return;
    _didFlash = true;
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _flashAnim = TweenSequence<double>([
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
    ]).animate(_flashCtrl!);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flashCtrl?.forward();
    });
  }

  @override
  void dispose() {
    _flashCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tx = widget.tx;
    final roomId = widget.roomId;
    final isLast = widget.isLast;
    final currentUserId = widget.currentUserId;
    final c = context.loitColors;
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
    final txCurrency = (tx['currency'] as String?) ?? 'IDR';
    final homeCurrency = ref.watch(homeCurrencyProvider);
    final storedHome = (tx['amount_home_currency'] as num?)?.toDouble();
    final isForeign = txCurrency != homeCurrency;
    final convertedAmount = storedHome?.abs();
    final txType = tx['type'] as String? ?? (amount > 0 ? 'income' : 'expense');
    final isIncome = txType == 'income';
    final isTransfer = txType == 'transfer';
    final notes = (tx['notes'] as String?)?.trim();
    final merchant = (notes != null && notes.isNotEmpty)
        ? notes.split('\n').first
        : (isTransfer ? 'Transfer' : isIncome ? 'Income' : 'Expense');
    final cat = tx['category'] as String?;
    final style = ref.watch(categoryStyleProvider(cat));
    final catLabel = ref.watch(categoryLabelProvider(
        CategoryLabelKey(key: cat, activeRoomId: roomId)));
    final user = tx['users'] as Map<String, dynamic>?;
    final rawName = (user?['name'] as String?)?.trim();
    final email = (user?['email'] as String?)?.trim();
    final emailHandle =
        (email != null && email.contains('@')) ? email.split('@').first : email;
    final payer = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (emailHandle != null && emailHandle.isNotEmpty)
            ? emailHandle
            : 'Unknown';
    final incomeColor = const Color(0xFF2F8F5E);

    final createdRaw = tx['created_at'] as String?;
    final created =
        createdRaw != null ? DateTime.tryParse(createdRaw)?.toLocal() : null;
    final timeText = created != null ? DateFormat.jm().format(created) : null;

    final txId = tx['id'] as String?;

    final body = Container(
      padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s4, vertical: LoitSpacing.s3),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: c.borderSubtle),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: style.tint.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(style.icon, size: 20, color: style.tint),
              ),
              if (user != null)
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: _PayerBadge(member: {
                    'user_id': tx['user_id'],
                    'users': user,
                  }),
                ),
            ],
          ),
          const SizedBox(width: LoitSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  merchant,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LoitTypography.bodyM.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '$payer · $catLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LoitTypography.bodyS
                      .copyWith(color: c.contentSecondary),
                ),
                if (isIncome) ...[
                  const SizedBox(height: 6),
                  _RoomChip(
                    icon: Icons.call_received,
                    label: 'Income',
                    tint: incomeColor,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: LoitSpacing.s2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isTransfer ? '' : isIncome ? '+' : '−'}${formatMoney(amount.abs(), txCurrency)}',
                style: LoitTypography.bodyM.copyWith(
                    color: isTransfer
                        ? c.contentSecondary
                        : isIncome
                            ? incomeColor
                            : c.danger,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              if (isForeign && convertedAmount != null) ...[
                const SizedBox(height: 2),
                Text(
                  '≈ ${formatMoney(convertedAmount, homeCurrency)}',
                  style: LoitTypography.bodyS.copyWith(
                    color: c.contentTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
              if (timeText != null) ...[
                const SizedBox(height: 2),
                Text(timeText,
                    style: LoitTypography.bodyS
                        .copyWith(color: c.contentTertiary)),
              ],
            ],
          ),
        ],
      ),
    );

    final Widget core;
    if (txId == null) {
      core = body;
    } else {
      final tappable = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push(
            '/rooms/$roomId/transactions/$txId',
            extra: tx,
          ),
          child: body,
        ),
      );
      final isOwner =
          currentUserId != null && tx['user_id'] == currentUserId;
      if (!isOwner) {
        core = tappable;
      } else {
        core = Dismissible(
          key: ValueKey('room-tx-$txId'),
          direction: DismissDirection.endToStart,
          onDismissed: (_) =>
              _scheduleDeleteWithUndo(context, ref, txId, merchant),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: c.danger,
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          child: tappable,
        );
      }
    }

    final flash = _flashAnim;
    if (flash == null) return core;
    final accent = RoomColors.forId(roomId);
    return AnimatedBuilder(
      animation: flash,
      builder: (_, child) {
        return Stack(
          children: [
            child!,
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: accent.withValues(alpha: 0.24 * flash.value),
                ),
              ),
            ),
          ],
        );
      },
      child: core,
    );
  }

  void _scheduleDeleteWithUndo(
      BuildContext context, WidgetRef ref, String txId, String label) {
    const window = Duration(seconds: 5);
    ref
        .read(pendingRoomTxDeletesProvider.notifier)
        .schedule(txId: txId, roomId: widget.roomId, delay: window);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: window,
        content: Text('Deleted "$label"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () =>
              ref.read(pendingRoomTxDeletesProvider.notifier).undo(txId),
        ),
      ),
    );
  }
}

class _PayerBadge extends ConsumerWidget {
  const _PayerBadge({required this.member});
  final Map<String, dynamic> member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final url = member['users']?['avatar_url'] as String?;
    final name = _memberName(member);
    final color = RoomColors.forId(name);
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: c.surface, width: 2),
        image: url != null && url.isNotEmpty
            ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover)
            : null,
      ),
      alignment: Alignment.center,
      child: url == null || url.isEmpty
          ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700),
            )
          : null,
    );
  }
}

class _RoomChip extends StatelessWidget {
  const _RoomChip({required this.label, required this.tint, this.icon});
  final String label;
  final Color tint;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: icon != null ? 6 : 7, vertical: 2),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: tint),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: LoitTypography.labelS.copyWith(
              color: tint,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetTab extends ConsumerWidget {
  const _BudgetTab({
    required this.roomId,
    required this.budgetsAsync,
    required this.fmt,
    required this.currency,
    required this.isArchived,
  });
  final String roomId;
  final AsyncValue<List<Map<String, dynamic>>> budgetsAsync;
  final String Function(double) fmt;
  final String currency;
  final bool isArchived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final spendAsync = ref.watch(roomBudgetSpendConvertedProvider(roomId));
    final spendData = spendAsync.value;
    final spendMap = spendData?.spend ?? const <String, double>{};
    return budgetsAsync.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        if (list.isEmpty) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s7),
            children: [
              const LoitEmptyState(
                icon: Icons.savings_outlined,
                title: 'No budgets set',
                body: 'Set category caps so the room knows when to slow down.',
              ),
              if (!isArchived) ...[
                const SizedBox(height: LoitSpacing.s4),
                Center(
                  child: FilledButton.icon(
                    onPressed: () => context.push(
                      '/rooms/$roomId/budgets/new',
                      extra: <String, dynamic>{'currency': currency},
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('New budget'),
                  ),
                ),
              ],
            ],
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
              LoitSpacing.s4, LoitSpacing.s2, LoitSpacing.s4, 100),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final b = list[i];
            final cat = b['category'] as String?;
            final style = ref.watch(categoryStyleProvider(cat));
            final budgetLabel = ref.watch(categoryLabelProvider(
                CategoryLabelKey(key: cat, activeRoomId: roomId)));
            final limit = (b['budget_limit'] as num?)?.toDouble() ?? 0;
            final budgetCurrency = b['currency'] as String? ?? currency;
            final String Function(double) rowFmt = budgetCurrency == currency
                ? fmt
                : (v) => formatMoney(v, budgetCurrency);
            final spent = spendMap['${cat ?? ''}|$budgetCurrency'] ?? 0;
            final ratio = limit <= 0 ? 0.0 : (spent / limit).clamp(0.0, 1.0);
            final isOver = limit > 0 && spent >= limit;
            final isNear = !isOver && ratio >= 0.8;
            final progressColor = isOver
                ? c.danger
                : isNear
                    ? c.warning
                    : style.tint;
            final now = DateTime.now();
            final period = BudgetPeriodX.fromWire(b['period'] as String?);
            final resetDay = ((b['reset_day'] as num?) ?? 1).toInt();
            final customDays = (b['custom_days'] as num?)?.toInt();
            final winStart = budgetWindowStart(
              period: period,
              resetDay: resetDay,
              customDays: customDays,
              now: now,
            );
            final cycleLen = switch (period) {
              BudgetPeriod.weekly => 7,
              BudgetPeriod.monthly =>
                DateTime(winStart.year, winStart.month + 1, winStart.day)
                    .difference(winStart)
                    .inDays,
              BudgetPeriod.yearly => DateTime(now.year + 1, 1, 1)
                  .difference(DateTime(now.year, 1, 1))
                  .inDays,
              BudgetPeriod.custom => customDays ?? 30,
            };
            final cycleEnd = winStart.add(Duration(days: cycleLen));
            final daysLeft = cycleEnd.difference(now).inDays;
            final resetsLabel = daysLeft <= 0
                ? 'resets today'
                : daysLeft == 1
                    ? 'resets tomorrow'
                    : 'resets in ${daysLeft}d';
            final durationLabel = '${period.label} · $resetsLabel';
            return Container(
              margin: const EdgeInsets.only(top: LoitSpacing.s2),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.borderSubtle),
                borderRadius: LoitRadius.brM,
              ),
              clipBehavior: Clip.antiAlias,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isArchived
                      ? null
                      : () => context.push(
                            '/rooms/$roomId/budgets/${b['id']}/edit',
                            extra: <String, dynamic>{
                              'budget': b,
                              'currency': currency,
                            },
                          ),
                  child: Padding(
                    padding: const EdgeInsets.all(LoitSpacing.s3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: style.tint.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Icon(style.icon, size: 18, color: style.tint),
                            ),
                            const SizedBox(width: LoitSpacing.s3),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(budgetLabel,
                                      style: LoitTypography.bodyM
                                          .copyWith(color: c.contentPrimary)),
                                  const SizedBox(height: 2),
                                  Text(durationLabel,
                                      style: LoitTypography.bodyS.copyWith(
                                        color: c.contentTertiary,
                                      )),
                                ],
                              ),
                            ),
                            Text(rowFmt(limit),
                                style: LoitTypography.bodyM.copyWith(
                                    color: c.contentPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ])),
                            if (!isArchived) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.chevron_right,
                                  size: 18, color: c.contentTertiary),
                            ],
                          ],
                        ),
                        const SizedBox(height: LoitSpacing.s2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 6,
                            backgroundColor: c.borderSubtle,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(progressColor),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${rowFmt(spent)} spent',
                              style: LoitTypography.bodyS.copyWith(
                                color: isOver
                                    ? c.danger
                                    : isNear
                                        ? c.warning
                                        : c.contentSecondary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                            Text(
                              limit <= 0
                                  ? '—'
                                  : '${(ratio * 100).round()}%',
                              style: LoitTypography.bodyS.copyWith(
                                color: c.contentTertiary,
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab({
    required this.roomId,
    required this.isCreator,
    required this.isArchived,
  });
  final String roomId;
  final bool isCreator;
  final bool isArchived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final asyncCats = ref.watch(userCategoriesProvider);
    final pending = ref.watch(pendingCategoryDeletesProvider);
    final canManage = isCreator && !isArchived;
    return asyncCats.when(
      skipLoadingOnReload: true,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (cats) {
        final roomCats = cats
            .where((cat) => cat.roomId == roomId && !pending.contains(cat.id))
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        final expense = roomCats.where((cat) => cat.isExpense).toList();
        final income = roomCats.where((cat) => cat.isIncome).toList();

        if (roomCats.isEmpty) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s7),
            children: [
              const LoitEmptyState(
                icon: Icons.category_outlined,
                title: 'No categories yet',
                body:
                    'Add room-specific categories so members tag transactions consistently.',
              ),
              if (canManage) ...[
                const SizedBox(height: LoitSpacing.s4),
                Center(
                  child: FilledButton.icon(
                    onPressed: () =>
                        context.push('/rooms/$roomId/categories/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('New category'),
                  ),
                ),
              ],
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
              LoitSpacing.s4, LoitSpacing.s2, LoitSpacing.s4, 100),
          children: [
            if (expense.isNotEmpty) ...[
              _SectionLabel(label: 'EXPENSE', count: expense.length),
              _CategoryGroup(
                roomId: roomId,
                cats: expense,
                canManage: canManage,
              ),
            ],
            if (income.isNotEmpty) ...[
              const SizedBox(height: LoitSpacing.s4),
              _SectionLabel(label: 'INCOME', count: income.length),
              _CategoryGroup(
                roomId: roomId,
                cats: income,
                canManage: canManage,
              ),
            ],
            if (!canManage) ...[
              const SizedBox(height: LoitSpacing.s4),
              Container(
                padding: const EdgeInsets.all(LoitSpacing.s3),
                decoration: BoxDecoration(
                  color: c.muted,
                  borderRadius: LoitRadius.brM,
                ),
                child: Text(
                  isArchived
                      ? 'Room is archived. Categories are read-only.'
                      : 'Only the room creator can add or edit categories.',
                  style: LoitTypography.bodyS
                      .copyWith(color: c.contentSecondary),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.count});
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, LoitSpacing.s3, 4, 6),
      child: Row(
        children: [
          Text(label,
              style: LoitTypography.labelS.copyWith(
                  color: c.contentSecondary, letterSpacing: 0.5)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: c.muted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('$count',
                style: LoitTypography.labelS
                    .copyWith(color: c.contentSecondary)),
          ),
        ],
      ),
    );
  }
}

class _CategoryGroup extends ConsumerWidget {
  const _CategoryGroup({
    required this.roomId,
    required this.cats,
    required this.canManage,
  });
  final String roomId;
  final List<UserCategory> cats;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.borderSubtle),
        borderRadius: LoitRadius.brM,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < cats.length; i++)
            _row(context, ref, cats[i], i != cats.length - 1),
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context, WidgetRef ref, UserCategory cat, bool divider) {
    final row = _CategoryRow(
      roomId: roomId,
      cat: cat,
      divider: divider,
      canManage: canManage,
    );
    if (!canManage) return row;
    final c = context.loitColors;
    return Dismissible(
      key: ValueKey(cat.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _scheduleDeleteWithUndo(context, ref, cat),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: c.danger,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: row,
    );
  }

  void _scheduleDeleteWithUndo(
      BuildContext context, WidgetRef ref, UserCategory cat) {
    const window = Duration(seconds: 4);
    ref
        .read(pendingCategoryDeletesProvider.notifier)
        .schedule(categoryId: cat.id, delay: window);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final controller = messenger.showSnackBar(
      SnackBar(
        duration: window,
        content: Text('Deleted "${cat.name}"'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => ref
              .read(pendingCategoryDeletesProvider.notifier)
              .undo(cat.id),
        ),
      ),
    );
    Future.delayed(window, () {
      controller.close();
    });
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.roomId,
    required this.cat,
    required this.divider,
    required this.canManage,
  });
  final String roomId;
  final UserCategory cat;
  final bool divider;
  final bool canManage;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final tap = canManage
        ? () => context.push('/rooms/$roomId/categories/${cat.id}/edit',
            extra: cat)
        : null;
    final body = InkWell(
      onTap: tap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: LoitSpacing.s4, vertical: LoitSpacing.s3),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cat.tintColor.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(cat.iconData, size: 18, color: cat.tintColor),
            ),
            const SizedBox(width: LoitSpacing.s3),
            Expanded(
              child: Text(cat.name,
                  style: LoitTypography.bodyM.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w500)),
            ),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: cat.tintColor,
                shape: BoxShape.circle,
                border: Border.all(color: c.borderSubtle),
              ),
            ),
            const SizedBox(width: LoitSpacing.s3),
            Icon(
              canManage ? Icons.chevron_right : Icons.lock_outline,
              size: canManage ? 18 : 14,
              color: c.contentTertiary,
            ),
          ],
        ),
      ),
    );

    if (!divider) return body;
    return Column(
      children: [
        body,
        Container(
          height: 1,
          color: c.borderSubtle,
          margin: const EdgeInsets.only(
              left: LoitSpacing.s4 + 36 + LoitSpacing.s3),
        ),
      ],
    );
  }
}
