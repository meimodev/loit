import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/widgets/loit_button.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.roomInviteRegenFailed(e.toString()))),
        );
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

    return roomAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.l10n.commonErrorWithDetail('$e'))),
      ),
      data: (room) {
        final name = room['name'] as String? ?? 'Room';
        final token = _token ?? room['invite_token'] as String? ?? '';
        final url = 'https://loit.app/invite/$token';
        final isCreator = room['created_by'] == user?.id;
        final memberCount =
            (room['room_members'] as List?)?.length ?? 1;

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
                  Container(
                    width: 220,
                    height: 220,
                    padding: const EdgeInsets.all(LoitSpacing.s3),
                    decoration: BoxDecoration(
                      color: c.surface,
                      border: Border.all(color: c.borderSubtle),
                      borderRadius: LoitRadius.brM,
                    ),
                    child: token.isEmpty
                        ? Center(child: Text(context.l10n.roomInviteNoToken))
                        : QrImageView(
                            data: url,
                            backgroundColor: c.surface,
                          ),
                  ),
                  const SizedBox(height: LoitSpacing.s4),
                  Text(context.l10n.roomScanToJoin,
                      style: LoitTypography.titleM.copyWith(
                          color: c.contentPrimary,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    l.roomInviteBody,
                    textAlign: TextAlign.center,
                    style: LoitTypography.bodyS
                        .copyWith(color: c.contentSecondary),
                  ),
                  const SizedBox(height: LoitSpacing.s4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: LoitSpacing.s3, vertical: LoitSpacing.s3),
                    decoration: BoxDecoration(
                      color: c.surface,
                      border: Border.all(color: c.borderSubtle),
                      borderRadius: LoitRadius.brM,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            url,
                            overflow: TextOverflow.ellipsis,
                            style: LoitTypography.bodyS
                                .copyWith(color: c.contentPrimary),
                          ),
                        ),
                        const SizedBox(width: LoitSpacing.s2),
                        InkWell(
                          onTap: token.isEmpty
                              ? null
                              : () async {
                                  await Clipboard.setData(
                                      ClipboardData(text: url));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                            content: Text(context.l10n.roomInviteLinkCopied)));
                                  }
                                },
                          child: Text(context.l10n.roomCopy,
                              style: LoitTypography.labelS.copyWith(
                                  color: c.brand,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: LoitSpacing.s3),
                  LoitButton.secondary(
                    fullWidth: true,
                    icon: Icons.share,
                    label: l.roomInviteShare,
                    onPressed: token.isEmpty
                        ? null
                        : () => Share.share('Join $name on LOIT: $url'),
                  ),
                  if (isCreator) ...[
                    const SizedBox(height: LoitSpacing.s2),
                    LoitButton.tertiary(
                      label: _regenerating
                          ? 'Regenerating\u2026'
                          : 'Regenerate link',
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
                      'Free plan \u00b7 up to 3 members per room. Currently $memberCount.',
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
