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
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/widgets/loit_button.dart';
import '../../shared/widgets/loit_input.dart';

class RoomJoinScreen extends ConsumerStatefulWidget {
  const RoomJoinScreen({super.key});

  @override
  ConsumerState<RoomJoinScreen> createState() => _RoomJoinScreenState();
}

class _RoomJoinScreenState extends ConsumerState<RoomJoinScreen> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String? _extractToken(String raw) {
    final s = raw.trim();
    if (s.isEmpty) return null;
    // Accept full URL or bare token
    final uri = Uri.tryParse(s);
    if (uri != null && uri.pathSegments.length >= 2) {
      final i = uri.pathSegments.indexOf('invite');
      if (i >= 0 && i + 1 < uri.pathSegments.length) {
        return uri.pathSegments[i + 1];
      }
      final r = uri.pathSegments.indexOf('r');
      if (r >= 0 && r + 1 < uri.pathSegments.length) {
        return uri.pathSegments[r + 1];
      }
    }
    return s;
  }

  Future<void> _join() async {
    final token = _extractToken(_ctrl.text);
    if (token == null) {
      setState(() => _error = 'Paste an invite link or token');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final roomId =
          await ref.read(roomServiceProvider).acceptInvite(token);
      Analytics.roomJoined();
      InteractionLog.success(
          action: 'room_joined', screen: 'join_room', message: '$roomId');
      ref.invalidate(myRoomsProvider);
      ref.invalidate(pendingInvitesProvider);
      ref.invalidate(userCategoriesProvider);
      if (roomId != null) ref.invalidate(roomDetailProvider(roomId));
      if (mounted && roomId != null) {
        context.pushReplacement('/rooms/$roomId');
      } else if (mounted) {
        setState(() => _error = 'Invite is invalid or expired');
      }
    } catch (e) {
      InteractionLog.error(
          action: 'room_join', screen: 'join_room', message: '$e');
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Join room'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(LoitSpacing.s4),
        children: [
          Container(
            padding: const EdgeInsets.all(LoitSpacing.s4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: LoitRadius.brM,
              border: Border.all(color: c.borderSubtle),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.qr_code_2, size: 36, color: c.brand),
                const SizedBox(height: LoitSpacing.s2),
                Text('Paste an invite link or token',
                    style: LoitTypography.titleM.copyWith(
                        color: c.contentPrimary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'You can scan a QR from the inviter or paste the loit.app/invite/… URL below.',
                  style: LoitTypography.bodyS
                      .copyWith(color: c.contentSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: LoitSpacing.s5),
          LoitInput(
            label: 'Invite link or token',
            controller: _ctrl,
            placeholder: 'loit.app/invite/…',
            error: _error,
            autofocus: true,
            onSubmitted: (_) => _join(),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(LoitSpacing.s4),
          decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.borderSubtle))),
          child: LoitButton.primary(
            size: LoitButtonSize.l,
            fullWidth: true,
            loading: _busy,
            label: 'Join room',
            onPressed:
                _ctrl.text.trim().isEmpty || _busy ? null : _join,
          ),
        ),
      ),
    );
  }
}
