import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/services/room_service.dart';
import '../../core/theme/loit_categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/widgets/loit_empty_state.dart';
import '../rooms/room_colors.dart';

class RoomDetailScreen extends ConsumerStatefulWidget {
  const RoomDetailScreen({super.key, required this.roomId, this.initialTab = 0});
  final String roomId;
  final int initialTab;

  @override
  ConsumerState<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends ConsumerState<RoomDetailScreen> {
  late int _tab = widget.initialTab.clamp(0, 2);

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
    final feedAsync = ref.watch(roomFeedProvider(widget.roomId));
    final budgetsAsync = ref.watch(roomBudgetsProvider(widget.roomId));
    final user = ref.watch(currentUserProvider);

    return roomAsync.when(
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
        final fmt = NumberFormat.simpleCurrency(name: currency);

        return Scaffold(
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
                  onInvite: () =>
                      context.push('/rooms/${widget.roomId}/invite'),
                  onArchive: () => _confirmArchive(context),
                  onLeave: () => _confirmLeave(context),
                  onMembers: () => _showMembers(context, members),
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
                    },
                    child: _tabBody(
                      feedAsync: feedAsync,
                      budgetsAsync: budgetsAsync,
                      members: members,
                      currentUserId: user?.id,
                      accent: accent,
                      fmt: fmt,
                      isArchived: isArchived,
                    ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: isArchived || _tab != 0
              ? null
              : FloatingActionButton(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  onPressed: () => _addExpense(room),
                  child: const Icon(Icons.add),
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
    required Color accent,
    required NumberFormat fmt,
    required bool isArchived,
  }) {
    switch (_tab) {
      case 1:
        return _BudgetTab(
            roomId: widget.roomId,
            budgetsAsync: budgetsAsync,
            fmt: fmt);
      case 2:
        return _BalancesTab(
          roomId: widget.roomId,
          feedAsync: feedAsync,
          members: members,
          currentUserId: currentUserId,
          fmt: fmt,
        );
      case 0:
      default:
        return _FeedTab(
          feedAsync: feedAsync,
          members: members,
          accent: accent,
          fmt: fmt,
          isArchived: isArchived,
          currentUserId: currentUserId,
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
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Members',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            for (final m in members)
              ListTile(
                leading: _MemberAvatar(member: m, size: 36),
                title: Text(_memberName(m)),
                trailing: Text((m['role'] as String?) ?? 'member'),
              ),
          ],
        ),
      ),
    );
  }
}

String _memberName(Map<String, dynamic> m) {
  final n = (m['users']?['name'] as String?) ?? '';
  return n.isNotEmpty ? n : 'Member';
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.accent,
    required this.members,
    required this.isCreator,
    required this.isArchived,
    required this.onInvite,
    required this.onArchive,
    required this.onLeave,
    required this.onMembers,
  });
  final String name;
  final Color accent;
  final List<Map<String, dynamic>> members;
  final bool isCreator;
  final bool isArchived;
  final VoidCallback onInvite;
  final VoidCallback onArchive;
  final VoidCallback onLeave;
  final VoidCallback onMembers;

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
                onPressed: () => context.pop(),
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
                  child: Text(
                    '${members.length} member${members.length == 1 ? '' : 's'}',
                    style: LoitTypography.bodyS
                        .copyWith(color: c.contentSecondary),
                  ),
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

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.member, required this.size});
  final Map<String, dynamic> member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final url = member['users']?['avatar_url'] as String?;
    final name = _memberName(member);
    final color = RoomColors.forId(name);
    return Container(
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
    const labels = ['Feed', 'Budget', 'Balances'];
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

class _FeedTab extends StatelessWidget {
  const _FeedTab({
    required this.feedAsync,
    required this.members,
    required this.accent,
    required this.fmt,
    required this.isArchived,
    required this.currentUserId,
  });
  final AsyncValue<List<Map<String, dynamic>>> feedAsync;
  final List<Map<String, dynamic>> members;
  final Color accent;
  final NumberFormat fmt;
  final bool isArchived;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (txns) {
        if (txns.isEmpty) {
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s7),
                child: LoitEmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: isArchived ? 'No activity' : 'No activity yet',
                  body: isArchived
                      ? 'This room is archived'
                      : 'Be the first to log an expense or income.',
                ),
              ),
            ],
          );
        }
        double expensesTotal = 0;
        double incomeTotal = 0;
        final perMember = <String, double>{};
        for (final t in txns) {
          final amt = (t['amount'] as num?)?.toDouble() ?? 0;
          if (amt < 0) {
            incomeTotal += amt.abs();
          } else {
            expensesTotal += amt;
          }
          final uid = t['user_id'] as String?;
          if (uid == null || amt < 0) continue;
          perMember[uid] = (perMember[uid] ?? 0) + amt;
        }
        final grouped = _groupByDay(txns);
        return ListView(
          padding: const EdgeInsets.fromLTRB(
              LoitSpacing.s4, 0, LoitSpacing.s4, 100),
          children: [
            _TotalSpentCard(
              total: expensesTotal,
              income: incomeTotal,
              perMember: perMember,
              members: members,
              fmt: fmt,
            ),
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
                  txns: entry.value,
                  fmt: fmt,
                  currentUserId: currentUserId),
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

class _TotalSpentCard extends StatelessWidget {
  const _TotalSpentCard({
    required this.total,
    required this.income,
    required this.perMember,
    required this.members,
    required this.fmt,
  });
  final double total;
  final double income;
  final Map<String, double> perMember;
  final List<Map<String, dynamic>> members;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final incomeColor = const Color(0xFF2F8F5E);
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
          Text('TOTAL SPENT',
              style: LoitTypography.labelS.copyWith(
                  color: c.contentSecondary, letterSpacing: 0.4)),
          const SizedBox(height: 4),
          Text(fmt.format(total),
              style: LoitTypography.titleL.copyWith(
                  color: c.contentPrimary,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()])),
          if (income > 0) ...[
            const SizedBox(height: LoitSpacing.s2),
            Row(
              children: [
                Icon(Icons.trending_up, size: 14, color: incomeColor),
                const SizedBox(width: 6),
                Text(
                  'Income · ${fmt.format(income)}',
                  style: LoitTypography.bodyS.copyWith(
                    color: incomeColor,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Net ${fmt.format(income - total)}',
                  style: LoitTypography.bodyS.copyWith(
                    color: c.contentSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
          if (perMember.isNotEmpty) ...[
            const SizedBox(height: LoitSpacing.s2),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                for (final m in members)
                  _MemberSplitChip(
                    name: _memberName(m),
                    amount: perMember[m['user_id']] ?? 0,
                    fmt: fmt,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberSplitChip extends StatelessWidget {
  const _MemberSplitChip(
      {required this.name, required this.amount, required this.fmt});
  final String name;
  final double amount;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return RichText(
      text: TextSpan(
        style:
            LoitTypography.bodyS.copyWith(color: c.contentSecondary),
        children: [
          TextSpan(text: '$name: '),
          TextSpan(
            text: fmt.format(amount),
            style: TextStyle(
                color: c.contentPrimary,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

class _DayGroup extends StatelessWidget {
  const _DayGroup(
      {required this.txns, required this.fmt, required this.currentUserId});
  final List<Map<String, dynamic>> txns;
  final NumberFormat fmt;
  final String? currentUserId;

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
              tx: txns[i],
              isLast: i == txns.length - 1,
              fmt: fmt,
              currentUserId: currentUserId,
            ),
        ],
      ),
    );
  }
}

class _RoomTxRow extends StatelessWidget {
  const _RoomTxRow(
      {required this.tx,
      required this.isLast,
      required this.fmt,
      required this.currentUserId});
  final Map<String, dynamic> tx;
  final bool isLast;
  final NumberFormat fmt;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
    // Prefer explicit type field; fall back to sign heuristic for legacy rows.
    final txType = tx['type'] as String? ?? (amount < 0 ? 'income' : 'expense');
    final isIncome = txType == 'income';
    final isTransfer = txType == 'transfer';
    final notes = (tx['notes'] as String?)?.trim();
    final merchant = (notes != null && notes.isNotEmpty)
        ? notes.split('\n').first
        : (isTransfer ? 'Transfer' : isIncome ? 'Income' : 'Expense');
    final cat = tx['category'] as String?;
    final style = LoitCategories.resolve(cat);
    final user = tx['users'] as Map<String, dynamic>?;
    final payer = (user?['name'] as String?) ?? 'Member';
    final isYou = tx['user_id'] == currentUserId;
    final incomeColor = const Color(0xFF2F8F5E);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s4, vertical: LoitSpacing.s3),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: c.borderSubtle),
        ),
      ),
      child: Row(
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
                Text(merchant,
                    style: LoitTypography.bodyM.copyWith(
                        color: c.contentPrimary,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  isTransfer
                      ? '${isYou ? 'Your' : "$payer's"} transfer'
                      : isIncome
                          ? '${isYou ? 'You' : payer} received'
                          : '${isYou ? 'You' : payer} paid · split equally',
                  style: LoitTypography.bodyS
                      .copyWith(color: c.contentSecondary),
                ),
              ],
            ),
          ),
          Text(
            '${isTransfer ? '' : isIncome ? '+' : ''}${fmt.format(amount.abs())}',
            style: LoitTypography.bodyM.copyWith(
                color: isTransfer
                    ? c.contentSecondary
                    : isIncome
                        ? incomeColor
                        : c.contentPrimary,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ],
      ),
    );
  }
}

class _BudgetTab extends StatelessWidget {
  const _BudgetTab({
    required this.roomId,
    required this.budgetsAsync,
    required this.fmt,
  });
  final String roomId;
  final AsyncValue<List<Map<String, dynamic>>> budgetsAsync;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return budgetsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (list) {
        if (list.isEmpty) {
          return ListView(children: const [
            Padding(
              padding: EdgeInsets.symmetric(vertical: LoitSpacing.s7),
              child: LoitEmptyState(
                icon: Icons.savings_outlined,
                title: 'No budgets set',
                body: 'Set category caps so the room knows when to slow down.',
              ),
            ),
          ]);
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
              LoitSpacing.s4, 0, LoitSpacing.s4, 100),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final b = list[i];
            final cat = b['category'] as String?;
            final style = LoitCategories.resolve(cat);
            final limit = (b['budget_limit'] as num?)?.toDouble() ?? 0;
            return Container(
              margin: const EdgeInsets.only(top: LoitSpacing.s2),
              padding: const EdgeInsets.all(LoitSpacing.s3),
              decoration: BoxDecoration(
                color: c.surface,
                border: Border.all(color: c.borderSubtle),
                borderRadius: LoitRadius.brM,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: style.tint.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child:
                        Icon(style.icon, size: 18, color: style.tint),
                  ),
                  const SizedBox(width: LoitSpacing.s3),
                  Expanded(
                      child: Text(style.label,
                          style: LoitTypography.bodyM
                              .copyWith(color: c.contentPrimary))),
                  Text(fmt.format(limit),
                      style: LoitTypography.bodyM.copyWith(
                          color: c.contentPrimary,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _BalancesTab extends StatelessWidget {
  const _BalancesTab({
    required this.roomId,
    required this.feedAsync,
    required this.members,
    required this.currentUserId,
    required this.fmt,
  });
  final String roomId;
  final AsyncValue<List<Map<String, dynamic>>> feedAsync;
  final List<Map<String, dynamic>> members;
  final String? currentUserId;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (txns) {
        final balances = _computeBalances(txns, members);
        final myBalance = currentUserId == null
            ? 0.0
            : (balances[currentUserId] ?? 0.0);
        final settlements = _suggestSettlements(balances, members);

        return ListView(
          padding: const EdgeInsets.fromLTRB(
              LoitSpacing.s4, LoitSpacing.s3, LoitSpacing.s4, 100),
          children: [
            Center(
              child: Column(
                children: [
                  Text('YOUR BALANCE',
                      style: LoitTypography.labelS.copyWith(
                          color: c.contentSecondary, letterSpacing: 0.4)),
                  const SizedBox(height: 4),
                  Text(
                    (myBalance >= 0 ? '+ ' : '− ') +
                        fmt.format(myBalance.abs()),
                    style: LoitTypography.titleL.copyWith(
                      color: myBalance >= 0 ? c.success : c.danger,
                      fontWeight: FontWeight.w600,
                      fontSize: 32,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    myBalance > 0
                        ? 'You are owed in this room'
                        : myBalance < 0
                            ? 'You owe in this room'
                            : 'You are settled',
                    style: LoitTypography.bodyS
                        .copyWith(color: c.contentSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: LoitSpacing.s5),
            Text('SUGGESTED SETTLEMENTS',
                style: LoitTypography.labelS.copyWith(
                    color: c.contentSecondary, letterSpacing: 0.5)),
            const SizedBox(height: LoitSpacing.s2),
            if (settlements.isEmpty)
              Container(
                padding: const EdgeInsets.all(LoitSpacing.s4),
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.borderSubtle),
                  borderRadius: LoitRadius.brM,
                ),
                child: Text('Everyone is settled.',
                    style: LoitTypography.bodyM
                        .copyWith(color: c.contentSecondary)),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  border: Border.all(color: c.borderSubtle),
                  borderRadius: LoitRadius.brM,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (var i = 0; i < settlements.length; i++)
                      _SettlementRow(
                        s: settlements[i],
                        members: members,
                        currentUserId: currentUserId,
                        fmt: fmt,
                        isLast: i == settlements.length - 1,
                      ),
                  ],
                ),
              ),
            const SizedBox(height: LoitSpacing.s4),
            Container(
              padding: const EdgeInsets.all(LoitSpacing.s3),
              decoration: BoxDecoration(
                color: c.muted,
                borderRadius: LoitRadius.brM,
              ),
              child: Text(
                'LOIT records the settlement; the payment happens in your wallet of choice.',
                style: LoitTypography.bodyS
                    .copyWith(color: c.contentSecondary),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Equal-split heuristic: each tx is split equally among all members,
  /// payer gets credit for the full amount.
  Map<String, double> _computeBalances(
      List<Map<String, dynamic>> txns, List<Map<String, dynamic>> members) {
    final out = <String, double>{};
    if (members.isEmpty) return out;
    final memberIds =
        members.map((m) => m['user_id'] as String?).whereType<String>().toList();
    if (memberIds.isEmpty) return out;
    for (final id in memberIds) {
      out[id] = 0;
    }
    for (final t in txns) {
      final payer = t['user_id'] as String?;
      final amount = (t['amount'] as num?)?.toDouble() ?? 0;
      if (payer == null || amount <= 0) continue;
      final share = amount / memberIds.length;
      out[payer] = (out[payer] ?? 0) + amount;
      for (final m in memberIds) {
        out[m] = (out[m] ?? 0) - share;
      }
    }
    return out;
  }

  List<_Settlement> _suggestSettlements(
      Map<String, double> balances, List<Map<String, dynamic>> members) {
    final entries = balances.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final debtors = <MapEntry<String, double>>[];
    final creditors = <MapEntry<String, double>>[];
    for (final e in entries) {
      if (e.value < -0.01) debtors.add(e);
      if (e.value > 0.01) creditors.add(e);
    }
    final out = <_Settlement>[];
    var di = 0, ci = creditors.length - 1;
    final dvals = debtors.map((e) => e.value).toList();
    final cvals = creditors.map((e) => e.value).toList();
    while (di < debtors.length && ci >= 0) {
      final pay = (-dvals[di]).clamp(0, cvals[ci]).toDouble();
      if (pay < 0.01) break;
      out.add(_Settlement(
        from: debtors[di].key,
        to: creditors[ci].key,
        amount: pay,
      ));
      dvals[di] += pay;
      cvals[ci] -= pay;
      if (dvals[di].abs() < 0.01) di++;
      if (cvals[ci].abs() < 0.01) ci--;
    }
    return out;
  }
}

class _Settlement {
  _Settlement({required this.from, required this.to, required this.amount});
  final String from;
  final String to;
  final double amount;
}

class _SettlementRow extends StatelessWidget {
  const _SettlementRow({
    required this.s,
    required this.members,
    required this.currentUserId,
    required this.fmt,
    required this.isLast,
  });
  final _Settlement s;
  final List<Map<String, dynamic>> members;
  final String? currentUserId;
  final NumberFormat fmt;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final fromName = _nameFor(s.from, members);
    final toName = _nameFor(s.to, members);
    final fromIsYou = s.from == currentUserId;
    final toIsYou = s.to == currentUserId;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s4, vertical: LoitSpacing.s3),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast
              ? BorderSide.none
              : BorderSide(color: c.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          _MiniAvatar(name: fromName),
          const SizedBox(width: LoitSpacing.s2),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: LoitTypography.bodyS
                    .copyWith(color: c.contentPrimary),
                children: [
                  TextSpan(text: fromIsYou ? 'You' : fromName),
                  TextSpan(
                      text: ' pay ',
                      style: TextStyle(color: c.contentSecondary)),
                  TextSpan(text: toIsYou ? 'you' : toName),
                ],
              ),
            ),
          ),
          Text(
            fmt.format(s.amount),
            style: LoitTypography.bodyM.copyWith(
              color: c.contentPrimary,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  String _nameFor(String id, List<Map<String, dynamic>> members) {
    for (final m in members) {
      if (m['user_id'] == id) return _memberName(m);
    }
    return 'Member';
  }
}

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final color = RoomColors.forId(name);
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
