import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_x.dart';
import '../providers/auth_providers.dart';

class ReceiptExpiryBanner extends ConsumerWidget {
  const ReceiptExpiryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final l = context.l10n;
    final next = profile?.nextReceiptExpiryAt;
    if (next == null) return const SizedBox.shrink();

    final daysLeft = next.difference(DateTime.now()).inDays;
    if (daysLeft > 30 || daysLeft < 0) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: cs.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              daysLeft <= 0
                  ? l.receiptExpiringToday
                  : l.receiptExpiringDays(daysLeft),
              style: TextStyle(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
