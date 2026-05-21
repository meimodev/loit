import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/loit_categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
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
import '../../shared/widgets/loit_animations.dart';
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
                '_source': txnSourceToString(t.source),
                '_ai_parsed': t.aiParsed,
                '_manual_fallback': t.isManualFallback,
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

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(transactionsProvider.notifier).refresh();
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
        if (isUnsynced) ...[
          LoitFadeSlideIn(
            child: LoitBanner(
              kind: LoitBannerKind.warning,
              title: l.txDetailNotSynced,
              body: l.txDetailNotSyncedBody,
            ),
          ),
          const SizedBox(height: LoitSpacing.s4),
        ],
        LoitFadeSlideIn(
          delay: const Duration(milliseconds: 40),
          offset: 16,
          child: _heroCard(context, t, catStyle, catLabel, homeCurrency),
        ),
        const SizedBox(height: LoitSpacing.s5),
        LoitFadeSlideIn(
          delay: const Duration(milliseconds: 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              if (t.currency != homeCurrency &&
                  t.fxSnapshot.containsKey(homeCurrency))
                _row(
                  context,
                  l.txDetailFxRate,
                  t.fxSnapshot[homeCurrency]!.toStringAsFixed(4),
                ),
              if (t.currency != homeCurrency &&
                  t.fxSnapshot.containsKey(homeCurrency))
                _row(
                  context,
                  l.txDetailHomeAmount,
                  formatMoney(t.amountIn(homeCurrency), homeCurrency),
                ),
              _row(context, l.txDetailSource, _sourceLabel(l, t.source)),
            ],
          ),
        ),
        if ((t.notes != null && t.notes!.isNotEmpty) ||
            (t.aiParsed && t.id != null && !isUnsynced)) ...[
          const SizedBox(height: LoitSpacing.s4),
          LoitFadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LoitGroupLabel(label: l.txDetailNotes),
                Builder(builder: (_) {
                  final parsed = parseBreakdown(t.notes);
                  if (t.aiParsed && t.id != null && !isUnsynced) {
                    return _ScanPreviewEditor(
                      txn: t,
                      parsed: parsed ??
                          NotesBreakdown(
                            merchant:
                                (t.notes ?? '').trim().split('\n').first,
                            items: const [],
                            total: t.absAmount,
                            currency: t.currency,
                          ),
                    );
                  }
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
                  return _BreakdownView(parsed: parsed, currency: t.currency);
                }),
              ],
            ),
          ),
        ],
        if (t.receiptUrl != null) ...[
          const SizedBox(height: LoitSpacing.s4),
          LoitFadeSlideIn(
            delay: const Duration(milliseconds: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LoitGroupLabel(label: l.txDetailReceipt),
                ClipRRect(
                  borderRadius: LoitRadius.brM,
                  child: LoitReceiptImage(path: t.receiptUrl!),
                ),
              ],
            ),
          ),
        ],
        if (!isUnsynced) ...[
          const SizedBox(height: LoitSpacing.s6),
          LoitFadeSlideIn(
            delay: const Duration(milliseconds: 380),
            child: OutlinedButton.icon(
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
          ),
        ],
      ],
    ),
    );
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
          Align(
            alignment: Alignment.centerLeft,
            child: LoitScaleIn(
              from: 0.9,
              duration: LoitMotion.emphasized,
              delay: const Duration(milliseconds: 120),
              child: LoitAmountText.money(
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

class _ScanPreviewEditor extends ConsumerStatefulWidget {
  const _ScanPreviewEditor({required this.txn, required this.parsed});

  final Txn txn;
  final NotesBreakdown parsed;

  @override
  ConsumerState<_ScanPreviewEditor> createState() => _ScanPreviewEditorState();
}

class _ScanPreviewEditorState extends ConsumerState<_ScanPreviewEditor> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _merchantCtl;
  late TextEditingController _totalCtl;
  late DateTime _date;
  late List<_ItemDraft> _items;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  void _hydrate() {
    final p = widget.parsed;
    _merchantCtl = TextEditingController(text: p.merchant);
    final total = p.total ?? widget.txn.absAmount;
    _totalCtl = TextEditingController(text: _fmt(total));
    _date = widget.txn.createdAt.toLocal();
    _items = [
      for (final it in p.items)
        _ItemDraft(
          name: TextEditingController(text: it.name),
          qty: TextEditingController(
              text: it.qty != null ? _fmt(it.qty!) : ''),
          unit: TextEditingController(
              text: it.unitPrice != null ? _fmt(it.unitPrice!) : ''),
          total: TextEditingController(
              text: it.totalPrice != null ? _fmt(it.totalPrice!) : ''),
        ),
    ];
  }

  static final NumberFormat _f = NumberFormat('#,##0.##', 'id_ID');
  String _fmt(double v) => _f.format(v);

  double? _parseNum(String s) {
    final t = s.trim();
    if (t.isEmpty) return null;
    final cleaned = t.replaceAll(RegExp(r'[^\d.,-]'), '');
    if (cleaned.isEmpty) return null;
    final lastSep = cleaned.lastIndexOf(RegExp(r'[.,]'));
    if (lastSep == -1) return double.tryParse(cleaned);
    final tail = cleaned.substring(lastSep + 1);
    if (tail.isNotEmpty &&
        tail.length <= 2 &&
        !tail.contains(RegExp(r'[.,]'))) {
      final head =
          cleaned.substring(0, lastSep).replaceAll(RegExp(r'[.,]'), '');
      return double.tryParse('${head.isEmpty ? '0' : head}.$tail');
    }
    return double.tryParse(cleaned.replaceAll(RegExp(r'[.,]'), ''));
  }

  @override
  void dispose() {
    _merchantCtl.dispose();
    _totalCtl.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  void _toggleEdit(bool on) {
    setState(() {
      _merchantCtl.dispose();
      _totalCtl.dispose();
      for (final i in _items) {
        i.dispose();
      }
      _hydrate();
      _editing = on;
    });
  }

  void _addItem() {
    setState(() => _items.add(_ItemDraft.empty()));
  }

  void _removeItem(int i) {
    setState(() {
      _items[i].dispose();
      _items.removeAt(i);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted) return;
    setState(() {
      _date = DateTime(
        picked.year,
        picked.month,
        picked.day,
        time?.hour ?? _date.hour,
        time?.minute ?? _date.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l = context.l10n;
    try {
      final items = <NotesBreakdownItem>[
        for (final d in _items)
          NotesBreakdownItem(
            name: d.name.text.trim(),
            qty: _parseNum(d.qty.text),
            unitPrice: _parseNum(d.unit.text),
            totalPrice: _parseNum(d.total.text),
          ),
      ];
      final totalParsed = _parseNum(_totalCtl.text);
      final breakdown = NotesBreakdown(
        merchant: _merchantCtl.text.trim(),
        items: items,
        total: totalParsed,
        currency: widget.txn.currency,
      );
      final notes = formatBreakdown(breakdown);

      final itemsPayload = [
        for (final it in items)
          if (it.name.isNotEmpty ||
              it.qty != null ||
              it.unitPrice != null ||
              it.totalPrice != null)
            {
              'name': it.name,
              if (it.qty != null) 'qty': it.qty,
              if (it.unitPrice != null) 'unit_price': it.unitPrice,
              if (it.totalPrice != null) 'total_price': it.totalPrice,
            },
      ];
      final payload = <String, dynamic>{
        'notes': notes,
        'created_at': _date.toUtc().toIso8601String(),
        'items': itemsPayload,
      };
      if (totalParsed != null) {
        final signed = widget.txn.type == 'expense'
            ? -totalParsed.abs()
            : totalParsed.abs();
        payload['amount'] = signed;
      }
      await ref
          .read(transactionsProvider.notifier)
          .updateTransaction(widget.txn.id!, payload);
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.txFormSaveFailed(e.toString()))),
      );
    }
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
      child: AnimatedSize(
        duration: LoitMotion.emphasized,
        curve: LoitMotion.easeOutQuart,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: LoitMotion.short,
          switchInCurve: LoitMotion.easeOutQuart,
          switchOutCurve: LoitMotion.easeOutQuart,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(anim),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_editing ? 'edit' : 'view'),
            child:
                _editing ? _buildEdit(context, c, l) : _buildView(context, c, l),
          ),
        ),
      ),
    );
  }

  Widget _buildView(BuildContext context, LoitColors c, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.parsed.merchant.isEmpty ? '—' : widget.parsed.merchant,
                style: LoitTypography.bodyL.copyWith(
                  color: c.contentPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _toggleEdit(true),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text(l.txDetailEdit),
            ),
          ],
        ),
        const SizedBox(height: LoitSpacing.s3),
        for (var i = 0; i < widget.parsed.items.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.parsed.items[i].name.isEmpty
                        ? '—'
                        : widget.parsed.items[i].name,
                    style: LoitTypography.bodyM
                        .copyWith(color: c.contentPrimary),
                  ),
                ),
                const SizedBox(width: LoitSpacing.s3),
                Text(_itemRight(widget.parsed.items[i]),
                    style: LoitTypography.bodyS
                        .copyWith(color: c.contentSecondary)),
              ],
            ),
          ),
          if (i != widget.parsed.items.length - 1)
            Divider(height: 1, color: c.borderSubtle),
        ],
        if (widget.parsed.total != null) ...[
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
                Text(_money(widget.parsed.total!),
                    style: LoitTypography.bodyM.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _money(double v) => formatMoney(v, widget.txn.currency);

  String _itemRight(NotesBreakdownItem it) {
    final parts = <String>[];
    if (it.qty != null && it.unitPrice != null) {
      parts.add('${_fmt(it.qty!)} × ${_money(it.unitPrice!)}');
    } else if (it.qty != null) {
      parts.add('${_fmt(it.qty!)} ×');
    } else if (it.unitPrice != null) {
      parts.add('× ${_money(it.unitPrice!)}');
    }
    if (it.totalPrice != null) {
      parts.add('= ${_money(it.totalPrice!)}');
    }
    return parts.join(' ');
  }

  Widget _buildEdit(BuildContext context, LoitColors c, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _merchantCtl,
          decoration: InputDecoration(
            labelText: l.txFormMerchant,
            isDense: true,
          ),
        ),
        const SizedBox(height: LoitSpacing.s3),
        InkWell(
          onTap: _pickDate,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: l.txFormDate,
              isDense: true,
            ),
            child: Text(
              yMMMd(context).add_jm().format(_date),
              style: LoitTypography.bodyM.copyWith(color: c.contentPrimary),
            ),
          ),
        ),
        const SizedBox(height: LoitSpacing.s4),
        Text(l.txFormItemBreakdown,
            style:
                LoitTypography.labelL.copyWith(color: c.contentSecondary)),
        const SizedBox(height: LoitSpacing.s2),
        for (var i = 0; i < _items.length; i++) ...[
          _itemEditor(i, c, l),
          if (i != _items.length - 1)
            Divider(height: LoitSpacing.s4, color: c.borderSubtle),
        ],
        const SizedBox(height: LoitSpacing.s3),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add, size: 16),
            label: Text(l.txFormAddItem),
          ),
        ),
        const SizedBox(height: LoitSpacing.s3),
        TextField(
          controller: _totalCtl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: l.txFormTotal,
            isDense: true,
          ),
        ),
        const SizedBox(height: LoitSpacing.s4),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => _toggleEdit(false),
                child: Text(l.txDetailCancel),
              ),
            ),
            const SizedBox(width: LoitSpacing.s3),
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.txFormSave),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _itemEditor(int i, LoitColors c, AppLocalizations l) {
    final d = _items[i];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: d.name,
                decoration: InputDecoration(
                  labelText: l.txFormItemName,
                  isDense: true,
                ),
              ),
            ),
            IconButton(
              tooltip: l.txFormRemove,
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => _removeItem(i),
            ),
          ],
        ),
        const SizedBox(height: LoitSpacing.s2),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: d.qty,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l.txFormQty,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: LoitSpacing.s2),
            Expanded(
              child: TextField(
                controller: d.unit,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l.txFormUnitPrice,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: LoitSpacing.s2),
            Expanded(
              child: TextField(
                controller: d.total,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l.txFormTotal,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ItemDraft {
  _ItemDraft({
    required this.name,
    required this.qty,
    required this.unit,
    required this.total,
  });

  factory _ItemDraft.empty() => _ItemDraft(
        name: TextEditingController(),
        qty: TextEditingController(),
        unit: TextEditingController(),
        total: TextEditingController(),
      );

  final TextEditingController name;
  final TextEditingController qty;
  final TextEditingController unit;
  final TextEditingController total;

  void dispose() {
    name.dispose();
    qty.dispose();
    unit.dispose();
    total.dispose();
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
      parts.add('${_f.format(it.qty)} × ${_money(it.unitPrice!)}');
    } else if (it.qty != null) {
      parts.add('${_f.format(it.qty)} ×');
    } else if (it.unitPrice != null) {
      parts.add('× ${_money(it.unitPrice!)}');
    }
    if (it.totalPrice != null) {
      parts.add('= ${_money(it.totalPrice!)}');
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
