import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/interaction_log_service.dart';
import '../../shared/providers/room_providers.dart';
import 'create_room_dialog.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(myRoomsProvider);
    final invites = ref.watch(pendingInvitesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rooms')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myRoomsProvider);
          ref.invalidate(pendingInvitesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Pending invites banner
            invites.when(
              data: (list) => list.isEmpty
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : SliverToBoxAdapter(
                      child: _InvitesBanner(invites: list),
                    ),
              loading: () =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            // Room list
            rooms.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
              data: (list) => list.isEmpty
                  ? const SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(),
                    )
                  : SliverList.builder(
                      itemCount: list.length,
                      itemBuilder: (_, i) => _RoomTile(room: list[i]),
                    ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Room'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => CreateRoomDialog(
        onCreated: (room) {
          Analytics.roomCreated();
          ref.invalidate(myRoomsProvider);
          context.push('/rooms/${room['id']}');
        },
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});
  final Map<String, dynamic> room;

  @override
  Widget build(BuildContext context) {
    final name = room['name'] as String? ?? 'Untitled';
    final members = room['room_members'] as List?;
    final memberCount = members?.length ?? 0;
    final isArchived = room['is_archived'] as bool? ?? false;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isArchived ? Colors.grey : null,
        child: Icon(isArchived ? Icons.archive : Icons.group),
      ),
      title: Text(name),
      subtitle: Text(
        '$memberCount member${memberCount == 1 ? '' : 's'}'
        '${isArchived ? ' · Archived' : ''}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => context.push('/rooms/${room['id']}'),
    );
  }
}

class _InvitesBanner extends ConsumerWidget {
  const _InvitesBanner({required this.invites});
  final List<Map<String, dynamic>> invites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${invites.length} pending invite${invites.length == 1 ? '' : 's'}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          for (final invite in invites) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    (invite['rooms'] as Map?)?['name'] as String? ??
                        'Unknown room',
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => _accept(context, ref, invite),
                  child: const Text('Join'),
                ),
              ],
            ),
            if (invite != invites.last) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  Future<void> _accept(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> invite,
  ) async {
    try {
      final roomId = await ref
          .read(roomServiceProvider)
          .acceptInvite(invite['invite_token'] as String);
      Analytics.roomJoined();
      InteractionLog.success(
        action: 'room_joined',
        screen: 'rooms',
        message: 'Joined room $roomId',
      );
      ref.invalidate(myRoomsProvider);
      ref.invalidate(pendingInvitesProvider);
      if (context.mounted && roomId != null) {
        context.push('/rooms/$roomId');
      }
    } catch (e) {
      InteractionLog.error(
        action: 'room_join',
        screen: 'rooms',
        message: '$e',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join: $e')),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('No rooms yet', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'Create a room to track shared expenses',
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
