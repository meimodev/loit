import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_providers.dart';

/// Shows when the user's earliest receipt expires within the next 30 days.
/// Driven by `users.next_receipt_expiry_at`, refreshed daily by the
/// `receipt-expiry-cron` Edge Function.
class ReceiptExpiryBanner extends ConsumerWidget {
  const ReceiptExpiryBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
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
                  ? 'Receipt photos are being deleted today.'
                  : 'Receipt photos expire in $daysLeft days.',
              style: TextStyle(color: cs.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
