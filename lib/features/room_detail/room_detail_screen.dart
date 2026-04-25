import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/services/room_service.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/room_providers.dart';
import '../rooms/invite_sheet.dart';

class RoomDetailScreen extends ConsumerWidget {
  const RoomDetailScreen({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomAsync = ref.watch(roomDetailProvider(roomId));
    final feedAsync = ref.watch(roomFeedProvider(roomId));
    final currentUser = ref.watch(currentUserProvider);

    return roomAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $e')),
      ),
      data: (room) {
        final name = room['name'] as String? ?? 'Room';
        final isCreator = room['created_by'] == currentUser?.id;
        final isArchived = room['is_archived'] as bool? ?? false;
        final members = (room['room_members'] as List?) ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text(name),
            actions: [
              if (!isArchived)
                IconButton(
                  icon: const Icon(Icons.person_add),
                  tooltip: 'Invite',
                  onPressed: () => _showInviteSheet(context, room),
                ),
              PopupMenuButton<String>(
                onSelected: (v) =>
                    _onMenuAction(context, ref, v, room),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'members',
                    child: Text('Members (${members.length})'),
                  ),
                  if (!isArchived)
                    const PopupMenuItem(
                      value: 'budgets',
                      child: Text('Room budgets'),
                    ),
                  if (isCreator && !isArchived)
                    const PopupMenuItem(
                      value: 'archive',
                      child: Text('Archive room'),
                    ),
                  if (!isCreator)
                    const PopupMenuItem(
                      value: 'leave',
                      child: Text('Leave room'),
                    ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(roomFeedProvider(roomId));
              ref.invalidate(roomDetailProvider(roomId));
            },
            child: feedAsync.when(
              loading: () => const _FeedSkeleton(),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Failed to load feed: $e'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(roomFeedProvider(roomId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (txns) => txns.isEmpty
                  ? _EmptyFeed(isArchived: isArchived)
                  : _FeedList(transactions: txns),
            ),
          ),
          floatingActionButton: isArchived
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _addExpense(context, ref, room),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
        );
      },
    );
  }

  void _showInviteSheet(BuildContext context, Map<String, dynamic> room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: InviteSheet(
          roomId: room['id'] as String,
          roomName: room['name'] as String? ?? 'Room',
        ),
      ),
    );
  }

  void _addExpense(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> room,
  ) {
    context.push(
      '/transactions/new',
      extra: <String, dynamic>{
        '_room_id': room['id'],
        '_room_name': room['name'],
        'currency': room['base_currency'] ?? 'IDR',
      },
    );
  }

  Future<void> _onMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    Map<String, dynamic> room,
  ) async {
    switch (action) {
      case 'members':
        _showMembers(context, room);
      case 'budgets':
        context.push('/rooms/$roomId/budgets');
      case 'archive':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Archive room?'),
            content: const Text(
              'Members will retain read-only access. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Archive'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          await RoomService().archiveRoom(roomId);
          ref.invalidate(myRoomsProvider);
          ref.invalidate(roomDetailProvider(roomId));
        }
      case 'leave':
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Leave room?'),
            content: const Text('You can rejoin via a new invite.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          await RoomService().leaveRoom(roomId);
          ref.invalidate(myRoomsProvider);
          if (context.mounted) context.go('/rooms');
        }
    }
  }

  void _showMembers(BuildContext context, Map<String, dynamic> room) {
    final members =
        (room['room_members'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Members',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final m in members)
              ListTile(
                leading: CircleAvatar(
                  backgroundImage: (m['users']?['avatar_url'] as String?)
                          ?.isNotEmpty ==
                      true
                      ? NetworkImage(m['users']['avatar_url'] as String)
                      : null,
                  child: (m['users']?['avatar_url'] as String?)
                              ?.isNotEmpty !=
                          true
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(
                  (m['users']?['name'] as String?)?.isNotEmpty == true
                      ? m['users']['name'] as String
                      : 'Member',
                ),
                trailing: Chip(
                  label: Text(
                    (m['role'] as String?) ?? 'member',
                  ),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({required this.transactions});
  final List<Map<String, dynamic>> transactions;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (_, i) => _TransactionCard(transaction: transactions[i]),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  const _TransactionCard({required this.transaction});
  final Map<String, dynamic> transaction;

  @override
  Widget build(BuildContext context) {
    final merchant = transaction['merchant'] as String?;
    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0;
    final currency = (transaction['currency'] as String?) ?? 'IDR';
    final category = transaction['category'] as String?;
    final createdAt = DateTime.tryParse(
      (transaction['created_at'] as String?) ?? '',
    );
    final user = transaction['users'] as Map<String, dynamic>?;
    final userName = (user?['name'] as String?)?.isNotEmpty == true
        ? user!['name'] as String
        : 'Member';
    final avatarUrl = user?['avatar_url'] as String?;

    final amtFmt = NumberFormat.simpleCurrency(name: currency);

    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            avatarUrl?.isNotEmpty == true ? NetworkImage(avatarUrl!) : null,
        child: avatarUrl?.isNotEmpty != true
            ? Text(userName[0].toUpperCase())
            : null,
      ),
      title: Text(merchant ?? category ?? 'Expense'),
      subtitle: Text(
        '$userName · ${category ?? 'other'}'
        '${createdAt != null ? ' · ${DateFormat.MMMd().add_jm().format(createdAt.toLocal())}' : ''}',
      ),
      trailing: Text(
        amtFmt.format(amount),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.isArchived});
  final bool isArchived;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No expenses yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            isArchived
                ? 'This room is archived'
                : 'Be the first to log an expense',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _FeedSkeleton extends StatelessWidget {
  const _FeedSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      itemBuilder: (_, __) => const _SkeletonTile(),
    );
  }
}

class _SkeletonTile extends StatefulWidget {
  const _SkeletonTile();

  @override
  State<_SkeletonTile> createState() => _SkeletonTileState();
}

class _SkeletonTileState extends State<_SkeletonTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_animation),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: baseColor),
        title: Container(
          height: 14,
          width: 120,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        subtitle: Container(
          height: 12,
          width: 180,
          margin: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        trailing: Container(
          height: 14,
          width: 60,
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
