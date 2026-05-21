import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../shared/utils/locale_date_format.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/loit_categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/home_currency_provider.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/account_picker_sheet.dart';
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
    final l = context.l10n;
    final user = ref.watch(currentUserProvider);

    AppBar appBar({required bool isOwner}) => AppBar(
          title: Text(l.txDetailTitle),
          actions: [
            if (isOwner)
              IconButton(
                tooltip: l.txDetailDelete,
                icon: Icon(Icons.delete_outline, color: c.danger),
                onPressed: () => _confirmAndDelete(context, ref),
              ),
          ],
        );

    bool ownerOf(Map<String, dynamic>? row) =>
        row != null && user != null && row['user_id'] == user.id;

    if (txn != null) {
      return Scaffold(
        backgroundColor: c.canvas,
        appBar: appBar(isOwner: ownerOf(txn)),
        body: _buildDetail(context, ref, txn!),
      );
    }

    final async = ref.watch(roomTransactionProvider(
        RoomTxKey(roomId: roomId, txId: transactionId)));
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: appBar(isOwner: async.maybeWhen(
        data: ownerOf,
        orElse: () => false,
      )),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (row) {
          if (row == null) return Center(child: Text(l.txDetailNotFound));
          return _buildDetail(context, ref, row);
        },
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final c = context.loitColors;
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.txDetailDeleteTitle),
        content: const Text(
            'This removes the transaction from the room for everyone. Cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.txDetailCancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.txDetailDelete),
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
      ref.invalidate(transactionsProvider);
      if (context.mounted) context.pop();
    }
  }

  Widget _buildDetail(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> t,
  ) {
    final c = context.loitColors;
    final l = context.l10n;
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
    final fxSnapshot = t['fx_snapshot'];
    double? snapshotRate(String target) {
      if (fxSnapshot is! Map) return null;
      final v = fxSnapshot[target];
      return v is num ? v.toDouble() : null;
    }
    final receiptUrl = t['receipt_url'] as String?;
    final aiParsed = t['ai_parsed'] == true;
    final rawSource = t['source'] as String?;
    final TxnSource sourceEnum;
    switch (rawSource) {
      case 'scanned':
        sourceEnum = TxnSource.scanned;
        break;
      case 'bot_image':
        sourceEnum = TxnSource.botImage;
        break;
      case 'bot_chat':
        sourceEnum = TxnSource.botChat;
        break;
      case 'manual':
        sourceEnum = TxnSource.manual;
        break;
      default:
        sourceEnum = aiParsed ? TxnSource.scanned : TxnSource.manual;
    }

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

    String fmt(double v) => formatMoney(v, currency);
    final homeCurrency = ref.watch(homeCurrencyProvider);
    final currentUser = ref.watch(currentUserProvider);
    final isOwner = currentUser != null && t['user_id'] == currentUser.id;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(roomTransactionProvider(
            RoomTxKey(roomId: roomId, txId: transactionId)));
        ref.invalidate(roomTransactionsProvider(roomId));
      },
      child: ListView(
      padding: const EdgeInsets.fromLTRB(
        LoitSpacing.s5,
        LoitSpacing.s5,
        LoitSpacing.s5,
        LoitSpacing.s8,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _heroCard(context, t, catStyle, catLabel, fmt, isTransfer),
        const SizedBox(height: LoitSpacing.s5),
        const LoitGroupLabel(label: 'Created by'),
        _creatorRow(context, payer, avatarUrl, email),
        const SizedBox(height: LoitSpacing.s4),
        LoitGroupLabel(label: l.txDetailDetails),
        _row(context, l.txDetailDate,
            yMMMMEEEEd(context).add_jm().format(created)),
        _row(context, l.txDetailType, _typeName(l, type)),
        if (!isTransfer)
          _row(context, l.txDetailCategory, catLabel),
        _row(context, l.txDetailCurrency, currency),
        if (currency != homeCurrency && snapshotRate(homeCurrency) != null)
          _row(context, l.txDetailFxRate,
              snapshotRate(homeCurrency)!.toStringAsFixed(4)),
        if (currency != homeCurrency && snapshotRate(homeCurrency) != null)
          _row(
            context,
            l.txDetailHomeAmount,
            formatMoney(amount * snapshotRate(homeCurrency)!, homeCurrency),
          ),
        _row(
          context,
          'Amount',
          '${isTransfer ? '' : isIncome ? '+' : ''}${fmt(amount.abs())}',
        ),
        _row(context, l.txDetailSource, _sourceLabel(l, sourceEnum)),
        if (isOwner)
          _AccountRow(
            roomId: roomId,
            transactionId: transactionId,
            fallbackAccountId: t['account_id'] as String?,
          ),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: LoitSpacing.s4),
          LoitGroupLabel(label: l.txDetailNotes),
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
            return _BreakdownView(parsed: parsed, currency: currency);
          }),
        ],
        if (receiptUrl != null && receiptUrl.isNotEmpty) ...[
          const SizedBox(height: LoitSpacing.s4),
          LoitGroupLabel(label: l.txDetailReceipt),
          ClipRRect(
            borderRadius: LoitRadius.brM,
            child: LoitReceiptImage(path: receiptUrl),
          ),
        ],
      ],
    ),
    );
  }

  String _typeName(AppLocalizations l, String type) {
    switch (type) {
      case 'income':
        return l.txFormIncome;
      case 'transfer':
        return l.txFormTransfer;
      default:
        return l.txFormExpense;
    }
  }

  String _sourceLabel(AppLocalizations l, TxnSource s) {
    switch (s) {
      case TxnSource.scanned:
        return l.txDetailSourceScanned;
      case TxnSource.botImage:
        return l.txDetailSourceBotImage;
      case TxnSource.botChat:
        return l.txDetailSourceBotChat;
      case TxnSource.manual:
        return l.txDetailSourceManual;
    }
  }

  Widget _heroCard(
    BuildContext context,
    Map<String, dynamic> t,
    LoitCategoryStyle catStyle,
    String catLabel,
    String Function(double) fmt,
    bool isTransfer,
  ) {
    final c = context.loitColors;
    final l = context.l10n;
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
                          isTransfer ? l.txDetailFallbackTransfer : l.txDetailTitle;
                      return Text(
                          t0.isEmpty ? fallback : t0,
                          style: LoitTypography.titleM
                              .copyWith(color: c.contentPrimary));
                    }),
                    const SizedBox(height: 2),
                    Text(
                      isTransfer ? l.txDetailFallbackTransfer : catLabel,
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
            fmt(isTransfer ? amount.abs() : amount),
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
  const _BreakdownView({required this.parsed, required this.currency});
  final NotesBreakdown parsed;
  final String currency;

  static final NumberFormat _f = NumberFormat('#,##0.##', 'id_ID');

  String _money(double v) => formatMoney(v, currency);

  String _itemRight(NotesBreakdownItem it) {
    final parts = <String>[];
    if (it.qty != null && it.unitPrice != null) {
      parts.add('${_f.format(it.qty)} \u00d7 ${_money(it.unitPrice!)}');
    } else if (it.qty != null) {
      parts.add('${_f.format(it.qty)} \u00d7');
    } else if (it.unitPrice != null) {
      parts.add('\u00d7 ${_money(it.unitPrice!)}');
    }
    if (it.totalPrice != null) {
      parts.add('= ${_money(it.totalPrice!)}');
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
                          ? '\u2014'
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
                    child: Text(context.l10n.txDetailTotal,
                        style: LoitTypography.bodyM.copyWith(
                          color: c.contentPrimary,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                  Text(_money(parsed.total!),
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

class _AccountRow extends ConsumerStatefulWidget {
  const _AccountRow({
    required this.roomId,
    required this.transactionId,
    required this.fallbackAccountId,
  });
  final String roomId;
  final String transactionId;
  final String? fallbackAccountId;

  @override
  ConsumerState<_AccountRow> createState() => _AccountRowState();
}

class _AccountRowState extends ConsumerState<_AccountRow> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final fresh = ref.watch(roomTransactionProvider(
        RoomTxKey(roomId: widget.roomId, txId: widget.transactionId)));
    final accId = fresh.maybeWhen(
      data: (row) => (row?['account_id'] as String?) ?? widget.fallbackAccountId,
      orElse: () => widget.fallbackAccountId,
    );
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    Account? acc;
    for (final a in accounts) {
      if (a.id == accId) {
        acc = a;
        break;
      }
    }
    final label = acc?.name ?? (accId == null ? 'Choose account' : 'Unknown');

    return InkWell(
      onTap: _busy ? null : () => _change(accId),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s3),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(l.txDetailAccount,
                  style: LoitTypography.bodyM
                      .copyWith(color: c.contentSecondary)),
            ),
            Expanded(
              child: _busy
                  ? const _AccountShimmer()
                  : Text(label,
                      style: LoitTypography.bodyM.copyWith(
                        color: c.contentPrimary,
                        fontWeight: FontWeight.w500,
                      )),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.contentTertiary),
          ],
        ),
      ),
    );
  }

  Future<void> _change(String? currentId) async {
    final picked = await pickLoitAccount(context, selectedId: currentId);
    if (picked == null || picked == currentId) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(transactionsProvider.notifier)
          .updateTransaction(widget.transactionId, {'account_id': picked});
      ref.invalidate(roomTransactionProvider(
          RoomTxKey(roomId: widget.roomId, txId: widget.transactionId)));
      ref.invalidate(roomFeedProvider(widget.roomId));
      ref.invalidate(accountsProvider);
      // Wait one microtask so the watched provider re-emits before we drop
      // the busy flag \u2014 avoids a flash of the stale name between shimmer
      // and the refreshed value.
      await Future<void>.delayed(const Duration(milliseconds: 120));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.roomUpdateFailed(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _AccountShimmer extends StatefulWidget {
  const _AccountShimmer();

  @override
  State<_AccountShimmer> createState() => _AccountShimmerState();
}

class _AccountShimmerState extends State<_AccountShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return SizedBox(
      height: 16,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 16,
                  color: c.muted.withValues(alpha: 0.6),
                ),
                Positioned(
                  left: -60 + 180 * t,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          c.surface.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
