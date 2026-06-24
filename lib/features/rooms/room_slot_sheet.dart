import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/config/pricing_constants.dart';
import '../../core/services/dummy_payment_service.dart';
import '../../core/services/payment_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/services_providers.dart';
import '../../shared/widgets/loit_button.dart';

/// Pro-only "buy another room" sheet (ADR-0020). A Room slot is a one-time,
/// permanent consumable (`loit_room_slot`) that raises the effective room cap
/// by one. Mirrors the scan top-up purchase flow.
void showRoomSlotSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _RoomSlotSheet(),
  );
}

class _RoomSlotSheet extends ConsumerStatefulWidget {
  const _RoomSlotSheet();

  @override
  ConsumerState<_RoomSlotSheet> createState() => _RoomSlotSheetState();
}

class _RoomSlotSheetState extends ConsumerState<_RoomSlotSheet> {
  bool _busy = false;
  PaymentProductDetails? _details;
  StreamSubscription<PurchaseUpdate>? _sub;

  @override
  void initState() {
    super.initState();
    final pay = ref.read(paymentServiceProvider);
    _sub = pay.purchaseUpdates.listen(_onPurchaseUpdate);
    _loadDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pay = ref.read(paymentServiceProvider);
    if (pay is DummyPaymentService) pay.bindContext(context);
  }

  @override
  void dispose() {
    final pay = ref.read(paymentServiceProvider);
    if (pay is DummyPaymentService) pay.unbindContext(context);
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    final pay = ref.read(paymentServiceProvider);
    try {
      final d = await pay.getProductDetails(PricingConstants.skuRoomSlot);
      if (!mounted) return;
      setState(() => _details = d);
    } catch (_) {/* fall back to constant price */}
  }

  Future<void> _buy() async {
    setState(() => _busy = true);
    try {
      final pay = ref.read(paymentServiceProvider);
      final result = await pay.purchaseOneTime(PricingConstants.skuRoomSlot);
      if (!mounted) return;
      if (result.status == PurchaseStatus.cancelled) {
        _snack(context.l10n.paywallPurchaseCancelled);
      } else if (result.status == PurchaseStatus.failed) {
        _snack(result.message ?? context.l10n.paywallPurchaseFailed);
      }
    } catch (e) {
      if (!mounted) return;
      _snack(context.l10n.paywallPurchaseStartError(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _onPurchaseUpdate(PurchaseUpdate u) {
    if (!mounted) return;
    if (u.productId != PricingConstants.skuRoomSlot) return;
    final l = context.l10n;
    if (u.status == PurchaseStatus.purchased ||
        u.status == PurchaseStatus.restored) {
      ref.invalidate(userProfileProvider);
      _snack(l.roomSlotSuccess);
      Navigator.of(context).maybePop();
    } else if (u.status == PurchaseStatus.failed) {
      _snack(u.message ?? l.paywallPurchaseFailed);
    } else if (u.status == PurchaseStatus.cancelled) {
      _snack(l.paywallPurchaseCancelled);
    }
    if (u.status != PurchaseStatus.pending) {
      setState(() => _busy = false);
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String get _price =>
      _details?.priceString ?? _formatIdr(PricingConstants.roomSlotIdr);

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        LoitSpacing.s5,
        LoitSpacing.s2,
        LoitSpacing.s5,
        LoitSpacing.s5 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.meeting_room_outlined, size: 32, color: c.brand),
          const SizedBox(height: LoitSpacing.s3),
          Text(
            l.roomSlotTitle,
            style: LoitTypography.titleM.copyWith(color: c.contentPrimary),
          ),
          const SizedBox(height: LoitSpacing.s2),
          Text(
            l.roomSlotBody(PricingConstants.roomCapPro, _price),
            style: LoitTypography.bodyM.copyWith(color: c.contentSecondary),
          ),
          const SizedBox(height: LoitSpacing.s5),
          LoitButton.primary(
            size: LoitButtonSize.l,
            fullWidth: true,
            loading: _busy,
            label: l.roomSlotBuyCta(_price),
            onPressed: _busy ? null : _buy,
          ),
        ],
      ),
    );
  }
}

String _formatIdr(int amount) {
  final fmt = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  return fmt.format(amount).trim();
}
