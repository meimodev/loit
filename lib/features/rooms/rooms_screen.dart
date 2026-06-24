import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/pricing_constants.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/interaction_log_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../core/services/reachability_service.dart'
    show OnlineOnlyActionException;
import '../../l10n/l10n_x.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/presence_provider.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/widgets/loit_animations.dart';
import '../../shared/widgets/loit_empty_state.dart';
import '../../shared/widgets/room_error_state.dart';
import '../paywall/paywall_screen.dart';
import 'room_colors.dart';
import 'room_slot_sheet.dart';

class RoomsScreen extends ConsumerWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l = context.l10n;
    final rooms = ref.watch(myRoomsProvider);
    final invites = ref.watch(pendingInvitesProvider);

    final hasRooms = rooms.value?.isNotEmpty ?? false;
    final profile = ref.watch(userProfileProvider).value;
    final canCreate = profile?.canCreateRoom ?? true;
    final canBuySlot = profile?.canPurchaseRoomSlot ?? false;

    return Scaffold(
      backgroundColor: c.canvas,
      // Persistent create affordance once the user already has a room; the
      // empty state carries its own create CTA, so the FAB stays hidden there.
      // At the room-creation cap (ADR-0020) the FAB does not create: Pro opens
      // the buy-a-room-slot sheet, Free/Lite open the upgrade paywall.
      floatingActionButton: hasRooms
          ? FloatingActionButton.extended(
              // Theme sets a global CircleBorder for FABs, which clips the
              // extended pill — override to a stadium so the label fits.
              shape: const StadiumBorder(),
              onPressed: () {
                if (canCreate) {
                  context.push('/rooms/new');
                } else if (canBuySlot) {
                  showRoomSlotSheet(context);
                } else {
                  showPaywallSheet(context, feature: 'more_rooms');
                }
              },
              icon: const Icon(Icons.add),
              label: Text(l.roomsScreenCreateRoom),
            )
          : null,
      appBar: AppBar(
        title: Text(l.roomsScreenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: l.roomsScreenJoinRoom,
            onPressed: () => context.push('/rooms/join'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myRoomsProvider);
          ref.invalidate(pendingInvitesProvider);
          await ref.read(myRoomsProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: _MembershipCard(),
            ),
            SliverToBoxAdapter(
              child: invites.maybeWhen(
                data: (list) => LoitAnimatedReveal(
                  visible: list.isNotEmpty,
                  child: list.isEmpty
                      ? const SizedBox.shrink()
                      : LoitFadeSlideIn(
                          key: ValueKey('invites-${list.length}'),
                          child: _InvitesBanner(invites: list),
                        ),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ),
            rooms.when(
              skipLoadingOnReload: true,
              loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.all(LoitSpacing.s5),
                  child: LoitEmptyState(
                    icon: Icons.cloud_off_outlined,
                    title: l.roomsLoadErrorTitle,
                    body: l.roomsLoadError,
                    primaryCta: l.roomsLoadRetry,
                    onPrimaryCta: () {
                      ref.invalidate(myRoomsProvider);
                      ref.invalidate(pendingInvitesProvider);
                    },
                  ),
                ),
              ),
              data: (list) => list.isEmpty
                  ? SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(LoitSpacing.s5),
                        child: LoitEmptyState(
                          icon: Icons.group_outlined,
                          title: l.roomsScreenNoRooms,
                          body: l.roomsScreenEmptyBody,
                          primaryCta: l.roomsScreenCreateRoom,
                          onPrimaryCta: () => context.push('/rooms/new'),
                          secondaryCta: l.roomsScreenJoinRoom,
                          onSecondaryCta: () => context.push('/rooms/join'),
                        ),
                      ),
                    )
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                          LoitSpacing.s4, LoitSpacing.s3, LoitSpacing.s4, 96),
                      sliver: SliverList.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final id = list[i]['id'] as String? ?? 'idx-$i';
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: LoitSpacing.s2),
                            child: LoitFadeSlideIn(
                              key: ValueKey('room-$id'),
                              delay: LoitMotion.staggerStep * i,
                              child: _RoomTile(room: list[i]),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomTile extends ConsumerWidget {
  const _RoomTile({required this.room});
  final Map<String, dynamic> room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l = context.l10n;
    final id = room['id'] as String? ?? '';
    final name = room['name'] as String? ?? l.roomTileUntitled;
    final baseCurrency = (room['base_currency'] as String?) ?? 'IDR';
    final createdBy = room['created_by'] as String?;
    final members =
        (room['room_members'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    final memberCount = members.length;
    final isArchived = room['is_archived'] as bool? ?? false;
    final color = RoomColors.forId(id);

    final currentUserId = ref.watch(currentUserProvider)?.id;
    final isOwner = createdBy != null && createdBy == currentUserId;

    // Presence — count members of this room that are online right now,
    // excluding self (we already know we're online, so our own presence is
    // not a signal worth showing on the list).
    final onlineIds = ref.watch(onlineUsersProvider).value ?? const <String>{};
    final memberIds = members
        .map((m) => m['user_id'] as String?)
        .whereType<String>()
        .toSet();
    final othersOnline = memberIds
        .intersection(onlineIds)
        .where((id) => id != currentUserId)
        .length;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isArchived ? c.muted : color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'R',
                    style: LoitTypography.titleM.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
                if (othersOnline > 0 && !isArchived)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: c.surface,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const LoitPulseDot(
                        color: Color(0xFF22C55E),
                        size: 10,
                        maxRing: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: LoitSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(name,
                            style: LoitTypography.bodyL.copyWith(
                                color: c.contentPrimary,
                                fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (baseCurrency != 'IDR') ...[
                        const SizedBox(width: LoitSpacing.s2),
                        _Pill(
                            label: baseCurrency, color: c.contentSecondary),
                      ],
                      if (isArchived) ...[
                        const SizedBox(width: 4),
                        _Pill(
                            label: l.roomTileArchivedLabel.toUpperCase(),
                            color: c.warning),
                      ],
                    ],
                  ),
                  const SizedBox(height: LoitSpacing.s2),
                  Wrap(
                    spacing: LoitSpacing.s3,
                    runSpacing: 4,
                    children: [
                      _MetaItem(
                        icon: Icons.group_outlined,
                        text: l.roomsScreenMembers(memberCount),
                      ),
                      if (isOwner)
                        _MetaItem(
                            icon: Icons.shield_outlined,
                            text: l.roomTileYouOwn),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: LoitSpacing.s2),
            Icon(Icons.chevron_right, size: 18, color: c.contentTertiary),
          ],
        ),
      ),
    );
  }
}

class _MembershipCard extends ConsumerWidget {
  const _MembershipCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l = context.l10n;
    final profile = ref.watch(userProfileProvider).value;
    final tier = profile?.tier ?? 'free';
    // Room-creation cap (ADR-0020): counts lifetime-created rooms, not
    // membership. Effective cap = base + purchased slots.
    final created = profile?.roomsCreatedTotal ?? 0;
    final limit = profile?.effectiveRoomCap ?? PricingConstants.roomCapFree;
    final atLimit = !(profile?.canCreateRoom ?? true);
    final canBuySlot = profile?.canPurchaseRoomSlot ?? false;
    final nearLimit = !atLimit && limit > 0 && created / limit >= 0.8;
    final tierLabel = switch (tier) {
      'pro' => 'Pro',
      'lite' => 'Lite',
      _ => 'Free',
    };
    final tierColor = switch (tier) {
      'pro' => c.brand,
      'lite' => c.info,
      _ => c.contentSecondary,
    };
    final usageText = l.roomMembershipUsageLimited(created, limit);

    // Quiet by default: the quota is secondary to the rooms list, so it
    // rides as a single slim line. It only earns a full bordered card with
    // progress + upgrade once you're close to being blocked.
    if (!atLimit && !nearLimit) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
            LoitSpacing.s4, LoitSpacing.s4, LoitSpacing.s4, 0),
        child: Row(
          children: [
            Icon(Icons.workspace_premium_outlined, size: 16, color: tierColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                usageText,
                style:
                    LoitTypography.bodyS.copyWith(color: c.contentSecondary),
              ),
            ),
            _Pill(label: tierLabel.toUpperCase(), color: tierColor),
          ],
        ),
      );
    }

    final progress =
        limit == 0 ? 0.0 : (created / limit).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.fromLTRB(
          LoitSpacing.s4, LoitSpacing.s4, LoitSpacing.s4, 0),
      padding: const EdgeInsets.all(LoitSpacing.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: LoitRadius.brM,
        border: Border.all(
          color: atLimit ? c.warning.withValues(alpha: 0.5) : c.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_outlined,
                  size: 18, color: tierColor),
              const SizedBox(width: 6),
              Text(
                l.roomMembershipTitle,
                style: LoitTypography.bodyS
                    .copyWith(color: c.contentSecondary),
              ),
              const Spacer(),
              _Pill(label: tierLabel.toUpperCase(), color: tierColor),
            ],
          ),
          const SizedBox(height: LoitSpacing.s3),
          Text(
            usageText,
            style: LoitTypography.bodyL.copyWith(
                color: c.contentPrimary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: LoitSpacing.s2),
          LoitAnimatedProgress(
            value: progress,
            color: atLimit ? c.warning : tierColor,
            background: c.muted,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          if (atLimit) ...[
            const SizedBox(height: LoitSpacing.s3),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.roomMembershipAtLimit(tierLabel),
                    style: LoitTypography.bodyS
                        .copyWith(color: c.contentSecondary),
                  ),
                ),
                TextButton(
                  onPressed: () => canBuySlot
                      ? showRoomSlotSheet(context)
                      : showPaywallSheet(context, feature: 'more_rooms'),
                  child: Text(canBuySlot ? l.roomSlotBuyShort : l.roomUpgrade),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: LoitTypography.labelS.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c.contentTertiary),
        const SizedBox(width: 4),
        Text(text,
            style: LoitTypography.bodyS.copyWith(color: c.contentTertiary)),
      ],
    );
  }
}

class _InvitesBanner extends ConsumerWidget {
  const _InvitesBanner({required this.invites});
  final List<Map<String, dynamic>> invites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l = context.l10n;
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
                  l.roomInvitesPending(invites.length),
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
                          l.roomUnknownRoom,
                      style: LoitTypography.bodyS
                          .copyWith(color: c.contentPrimary),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _accept(context, ref, invite),
                    child: Text(l.roomsScreenAcceptInvite),
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
    final l = context.l10n;
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
    } on OnlineOnlyActionException {
      if (context.mounted) showRoomOnlineOnlySnack(context);
    } catch (e) {
      InteractionLog.error(
          action: 'room_join', screen: 'rooms', message: '$e');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.roomJoinFailed)));
      }
    }
  }
}
