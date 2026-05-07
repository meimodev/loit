import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/interaction_log_service.dart';
import '../../core/services/room_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/widgets/loit_button.dart';
import '../../shared/widgets/loit_input.dart';
import 'room_colors.dart';

class RoomCreateScreen extends ConsumerStatefulWidget {
  const RoomCreateScreen({super.key});

  @override
  ConsumerState<RoomCreateScreen> createState() => _RoomCreateScreenState();
}

class _RoomCreateScreenState extends ConsumerState<RoomCreateScreen> {
  final _name = TextEditingController();
  int _colorIdx = 2;
  String _currency = 'IDR';
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final color = RoomColors.palette[_colorIdx];
    final initial =
        _name.text.isEmpty ? 'R' : _name.text[0].toUpperCase();

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('New room'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(LoitSpacing.s4),
        children: [
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(initial,
                  style: LoitTypography.titleL.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 36)),
            ),
          ),
          const SizedBox(height: LoitSpacing.s5),
          LoitInput(
            label: 'Room name',
            controller: _name,
            placeholder: 'e.g. Bali Trip',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: LoitSpacing.s5),
          Text('COLOR IDENTITY',
              style: LoitTypography.labelS.copyWith(
                  color: c.contentSecondary, letterSpacing: 0.5)),
          const SizedBox(height: LoitSpacing.s2),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < RoomColors.palette.length; i++)
                GestureDetector(
                  onTap: () => setState(() => _colorIdx = i),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: RoomColors.palette[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: i == _colorIdx
                            ? c.contentPrimary
                            : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: i == _colorIdx
                        ? const Icon(Icons.check,
                            size: 18, color: Colors.white)
                        : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: LoitSpacing.s5),
          Text('BASE CURRENCY',
              style: LoitTypography.labelS.copyWith(
                  color: c.contentSecondary, letterSpacing: 0.5)),
          const SizedBox(height: LoitSpacing.s2),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final code in const ['IDR', 'USD', 'SGD', 'MYR', 'EUR', 'JPY'])
                GestureDetector(
                  onTap: () => setState(() => _currency = code),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: LoitSpacing.s3, vertical: LoitSpacing.s2),
                    decoration: BoxDecoration(
                      color: code == _currency
                          ? const Color(0xFFE6F4F0)
                          : c.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: code == _currency ? c.brand : c.borderSubtle,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      code,
                      style: LoitTypography.bodyS.copyWith(
                        color: code == _currency
                            ? c.brand
                            : c.contentPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: LoitSpacing.s5),
          Container(
            padding: const EdgeInsets.all(LoitSpacing.s3),
            decoration: BoxDecoration(
              color: c.muted,
              borderRadius: LoitRadius.brM,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: c.brand),
                const SizedBox(width: LoitSpacing.s2),
                Expanded(
                  child: Text(
                    'You will be added as admin. Invite people after the room is created.',
                    style: LoitTypography.bodyS
                        .copyWith(color: c.contentSecondary),
                  ),
                ),
              ],
            ),
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
            label: 'Create room',
            onPressed: _name.text.trim().isEmpty || _busy ? null : _create,
          ),
        ),
      ),
    );
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _busy = true);
    try {
      final room = await RoomService().createRoom(
        name: name,
        baseCurrency: _currency,
      );
      Analytics.roomCreated();
      InteractionLog.success(
        action: 'room_created',
        screen: 'create_room',
        message: name,
        metadata: {'currency': _currency, 'color_idx': _colorIdx},
      );
      ref.invalidate(myRoomsProvider);
      ref.invalidate(userCategoriesProvider);
      if (mounted) {
        context.pushReplacement('/rooms/${room['id']}');
      }
    } catch (e) {
      InteractionLog.error(
        action: 'room_create',
        screen: 'create_room',
        message: '$e',
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
