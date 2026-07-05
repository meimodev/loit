import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/interaction_log_service.dart';
import '../../core/services/reachability_service.dart'
    show OnlineOnlyActionException;
import '../../shared/widgets/room_error_state.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/supported_currencies_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/widgets/currency_picker_sheet.dart';
import '../../shared/widgets/loit_button.dart';
import '../../shared/widgets/loit_input.dart';
import '../paywall/paywall_screen.dart';
import 'room_colors.dart';
import 'room_slot_sheet.dart';

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
    final l = context.l10n;
    final color = RoomColors.palette[_colorIdx];
    final initial =
        _name.text.isEmpty ? 'R' : _name.text[0].toUpperCase();

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l.roomCreateTitle),
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
            label: l.roomCreateName,
            controller: _name,
            placeholder: l.roomCreateNamePlaceholder,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: LoitSpacing.s5),
          Text(l.roomColorIdentity,
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
          Text(l.roomBaseCurrency,
              style: LoitTypography.labelS.copyWith(
                  color: c.contentSecondary, letterSpacing: 0.5)),
          const SizedBox(height: LoitSpacing.s2),
          _currencyRow(context),
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
                    l.roomCreateAdminNote,
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
            label: _busy ? l.roomCreateCreating : l.roomCreateCreate,
            onPressed: _name.text.trim().isEmpty || _busy ? null : _create,
          ),
        ),
      ),
    );
  }

  Widget _currencyRow(BuildContext context) {
    final c = context.loitColors;
    final registry = ref.watch(supportedCurrenciesProvider).value;
    final cur = registry?.byCode[_currency];
    final label = cur == null
        ? _currency
        : '${cur.code} · ${cur.symbol} · ${cur.name}';
    return InkWell(
      borderRadius: LoitRadius.brM,
      onTap: () async {
        final picked = await pickCurrency(context, selected: _currency);
        if (picked != null) setState(() => _currency = picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: LoitSpacing.s4, vertical: LoitSpacing.s3),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: LoitRadius.brM,
          border: Border.all(color: c.borderSubtle),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: LoitTypography.bodyM.copyWith(color: c.contentPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.contentTertiary),
          ],
        ),
      ),
    );
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final room = await ref.read(roomServiceProvider).createRoom(
        name: name,
        baseCurrency: _currency,
      );

      // Best-effort: seed Default room accounts (ADR 0024). A failure leaves
      // the room with zero accounts — still usable, the admin can add manually.
      try {
        await ref.read(roomServiceProvider).seedDefaultAccounts(
              roomId: room['id'] as String,
              currency: _currency,
            );
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Akun default gagal dimuat — tambah manual di room.'),
          ));
        }
      }

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
    } on OnlineOnlyActionException {
      if (mounted) showRoomOnlineOnlySnack(context);
    } catch (e) {
      // Server-side room-creation cap (ADR-0020). The FAB gates this
      // pre-emptively, so reaching here means a stale/raced client — route to
      // the same buy-slot / upgrade affordances instead of a raw error.
      if ('$e'.contains('room_creation_cap_reached')) {
        if (mounted) {
          final canBuySlot =
              ref.read(userProfileProvider).value?.canPurchaseRoomSlot ?? false;
          if (canBuySlot) {
            showRoomSlotSheet(context);
          } else {
            showPaywallSheet(context, feature: 'more_rooms');
          }
        }
        return;
      }
      InteractionLog.error(
        action: 'room_create',
        screen: 'create_room',
        message: '$e',
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.roomCreateFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
