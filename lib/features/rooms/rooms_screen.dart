import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/interaction_log_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/widgets/connectivity_banner.dart';
import '../../shared/widgets/loit_empty_state.dart';
import 'room_colors.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final rooms = ref.watch(myRoomsProvider);
    final invites = ref.watch(pendingInvitesProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Join via link',
            onPressed: () => context.push('/rooms/join'),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New room',
            onPressed: () => context.push('/rooms/new'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myRoomsProvider);
          ref.invalidate(pendingInvitesProvider);
        },
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: ConnectivityBanner()),
            invites.maybeWhen(
              data: (list) => list.isEmpty
                  ? const SliverToBoxAdapter(child: SizedBox.shrink())
                  : SliverToBoxAdapter(child: _InvitesBanner(invites: list)),
              orElse: () =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
            rooms.when(
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(
                child: Center(child: Text('Error: $e')),
              ),
              data: (list) => list.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(LoitSpacing.s5),
                        child: LoitEmptyState(
                          icon: Icons.group_outlined,
                          title: 'No rooms yet',
                          body:
                              'Create a room to track shared expenses with friends or housemates.',
                          primaryCta: 'New room',
                          onPrimaryCta: () => context.push('/rooms/new'),
                          secondaryCta: 'Join via link',
                          onSecondaryCta: () => context.push('/rooms/join'),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          LoitSpacing.s4, LoitSpacing.s3, LoitSpacing.s4, 96),
                      sliver: SliverList.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: LoitSpacing.s2),
                          child: _RoomTile(room: list[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.room});
  final Map<String, dynamic> room;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final id = room['id'] as String? ?? '';
    final name = room['name'] as String? ?? 'Untitled';
    final members = room['room_members'] as List?;
    final memberCount = members?.length ?? 0;
    final isArchived = room['is_archived'] as bool? ?? false;
    final color = RoomColors.forId(id);

    return InkWell(
      onTap: () => context.push('/rooms/$id'),
      borderRadius: LoitRadius.brM,
      child: Container(
        padding: const EdgeInsets.all(LoitSpacing.s4),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.borderSubtle),
          borderRadius: LoitRadius.brM,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isArchived ? c.muted : color,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'R',
                style: LoitTypography.titleM.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: LoitSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(name,
                            style: LoitTypography.bodyL.copyWith(
                                color: c.contentPrimary,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Text('· $memberCount members',
                          style: LoitTypography.bodyS
                              .copyWith(color: c.contentTertiary)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isArchived ? 'Archived' : 'Tap to open feed',
                    style: LoitTypography.bodyS
                        .copyWith(color: c.contentSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.contentTertiary),
          ],
        ),
      ),
    );
  }
}

class _InvitesBanner extends ConsumerWidget {
  const _InvitesBanner({required this.invites});
  final List<Map<String, dynamic>> invites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(
          LoitSpacing.s4, LoitSpacing.s3, LoitSpacing.s4, 0),
      padding: const EdgeInsets.all(LoitSpacing.s3),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF4E0),
        borderRadius: LoitRadius.brM,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mail_outline,
                  size: 18, color: Color(0xFF7D5916)),
              const SizedBox(width: LoitSpacing.s2),
              Expanded(
                child: Text(
                  '${invites.length} pending invite${invites.length == 1 ? '' : 's'}',
                  style: LoitTypography.bodyM.copyWith(
                      color: const Color(0xFF7D5916),
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: LoitSpacing.s2),
          for (final invite in invites)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      (invite['rooms'] as Map?)?['name'] as String? ??
                          'Unknown room',
                      style: LoitTypography.bodyS
                          .copyWith(color: c.contentPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _accept(context, ref, invite),
                    child: const Text('Join'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _accept(BuildContext context, WidgetRef ref,
      Map<String, dynamic> invite) async {
    try {
      final roomId = await ref
          .read(roomServiceProvider)
          .acceptInvite(invite['invite_token'] as String);
      Analytics.roomJoined();
      InteractionLog.success(
          action: 'room_joined', screen: 'rooms', message: 'Joined $roomId');
      ref.invalidate(myRoomsProvider);
      ref.invalidate(pendingInvitesProvider);
      if (context.mounted && roomId != null) {
        context.push('/rooms/$roomId');
      }
    } catch (e) {
      InteractionLog.error(
          action: 'room_join', screen: 'rooms', message: '$e');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to join: $e')));
      }
    }
  }
}
