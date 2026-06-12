import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';

/// Funding source of a **Room transaction** (ADR 0011).
///
/// `roomPool` = a Room-account movement (pool-funded). `myMoney` = an
/// Out-of-pocket room expense (`account_id` = the payer's personal account).
enum PaidFrom { roomPool, myMoney }

/// "Paid from: Room pool | My money" segmented control. Shown only inside a
/// room context. When the room has no Room account yet, the Room pool segment
/// is disabled and a hint is shown (the caller should default to [PaidFrom.myMoney]).
class LoitPaidFromSegment extends StatelessWidget {
  const LoitPaidFromSegment({
    super.key,
    required this.value,
    required this.onChanged,
    required this.poolEnabled,
  });

  final PaidFrom value;
  final ValueChanged<PaidFrom> onChanged;

  /// False when the room has no Room account — disables the Room pool option.
  final bool poolEnabled;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l.txFormPaidFrom,
          style: LoitTypography.bodyM.copyWith(
            color: c.contentPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: _seg(
                context,
                label: l.txFormPaidFromRoomPool,
                selected: value == PaidFrom.roomPool,
                enabled: poolEnabled,
                isFirst: true,
                isLast: false,
                onTap: () => onChanged(PaidFrom.roomPool),
              ),
            ),
            Expanded(
              child: _seg(
                context,
                label: l.txFormPaidFromMyMoney,
                selected: value == PaidFrom.myMoney,
                enabled: true,
                isFirst: false,
                isLast: true,
                onTap: () => onChanged(PaidFrom.myMoney),
              ),
            ),
          ],
        ),
        if (!poolEnabled) ...[
          const SizedBox(height: LoitSpacing.s2),
          Text(
            l.txFormPaidFromNoPoolHint,
            style: LoitTypography.bodyS.copyWith(color: c.contentTertiary),
          ),
        ],
      ],
    );
  }

  Widget _seg(
    BuildContext context, {
    required String label,
    required bool selected,
    required bool enabled,
    required bool isFirst,
    required bool isLast,
    required VoidCallback onTap,
  }) {
    final c = context.loitColors;
    final radius = BorderRadius.horizontal(
      left: isFirst ? const Radius.circular(8) : Radius.zero,
      right: isLast ? const Radius.circular(8) : Radius.zero,
    );
    final color = c.brand;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : c.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? color : c.borderDefault,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: LoitTypography.bodyS.copyWith(
            color: !enabled
                ? c.contentTertiary
                : selected
                    ? color
                    : c.contentSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
