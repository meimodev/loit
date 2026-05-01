import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/loit_categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/loit_amount_text.dart';
import '../../shared/widgets/loit_category_avatar.dart';
import '../../shared/widgets/loit_group_label.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final txns = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Transaction'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/transactions/new', extra: {
              '_edit_id': transactionId,
            }),
          ),
        ],
      ),
      body: txns.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          final t = items.firstWhere(
            (e) => e.id == transactionId,
            orElse: () => Txn(
              id: null,
              merchant: null,
              amount: 0,
              currency: 'IDR',
              amountHome: null,
              fxRate: null,
              category: null,
              notes: null,
              receiptUrl: null,
              aiParsed: false,
              isManualFallback: false,
              createdAt: DateTime.now(),
            ),
          );
          if (t.id == null) {
            return const Center(child: Text('Not found'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              LoitSpacing.s5,
              LoitSpacing.s5,
              LoitSpacing.s5,
              LoitSpacing.s8,
            ),
            children: [
              _heroCard(context, t),
              const SizedBox(height: LoitSpacing.s5),
              const LoitGroupLabel(label: 'Details'),
              _row(context, 'Date',
                  DateFormat.yMMMMEEEEd().add_jm().format(t.createdAt.toLocal())),
              _row(context, 'Category',
                  LoitCategories.resolve(t.category).label),
              _row(context, 'Currency', t.currency),
              if (t.fxRate != null)
                _row(context, 'FX rate', t.fxRate!.toStringAsFixed(4)),
              if (t.amountHome != null && t.amountHome != t.amount)
                _row(
                  context,
                  'Home amount',
                  NumberFormat.simpleCurrency(decimalDigits: 0)
                      .format(t.amountHome),
                ),
              if (t.aiParsed)
                _row(context, 'Source', 'AI scanned'),
              if (t.isManualFallback)
                _row(context, 'Source', 'Manual fallback'),
              if (t.notes != null && t.notes!.isNotEmpty) ...[
                const SizedBox(height: LoitSpacing.s4),
                const LoitGroupLabel(label: 'Notes'),
                Container(
                  padding: const EdgeInsets.all(LoitSpacing.s4),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: LoitRadius.brM,
                    border: Border.all(color: c.borderSubtle),
                  ),
                  child: Text(t.notes!,
                      style: LoitTypography.bodyM
                          .copyWith(color: c.contentPrimary)),
                ),
              ],
              if (t.receiptUrl != null) ...[
                const SizedBox(height: LoitSpacing.s4),
                const LoitGroupLabel(label: 'Receipt'),
                ClipRRect(
                  borderRadius: LoitRadius.brM,
                  child: Image.network(
                    t.receiptUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 160,
                      color: c.muted,
                      alignment: Alignment.center,
                      child: Icon(Icons.broken_image_outlined,
                          color: c.contentTertiary),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: LoitSpacing.s6),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.danger,
                  side: BorderSide(color: c.danger.withValues(alpha: 0.4)),
                  minimumSize: const Size.fromHeight(48),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text('Delete transaction'),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Delete transaction?'),
                      content: const Text('This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await ref
                        .read(transactionsProvider.notifier)
                        .deleteTransaction(t.id!);
                    if (context.mounted) context.pop();
                  }
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _heroCard(BuildContext context, Txn t) {
    final c = context.loitColors;
    return Container(
      padding: const EdgeInsets.all(LoitSpacing.s5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: LoitRadius.brL,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LoitCategoryAvatar(categoryKey: t.category, size: 48),
              const SizedBox(width: LoitSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.merchant ?? 'Transaction',
                        style: LoitTypography.titleM
                            .copyWith(color: c.contentPrimary)),
                    const SizedBox(height: 2),
                    Text(LoitCategories.resolve(t.category).label,
                        style: LoitTypography.bodyS
                            .copyWith(color: c.contentSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LoitSpacing.s5),
          LoitAmountText(
            NumberFormat.simpleCurrency(
              name: t.currency,
              decimalDigits: 0,
            ).format(t.amount),
            variant: LoitAmountVariant.hero,
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    final c = context.loitColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: LoitTypography.bodyM
                    .copyWith(color: c.contentSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: LoitTypography.bodyM.copyWith(
                  color: c.contentPrimary,
                  fontWeight: FontWeight.w500,
                )),
          ),
        ],
      ),
    );
  }
}
