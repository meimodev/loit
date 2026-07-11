import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../core/services/reachability_service.dart' show isNetworkError;
import '../../l10n/l10n_x.dart';
import '../../shared/widgets/room_error_state.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/widgets/loit_button.dart';

/// "Undang anggota" — QR-only invite (ADR 0031). The QR payload stays
/// URL-shaped (`https://loit.app/invite/{token}`) so the scanner's
/// `isLoitInviteUrl` filter and previously printed QRs keep working, but no
/// link is surfaced or shareable from here.
class RoomInviteScreen extends ConsumerStatefulWidget {
  const RoomInviteScreen({super.key, required this.roomId});
  final String roomId;

  @override
  ConsumerState<RoomInviteScreen> createState() => _RoomInviteScreenState();
}

class _RoomInviteScreenState extends ConsumerState<RoomInviteScreen> {
  String? _token;
  bool _regenerating = false;

  Future<void> _regen() async {
    setState(() => _regenerating = true);
    try {
      final newToken = await Supabase.instance.client.rpc(
        'regenerate_room_invite_token',
        params: {'p_room_id': widget.roomId},
      ) as String;
      if (mounted) setState(() => _token = newToken);
      ref.invalidate(roomDetailProvider(widget.roomId));
    } catch (e) {
      if (mounted) {
        // Regenerate is a direct room-write RPC (online-only, ADR 0014): map a
        // network failure to the canonical message; keep real errors otherwise.
        if (isNetworkError(e)) {
          showRoomOnlineOnlySnack(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(context.l10n.roomInviteRegenFailed(e.toString()))),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider).value;

    return roomAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: RoomErrorState(
            error: e,
            onRetry: () => ref.invalidate(roomDetailProvider(widget.roomId)),
          ),
        ),
      ),
      data: (room) {
        final name = room['name'] as String? ?? l.roomDetailRoomFallback;
        final token = _token ?? room['invite_token'] as String? ?? '';
        final isCreator = room['created_by'] == user?.id;
        final memberCount =
            (room['room_members'] as List?)?.length ?? 1;
        // Member cap is enforced server-side by the room creator's tier
        // (accept_room_invite: free/lite 3, pro 7, team 15). The client only
        // knows the viewer's own tier, so the cap shows for the creator and
        // falls back to a plain count for invited admins.
        final memberCap = isCreator
            ? switch (profile?.tier) {
                'team' => 15,
                'pro' => 7,
                _ => 3,
              }
            : null;

        return Scaffold(
          backgroundColor: c.canvas,
          appBar: AppBar(
            title: Text(l.roomInviteTitle),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(LoitSpacing.s5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: LoitSpacing.s4),
                  Text(name,
                      textAlign: TextAlign.center,
                      style: LoitTypography.titleL.copyWith(
                          color: c.contentPrimary,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: LoitSpacing.s4),
                  Container(
                    width: 260,
                    height: 260,
                    padding: const EdgeInsets.all(LoitSpacing.s3),
                    decoration: BoxDecoration(
                      // Scanners need dark-on-light; keep white in dark theme too.
                      color: Colors.white,
                      border: Border.all(color: c.borderSubtle),
                      borderRadius: LoitRadius.brM,
                    ),
                    child: token.isEmpty
                        ? Center(child: Text(l.roomInviteNoToken))
                        : QrImageView(
                            data: 'https://loit.app/invite/$token',
                            backgroundColor: Colors.white,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                  ),
                  const SizedBox(height: LoitSpacing.s4),
                  Text(l.roomScanToJoin,
                      style: LoitTypography.titleM.copyWith(
                          color: c.contentPrimary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    l.roomInviteInstruction,
                    textAlign: TextAlign.center,
                    style: LoitTypography.bodyS
                        .copyWith(color: c.contentSecondary),
                  ),
                  if (isCreator) ...[
                    const SizedBox(height: LoitSpacing.s3),
                    LoitButton.tertiary(
                      label: _regenerating
                          ? l.roomInviteRegenerating
                          : l.roomInviteRegen,
                      onPressed: _regenerating ? null : _regen,
                    ),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(LoitSpacing.s3),
                    decoration: BoxDecoration(
                      color: c.muted,
                      borderRadius: LoitRadius.brM,
                    ),
                    child: Text(
                      memberCap != null
                          ? l.roomInviteMemberCap(memberCount, memberCap)
                          : l.roomInviteMemberCount(memberCount),
                      style: LoitTypography.bodyS
                          .copyWith(color: c.contentSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
