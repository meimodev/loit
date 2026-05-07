import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/loit_categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/preferences_provider.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/loit_amount_text.dart';
import '../../shared/widgets/loit_category_avatar.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_receipt_image.dart';
import '../rooms/room_colors.dart';
import '../transactions/notes_breakdown.dart';

class RoomTransactionDetailScreen extends ConsumerWidget {
  const RoomTransactionDetailScreen({
    super.key,
    required this.roomId,
    required this.transactionId,
    this.txn,
  });

  final String roomId;
  final String transactionId;
  final Map<String, dynamic>? txn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final roomAsync = ref.watch(roomDetailProvider(roomId));
    final user = ref.watch(currentUserProvider);
    final isCreator = roomAsync.maybeWhen(
      data: (r) => r['created_by'] == user?.id,
      orElse: () => false,
    );

    AppBar appBar() => AppBar(
          title: const Text('Transaction'),
          actions: [
            if (isCreator)
              IconButton(
                tooltip: 'Delete',
                icon: Icon(Icons.delete_outline, color: c.danger),
                onPressed: () => _confirmAndDelete(context, ref),
              ),
          ],
        );

    if (txn != null) {
      return Scaffold(
        backgroundColor: c.canvas,
        appBar: appBar(),
        body: _buildDetail(context, ref, txn!),
      );
    }

    final async = ref.watch(roomTransactionProvider(
        RoomTxKey(roomId: roomId, txId: transactionId)));
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: appBar(),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (row) {
          if (row == null) return const Center(child: Text('Not found'));
          return _buildDetail(context, ref, row);
        },
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final c = context.loitColors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
            'This removes the transaction from the room for everyone. Cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Supabase.instance.client
          .from('transactions')
          .delete()
          .eq('id', transactionId);
    } finally {
      ref.invalidate(roomFeedProvider(roomId));
      ref.invalidate(roomTransactionProvider(
          RoomTxKey(roomId: roomId, txId: transactionId)));
      if (context.mounted) context.pop();
    }
  }

  Widget _buildDetail(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> t,
  ) {
    final c = context.loitColors;
    final amount = (t['amount'] as num?)?.toDouble() ?? 0;
    final type = t['type'] as String? ?? (amount < 0 ? 'income' : 'expense');
    final isIncome = type == 'income';
    final isTransfer = type == 'transfer';
    final category = t['category'] as String?;
    final catStyle = ref.watch(categoryStyleProvider(category));
    final catLabel = ref.watch(categoryLabelProvider(
        CategoryLabelKey(key: category, activeRoomId: roomId)));
    final notes = t['notes'] as String?;
    final currency = t['currency'] as String? ?? 'IDR';
    final fxRate = (t['fx_rate'] as num?)?.toDouble();
    final amountHome = (t['amount_home_currency'] as num?)?.toDouble() ??
        (t['amount_home'] as num?)?.toDouble();
    final receiptUrl = t['receipt_url'] as String?;
    final aiParsed = t['ai_parsed'] == true;
    final isManualFallback = t['is_manual_fallback'] == true;

    final user = t['users'] as Map<String, dynamic>?;
    final rawName = (user?['name'] as String?)?.trim();
    final email = (user?['email'] as String?)?.trim();
    final emailHandle =
        (email != null && email.contains('@')) ? email.split('@').first : email;
    final payer = (rawName != null && rawName.isNotEmpty)
        ? rawName
        : (emailHandle != null && emailHandle.isNotEmpty)
            ? emailHandle
            : 'Unknown';
    final avatarUrl = user?['avatar_url'] as String?;

    final createdRaw = t['created_at'] as String?;
    final created = createdRaw != null
        ? DateTime.tryParse(createdRaw)?.toLocal() ?? DateTime.now()
        : DateTime.now();

    final fmt = NumberFormat.simpleCurrency(name: currency, decimalDigits: currencyDecimals(currency));
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
        _heroCard(context, t, catStyle, catLabel, fmt, isTransfer),
        const SizedBox(height: LoitSpacing.s5),
        const LoitGroupLabel(label: 'Created by'),
        _creatorRow(context, payer, avatarUrl, email),
        const SizedBox(height: LoitSpacing.s4),
        const LoitGroupLabel(label: 'Details'),
        _row(context, 'Date',
            DateFormat.yMMMMEEEEd().add_jm().format(created)),
        _row(context, 'Type', _typeName(type)),
        if (!isTransfer)
          _row(context, 'Category', catLabel),
        _row(context, 'Currency', currency),
        if (fxRate != null)
          _row(context, 'FX rate', fxRate.toStringAsFixed(4)),
        if (amountHome != null && amountHome != amount)
          _row(
            context,
            'Home amount',
            NumberFormat.simpleCurrency(
              name: homeCurrency,
              decimalDigits: currencyDecimals(homeCurrency),
            ).format(amountHome),
          ),
        _row(
          context,
          'Amount',
          '${isTransfer ? '' : isIncome ? '+' : ''}${fmt.format(amount.abs())}',
        ),
        if (aiParsed) _row(context, 'Source', 'AI scanned'),
        if (isManualFallback) _row(context, 'Source', 'Manual fallback'),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: LoitSpacing.s4),
          const LoitGroupLabel(label: 'Notes'),
          Builder(builder: (_) {
            final parsed = parseBreakdown(notes);
            if (parsed == null) {
              return Container(
                padding: const EdgeInsets.all(LoitSpacing.s4),
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: LoitRadius.brM,
                  border: Border.all(color: c.borderSubtle),
                ),
                child: Text(notes,
                    style: LoitTypography.bodyM
                        .copyWith(color: c.contentPrimary)),
              );
            }
            return _BreakdownView(parsed: parsed);
          }),
        ],
        if (receiptUrl != null && receiptUrl.isNotEmpty) ...[
          const SizedBox(height: LoitSpacing.s4),
          const LoitGroupLabel(label: 'Receipt'),
          ClipRRect(
            borderRadius: LoitRadius.brM,
            child: LoitReceiptImage(path: receiptUrl),
          ),
        ],
      ],
    );
  }

  String _typeName(String type) {
    switch (type) {
      case 'income':
        return 'Income';
      case 'transfer':
        return 'Transfer';
      default:
        return 'Expense';
    }
  }

  Widget _heroCard(
    BuildContext context,
    Map<String, dynamic> t,
    LoitCategoryStyle catStyle,
    String catLabel,
    NumberFormat fmt,
    bool isTransfer,
  ) {
    final c = context.loitColors;
    final notes = t['notes'] as String?;
    final amount = (t['amount'] as num?)?.toDouble() ?? 0;
    final category = t['category'] as String?;
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
              if (isTransfer)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.contentSecondary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(Icons.swap_horiz,
                      color: c.contentSecondary, size: 24),
                )
              else
                LoitCategoryAvatar(categoryKey: category, size: 48),
              const SizedBox(width: LoitSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(builder: (_) {
                      final t0 = breakdownTitle(notes);
                      final fallback =
                          isTransfer ? 'Transfer' : 'Transaction';
                      return Text(
                          t0.isEmpty ? fallback : t0,
                          style: LoitTypography.titleM
                              .copyWith(color: c.contentPrimary));
                    }),
                    const SizedBox(height: 2),
                    Text(
                      isTransfer ? 'Transfer' : catLabel,
                      style: LoitTypography.bodyS
                          .copyWith(color: c.contentSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LoitSpacing.s5),
          LoitAmountText(
            fmt.format(isTransfer ? amount.abs() : amount),
            variant: LoitAmountVariant.hero,
          ),
        ],
      ),
    );
  }

  Widget _creatorRow(
    BuildContext context,
    String name,
    String? avatarUrl,
    String? email,
  ) {
    final c = context.loitColors;
    final color = RoomColors.forId(name);
    return Container(
      padding: const EdgeInsets.all(LoitSpacing.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: LoitRadius.brM,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              image: avatarUrl != null && avatarUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(avatarUrl), fit: BoxFit.cover)
                  : null,
            ),
            alignment: Alignment.center,
            child: avatarUrl == null || avatarUrl.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: LoitSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: LoitTypography.bodyM.copyWith(
                        color: c.contentPrimary,
                        fontWeight: FontWeight.w600)),
                if (email != null && email.isNotEmpty)
                  Text(email,
                      style: LoitTypography.bodyS
                          .copyWith(color: c.contentSecondary)),
              ],
            ),
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
                    child: Text('Total',
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
