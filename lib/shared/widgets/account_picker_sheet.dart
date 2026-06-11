import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../providers/accounts_provider.dart';
import '../providers/room_accounts_provider.dart';
import 'loit_sheet.dart';

/// Bottom sheet for picking an account. Returns the selected account id.
/// [excludeId] prevents selecting the same account (e.g., transfer destination).
/// [kindFilter] limits to asset or liability; null = all.
/// [roomId] scopes the list to that room's accounts (pool-only entry); null =
/// the user's personal accounts.
Future<String?> pickLoitAccount(
  BuildContext context, {
  String? selectedId,
  String? excludeId,
  AccountKind? kindFilter,
  String? roomId,
}) {
  return showLoitSheet<String>(
    context,
    builder: (ctx) => _AccountPickerSheet(
      selectedId: selectedId,
      excludeId: excludeId,
      kindFilter: kindFilter,
      roomId: roomId,
    ),
  );
}

class _AccountPickerSheet extends ConsumerWidget {
  const _AccountPickerSheet({
    this.selectedId,
    this.excludeId,
    this.kindFilter,
    this.roomId,
  });

  final String? selectedId;
  final String? excludeId;
  final AccountKind? kindFilter;
  final String? roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final accounts = roomId != null
        ? ref.watch(activeRoomAccountsProvider(roomId!))
        : ref.watch(activeAccountsProvider);
    final visible = accounts.where((a) {
      if (a.id == excludeId) return false;
      if (kindFilter != null && a.kind != kindFilter) return false;
      return true;
    }).toList();

    return LoitSheet(
      title: context.l10n.accountPickerTitle,
      child: visible.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s5),
              child: Text(
                context.l10n.accountPickerEmpty,
                style: LoitTypography.bodyM.copyWith(color: c.contentSecondary),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final a in visible) ...[
                  InkWell(
                    borderRadius: LoitRadius.brM,
                    onTap: () => Navigator.of(context).pop(a.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: LoitSpacing.s3,
                        horizontal: LoitSpacing.s2,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: a.kind == AccountKind.asset
                                  ? c.info.withValues(alpha: 0.12)
                                  : c.danger.withValues(alpha: 0.12),
                              borderRadius: LoitRadius.brM,
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              a.kind == AccountKind.asset
                                  ? Icons.account_balance_wallet_outlined
                                  : Icons.credit_card_outlined,
                              size: 18,
                              color: a.kind == AccountKind.asset
                                  ? c.info
                                  : c.danger,
                            ),
                          ),
                          const SizedBox(width: LoitSpacing.s4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.name,
                                  style: LoitTypography.bodyL
                                      .copyWith(color: c.contentPrimary),
                                ),
                                Text(
                                  a.kind == AccountKind.asset
                                      ? 'Asset'
                                      : 'Liability',
                                  style: LoitTypography.bodyS
                                      .copyWith(color: c.contentTertiary),
                                ),
                              ],
                            ),
                          ),
                          if (a.id == selectedId)
                            Icon(Icons.check_rounded,
                                color: c.brand, size: 22),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
