import 'package:flutter/material.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';

/// The funding species of a room transaction, surfaced on the personal
/// transactions list beside the room origin badge.
///
/// - [pool] — a Room-account movement: paid from the room's shared pool, no
///   personal-money leg. Quiet/neutral styling (the expected default).
/// - [myMoney] — an Out-of-pocket room expense: paid from the member's own
///   personal account. Loud/amber styling — the surprising case, because the
///   member's real cash balance moved.
enum FundingSpecies { pool, myMoney }

/// Compact pill rendered next to [LoitRoomOriginBadge] telling the user which
/// account funded a room transaction. Label-only (no tap); the precise
/// spend-vs-balance effect is explained on the transaction detail screen.
class LoitFundingBadge extends StatelessWidget {
  const LoitFundingBadge({
    super.key,
    required this.species,
    required this.label,
  });

  final FundingSpecies species;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final isMyMoney = species == FundingSpecies.myMoney;

    final Color bg =
        isMyMoney ? c.warningSurface : c.muted;
    final Color border =
        isMyMoney ? c.warning.withValues(alpha: 0.32) : c.borderDefault;
    final Color fg = isMyMoney ? c.warning : c.contentSecondary;
    final IconData icon =
        isMyMoney ? Icons.account_balance_wallet : Icons.savings;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: LoitTypography.labelS.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
