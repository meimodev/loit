import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/providers/auth_providers.dart';

class PaymentReceipt {
  final String id;
  final String provider;
  final String eventType;
  final String productId;
  final String? storeTxnId;
  final DateTime occurredAt;

  PaymentReceipt({
    required this.id,
    required this.provider,
    required this.eventType,
    required this.productId,
    required this.storeTxnId,
    required this.occurredAt,
  });

  factory PaymentReceipt.fromRow(Map<String, dynamic> r) => PaymentReceipt(
        id: r['id'] as String,
        provider: r['provider'] as String,
        eventType: r['event_type'] as String,
        productId: r['product_id'] as String,
        storeTxnId: r['store_txn_id'] as String?,
        occurredAt: DateTime.parse(r['occurred_at'] as String),
      );
}

final paymentReceiptsProvider =
    FutureProvider<List<PaymentReceipt>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  final rows = await Supabase.instance.client
      .from('payment_receipts')
      .select()
      .eq('user_id', user.id)
      .order('occurred_at', ascending: false)
      .limit(100);
  return (rows as List)
      .map((r) => PaymentReceipt.fromRow(r as Map<String, dynamic>))
      .toList();
});

class BillingHistoryScreen extends ConsumerWidget {
  const BillingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipts = ref.watch(paymentReceiptsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Billing & receipts')),
      body: receipts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No purchases yet.\nReceipts will appear here after your first payment.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(paymentReceiptsProvider),
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = items[i];
                return ListTile(
                  leading: Icon(_iconFor(r.eventType)),
                  title: Text(_titleFor(r.productId)),
                  subtitle: Text(
                    '${_eventLabel(r.eventType)} · '
                    '${DateFormat.yMMMd().add_jm().format(r.occurredAt.toLocal())}'
                    '${r.provider == 'dummy' ? ' · STUB' : ''}',
                  ),
                  trailing: r.storeTxnId == null
                      ? null
                      : Text(
                          r.storeTxnId!.length > 10
                              ? '…${r.storeTxnId!.substring(r.storeTxnId!.length - 8)}'
                              : r.storeTxnId!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _iconFor(String eventType) {
    if (eventType.contains('EXPIRATION') || eventType.contains('CANCEL')) {
      return Icons.cancel_outlined;
    }
    if (eventType.contains('RENEWAL')) return Icons.autorenew;
    if (eventType.contains('NON_RENEWING')) return Icons.shopping_bag_outlined;
    return Icons.receipt_long_outlined;
  }

  String _eventLabel(String eventType) {
    return switch (eventType) {
      'INITIAL_PURCHASE' => 'New subscription',
      'RENEWAL' => 'Renewal',
      'NON_RENEWING_PURCHASE' => 'One-time purchase',
      'PRODUCT_CHANGE' => 'Plan change',
      'CANCELLATION' => 'Cancelled',
      'EXPIRATION' => 'Expired',
      'UNCANCELLATION' => 'Resubscribed',
      'BILLING_ISSUE' => 'Billing issue',
      _ => eventType,
    };
  }

  String _titleFor(String productId) {
    return switch (productId) {
      'loit_pro_monthly_1' => 'LOIT Pro · Monthly',
      'loit_pro_annual_1' => 'LOIT Pro · Annual',
      'loit_team_monthly_1' => 'LOIT Team · Monthly',
      'loit_team_annual_1' => 'LOIT Team · Annual',
      'loit_scan_topup_10' => 'Scan top-up · 10 scans',
      'loit_storage_ext_6mo' => 'Receipt storage · +6 months',
      _ => productId,
    };
  }
}
