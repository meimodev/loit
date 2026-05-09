import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/loit_categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/providers/preferences_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/utils/locale_date_format.dart';
import '../../shared/widgets/loit_amount_text.dart';
import '../../shared/widgets/loit_banner.dart';
import '../../shared/widgets/loit_category_avatar.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_receipt_image.dart';
import 'notes_breakdown.dart';

class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({super.key, required this.transactionId, this.txn});

  final String transactionId;
  final Txn? txn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l = context.l10n;
    final txns = ref.watch(transactionsProvider);
    final accounts = ref.watch(accountsProvider).value ?? const [];
    final accountMap = {for (final a in accounts) a.id: a};
    final isUnsynced = txn != null;

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l.txDetailTitle),
        actions: [
          IconButton(
            tooltip: l.txDetailEdit,
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              final Txn? t;
              if (txn != null) {
                t = txn;
              } else {
                final txns = ref.read(transactionsProvider).value ?? const [];
                t = txns.where((e) => e.id == transactionId).firstOrNull;
              }
              if (t == null) return;
              context.push('/transactions/new', extra: {
                '_edit_id': t.id,
                'amount': t.absAmount,
                'currency': t.currency,
                'type': t.type,
                'account_id': t.accountId,
                'to_account_id': t.toAccountId,
                'category': t.category,
                'notes': t.notes,
                'created_at': t.createdAt.toIso8601String(),
              });
            },
          ),
        ],
      ),
      body: isUnsynced
          ? _buildDetail(context, ref, txn!, accountMap, isUnsynced: true)
          : txns.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (items) {
                final t = items.firstWhere(
                  (e) => e.id == transactionId,
                  orElse: () => Txn(
                    id: null,
                    amount: 0,
                    currency: 'IDR',
                    fxSnapshot: const {},
                    category: null,
                    notes: null,
                    receiptUrl: null,
                    aiParsed: false,
                    isManualFallback: false,
                    createdAt: DateTime.utc(1970),
                  ),
                );
                if (t.id == null) {
                  return Center(child: Text(l.txDetailNotFound));
                }
                return _buildDetail(context, ref, t, accountMap);
              },
            ),
    );
  }

  Widget _buildDetail(
    BuildContext context,
    WidgetRef ref,
    Txn t,
    Map<String, Account> accountMap, {
    bool isUnsynced = false,
  }) {
    final c = context.loitColors;
    final l = context.l10n;
    final catStyle = ref.watch(categoryStyleProvider(t.category));
    final catLabel = ref.watch(categoryLabelProvider(
        CategoryLabelKey(key: t.category)));
    final fromAccount = t.accountId != null ? accountMap[t.accountId] : null;
    final toAccount = t.toAccountId != null ? accountMap[t.toAccountId] : null;
    final homeCurrency = ref.watch(preferencesProvider).maybeWhen(
          data: (p) => p.currency,
          orElse: () => 'IDR',
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        LoitSpacing.s5,
        LoitSpacing.s5,
        LoitSpacing.s5,
        LoitSpacing.s8,
      ),
      children: [
        if (isUnsynced) ...[
          LoitBanner(
            kind: LoitBannerKind.warning,
            title: l.txDetailNotSynced,
            body: l.txDetailNotSyncedBody,
          ),
          const SizedBox(height: LoitSpacing.s4),
        ],
        _heroCard(context, t, catStyle, catLabel, homeCurrency),
        const SizedBox(height: LoitSpacing.s5),
        LoitGroupLabel(label: l.txDetailDetails),
        _row(context, l.txDetailDate,
            yMMMMEEEEd(context).add_jm().format(t.createdAt.toLocal())),
        _row(context, l.txDetailType, _typeName(l, t.type)),
        if (fromAccount != null)
          _row(context, l.txDetailAccount, fromAccount.name),
        if (toAccount != null)
          _row(context, l.txDetailToAccount, toAccount.name),
        if (!t.isTransfer)
          _row(context, l.txDetailCategory, catLabel),
        _row(context, l.txDetailCurrency, t.currency),
        if (t.currency != homeCurrency && t.fxSnapshot.containsKey(homeCurrency))
          _row(
            context,
            l.txDetailFxRate,
            t.fxSnapshot[homeCurrency]!.toStringAsFixed(4),
          ),
        if (t.currency != homeCurrency && t.fxSnapshot.containsKey(homeCurrency))
          _row(
            context,
            l.txDetailHomeAmount,
            formatMoney(t.amountIn(homeCurrency), homeCurrency),
          ),
        if (t.aiParsed)
          _row(context, l.txDetailSource, l.txDetailAiScanned),
        if (t.isManualFallback)
          _row(context, l.txDetailSource, l.txDetailManualFallback),
        if (t.notes != null && t.notes!.isNotEmpty) ...[
          const SizedBox(height: LoitSpacing.s4),
          LoitGroupLabel(label: l.txDetailNotes),
          Builder(builder: (_) {
            final parsed = parseBreakdown(t.notes);
            if (parsed == null) {
              return Container(
                padding: const EdgeInsets.all(LoitSpacing.s4),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: LoitRadius.brM,
                  border: Border.all(color: c.borderSubtle),
                ),
                child: Text(t.notes!,
                    style: LoitTypography.bodyM
                        .copyWith(color: c.contentPrimary)),
              );
            }
            return _BreakdownView(parsed: parsed);
          }),
        ],
        if (t.receiptUrl != null) ...[
          const SizedBox(height: LoitSpacing.s4),
          LoitGroupLabel(label: l.txDetailReceipt),
          ClipRRect(
            borderRadius: LoitRadius.brM,
            child: LoitReceiptImage(path: t.receiptUrl!),
          ),
        ],
        if (!isUnsynced) ...[
          const SizedBox(height: LoitSpacing.s6),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: c.danger,
              side: BorderSide(color: c.danger.withValues(alpha: 0.4)),
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.delete_outline),
            label: Text(l.txDetailDeleteTransaction),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(l.txDetailDeleteTitle),
                  content: Text(l.txDetailDeleteBody),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l.txDetailCancel),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l.txDetailDelete),
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
      ],
    );
  }

  String _typeName(AppLocalizations l, String type) {
    switch (type) {
      case 'income':
        return l.txFormIncome;
      case 'transfer':
        return l.txDetailFallbackTransfer;
      default:
        return l.txFormExpense;
    }
  }

  Widget _heroCard(BuildContext context, Txn t, LoitCategoryStyle catStyle,
      String catLabel, String homeCurrency) {
    final c = context.loitColors;
    final l = context.l10n;
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
              if (t.isTransfer)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.contentSecondary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.swap_horiz, color: c.contentSecondary, size: 24),
                )
              else
                LoitCategoryAvatar(categoryKey: t.category, size: 48),
              const SizedBox(width: LoitSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(builder: (_) {
                      final t0 = breakdownTitle(t.notes);
                      final fallback = t.isTransfer ? l.txDetailFallbackTransfer : l.txDetailTitle;
                      return Text(
                          t0.isEmpty ? fallback : t0,
                          style: LoitTypography.titleM
                              .copyWith(color: c.contentPrimary));
                    }),
                    const SizedBox(height: 2),
                    Text(
                      t.isTransfer ? l.txDetailFallbackTransfer : catLabel,
                      style: LoitTypography.bodyS
                          .copyWith(color: c.contentSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LoitSpacing.s5),
          LoitAmountText.money(
            amount: t.isTransfer ? t.absAmount : t.amount,
            currency: t.currency,
            variant: LoitAmountVariant.hero,
            convertedAmount: (!t.isTransfer &&
                    t.currency != homeCurrency &&
                    t.fxSnapshot.containsKey(homeCurrency))
                ? t.amountIn(homeCurrency)
                : null,
            convertedCurrency: (!t.isTransfer &&
                    t.currency != homeCurrency &&
                    t.fxSnapshot.containsKey(homeCurrency))
                ? homeCurrency
                : null,
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

class _BreakdownView extends StatelessWidget {
  const _BreakdownView({required this.parsed});
  final NotesBreakdown parsed;

  static final NumberFormat _f = NumberFormat('#,##0.##', 'id_ID');

  String _itemRight(NotesBreakdownItem it) {
    final parts = <String>[];
    if (it.qty != null && it.unitPrice != null) {
      parts.add('${_f.format(it.qty)} × ${_f.format(it.unitPrice)}');
    } else if (it.qty != null) {
      parts.add('${_f.format(it.qty)} ×');
    } else if (it.unitPrice != null) {
      parts.add('× ${_f.format(it.unitPrice)}');
    }
    if (it.totalPrice != null) {
      parts.add('= ${_f.format(it.totalPrice)}');
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(LoitSpacing.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: LoitRadius.brM,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (parsed.merchant.isNotEmpty)
            Text(parsed.merchant,
                style: LoitTypography.bodyL.copyWith(
                  color: c.contentPrimary,
                  fontWeight: FontWeight.w600,
                )),
          if (parsed.merchant.isNotEmpty)
            const SizedBox(height: LoitSpacing.s3),
          for (var i = 0; i < parsed.items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      parsed.items[i].name.isEmpty
                          ? '—'
                          : parsed.items[i].name,
                      style: LoitTypography.bodyM
                          .copyWith(color: c.contentPrimary),
                    ),
                  ),
                  const SizedBox(width: LoitSpacing.s3),
                  Text(_itemRight(parsed.items[i]),
                      style: LoitTypography.bodyS
                          .copyWith(color: c.contentSecondary)),
                ],
              ),
            ),
            if (i != parsed.items.length - 1)
              Divider(height: 1, color: c.borderSubtle),
          ],
          if (parsed.total != null) ...[
            const SizedBox(height: LoitSpacing.s3),
            Divider(height: 1, color: c.borderSubtle),
            Padding(
              padding: const EdgeInsets.only(top: LoitSpacing.s3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l.txDetailTotal,
                        style: LoitTypography.bodyM.copyWith(
                          color: c.contentPrimary,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  Text(_f.format(parsed.total),
                      style: LoitTypography.bodyM.copyWith(
                        color: c.contentPrimary,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
