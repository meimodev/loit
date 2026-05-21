import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/currency_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/services_providers.dart';
import '../../shared/providers/supported_currencies_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/utils/locale_date_format.dart';
import '../../shared/widgets/currency_picker_sheet.dart';
import '../../shared/widgets/loit_input.dart';
import '../../shared/widgets/loit_tx_row.dart';
import '../transactions/notes_breakdown.dart';

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.account});
  final Account? account;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _nameCtrl = TextEditingController();
  final _balanceCtrl = TextEditingController();
  AccountKind _kind = AccountKind.asset;
  late String _currency;
  bool _busy = false;
  String? _nameError;
  bool _balanceUserEdited = false;
  bool _balanceSeeded = false;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      _nameCtrl.text = a.name;
      _kind = a.kind;
      _currency = a.currency;
      // Seed with initial_balance as a fallback. build() will refresh this
      // with the live computed balance once transactions are loaded.
      _balanceCtrl.text = a.initialBalance != 0
          ? formatAmountInput(a.initialBalance.abs())
          : '';
    } else {
      _currency = 'IDR';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _balanceCtrl.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _nameCtrl.text.trim();
    final l = context.l10n;
    final err = name.isEmpty ? l.accountFormNameRequired : null;
    setState(() => _nameError = err);
    return err == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    final l = context.l10n;
    setState(() => _busy = true);
    try {
      final notifier = ref.read(accountsProvider.notifier);
      final raw = parseAmountInput(_balanceCtrl.text) ?? 0;
      final initial = _kind == AccountKind.liability ? -raw.abs() : raw;

      if (widget.account == null) {
        await notifier.addAccount(
          name: _nameCtrl.text.trim(),
          kind: _kind,
          currency: _currency,
          initialBalance: initial,
        );
        if (mounted) context.pop();
        return;
      }

      final old = widget.account!;
      final kindStr = _kind == AccountKind.asset ? 'asset' : 'liability';
      final kindUnchanged = old.kind == _kind;

      // Asset balance edits go through an Adjustment transaction so the
      // running ledger stays consistent. Liability balance is read-only in
      // the form, and kind switches fall back to the legacy direct write.
      if (_kind == AccountKind.asset && kindUnchanged) {
        final balances = ref.read(accountNativeBalancesProvider);
        final currentBalance = balances[old.id] ?? old.initialBalance;
        final delta = raw - currentBalance;
        if (delta.abs() > 0.005) {
          final confirmed = await _confirmAdjustment(
            current: currentBalance,
            target: raw,
            delta: delta,
          );
          if (confirmed != true) {
            if (mounted) setState(() => _busy = false);
            return;
          }
          await notifier.updateAccount(old.id, {
            'name': _nameCtrl.text.trim(),
            'kind': kindStr,
            'currency': _currency,
          });
          final signedAmount = delta; // >0 income, <0 expense
          final svc = ref.read(currencyServiceProvider);
          final rates = await svc.loadUsdBaseRates();
          final supported = ref.read(supportedCurrenciesProvider).value;
          final codes = supported?.codes ?? rates.keys.toList(growable: false);
          final fxSnapshot = CurrencyService.buildSnapshot(
            from: _currency,
            rates: rates,
            supported: codes,
          );
          await ref.read(transactionsProvider.notifier).addTransaction({
            'amount': signedAmount,
            'currency': _currency,
            'fx_snapshot': fxSnapshot,
            'type': delta > 0 ? 'income' : 'expense',
            'account_id': old.id,
            'category': 'adjustment',
            'notes': l.accountFormBalanceAdjustment,
            'ai_parsed': false,
            'is_manual_fallback': false,
            'source': 'manual',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          });
        } else {
          await notifier.updateAccount(old.id, {
            'name': _nameCtrl.text.trim(),
            'kind': kindStr,
            'currency': _currency,
          });
        }
      } else {
        await notifier.updateAccount(old.id, {
          'name': _nameCtrl.text.trim(),
          'kind': kindStr,
          'currency': _currency,
          'initial_balance': initial,
        });
      }

      if (mounted) context.pop();
    } on AccountNameTakenException {
      if (mounted) {
        setState(() => _nameError = l.accountFormNameAlreadyUsed);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.accountFormSaveFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool?> _confirmAdjustment({
    required double current,
    required double target,
    required double delta,
  }) {
    final l = context.l10n;
    final isIncome = delta > 0;
    final txLabel = isIncome ? l.txFormIncome : l.txFormExpense;
    final deltaStr = formatMoney(delta.abs(), _currency);
    final currentStr = formatMoney(current, _currency);
    final targetStr = formatMoney(target, _currency);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.accountFormAddAdjustmentTitle),
        content: Text(
          l.accountFormAddAdjustmentBody(
            currentStr,
            targetStr,
            txLabel,
            deltaStr,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.accountFormCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.accountFormAddAdjustment),
          ),
        ],
      ),
    );
  }

  Future<void> _archive() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.accountFormArchiveTitle),
        content: Text(l.accountFormArchiveBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.accountFormCancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.accountFormArchive)),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref
        .read(accountsProvider.notifier)
        .archiveAccount(widget.account!.id);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final accountId = widget.account!.id;
    final txns = ref.read(transactionsProvider).value ?? const [];
    final affected = txns
        .where((t) => t.accountId == accountId || t.toAccountId == accountId)
        .length;
    final c = context.loitColors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.accountFormDeleteTitle),
        content: Text(
          affected == 0
              ? l.accountFormDeleteBody(widget.account!.name)
              : l.accountFormDeleteBodyWithTxns(
                  widget.account!.name,
                  affected,
                  affected == 1 ? '' : 's',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.accountFormCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.danger),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l.accountFormDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref.read(accountsProvider.notifier).deleteAccount(accountId);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l.accountFormDeleteFailed('$e'))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickCurrency() async {
    final picked = await pickCurrency(context, selected: _currency);
    if (picked != null && picked != _currency) {
      setState(() => _currency = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final isEdit = widget.account != null;
    if (isEdit) {
      final balances = ref.watch(accountNativeBalancesProvider);
      final balance = balances[widget.account!.id] ?? 0;
      // Liability balance is read-only — always reflect computed value.
      // Asset balance seeds once with computed value; further updates pause
      // the moment the user edits the field.
      if (_kind == AccountKind.liability) {
        _balanceCtrl.text = formatAmountInput(balance.abs());
      } else if (!_balanceUserEdited) {
        final next = balance != 0 ? formatAmountInput(balance.abs()) : '';
        if (!_balanceSeeded || _balanceCtrl.text != next) {
          _balanceCtrl.text = next;
          _balanceSeeded = true;
        }
      }
    }

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(isEdit ? l.accountFormEditAccount : l.accountFormNewAccount),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: l.accountFormArchive,
              onPressed: _archive,
            ),
          if (isEdit)
            IconButton(
              icon: Icon(Icons.delete_outline, color: c.danger),
              tooltip: l.accountFormDelete,
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(LoitSpacing.s5),
        children: [
          LoitInput(
            controller: _nameCtrl,
            label: l.accountFormName,
            placeholder: l.accountFormNamePlaceholder,
            error: _nameError,
          ),
          const SizedBox(height: LoitSpacing.s4),
          Text(
            l.accountFormType,
            style: LoitTypography.bodyM.copyWith(
              color: c.contentPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _KindOption(
                  label: l.accountFormAsset,
                  icon: Icons.account_balance_wallet_outlined,
                  selected: _kind == AccountKind.asset,
                  color: c.info,
                  onTap: () => setState(() => _kind = AccountKind.asset),
                ),
              ),
              const SizedBox(width: LoitSpacing.s3),
              Expanded(
                child: _KindOption(
                  label: l.accountFormLiability,
                  icon: Icons.credit_card_outlined,
                  selected: _kind == AccountKind.liability,
                  color: c.danger,
                  onTap: () => setState(() => _kind = AccountKind.liability),
                ),
              ),
            ],
          ),
          if (_kind == AccountKind.liability) ...[
            const SizedBox(height: LoitSpacing.s4),
            _liabilityInfoBox(),
          ],
          const SizedBox(height: LoitSpacing.s4),
          _picker(
            label: l.accountFormCurrency,
            value: _currency,
            onTap: _pickCurrency,
          ),
          const SizedBox(height: LoitSpacing.s4),
          LoitInput(
            controller: _balanceCtrl,
            label: isEdit ? l.accountFormCurrentBalance : l.accountFormOpeningBalance,
            enabled: _kind != AccountKind.liability,
            placeholder: '0',
            leading: Padding(
              padding: const EdgeInsets.only(right: LoitSpacing.s2),
              child: Text(
                _currency,
                style: LoitTypography.bodyM.copyWith(
                  color: c.contentSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ThousandsInputFormatter(),
            ],
            onChanged: (_) {
              if (!_balanceUserEdited) {
                _balanceUserEdited = true;
              }
            },
          ),
          const SizedBox(height: LoitSpacing.s7),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: _busy ? null : _save,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? l.accountFormSaveChanges : l.accountFormCreateAccount),
          ),
          if (isEdit) _recentTransactions(widget.account!.id),
        ],
      ),
    );
  }

  Widget _liabilityInfoBox() {
    final c = context.loitColors;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LoitSpacing.s4,
        vertical: LoitSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: c.infoSurface,
        borderRadius: LoitRadius.brM,
        border: Border.all(color: c.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: c.info),
          const SizedBox(width: LoitSpacing.s2),
          Expanded(
            child: Text(
              l.accountFormLiabilityInfo,
              style: LoitTypography.bodyS.copyWith(
                color: c.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentTransactions(String accountId) {
    final c = context.loitColors;
    final l = context.l10n;
    final txns = ref.watch(transactionsProvider).value ?? const [];
    final allAccounts = ref.watch(accountsProvider).value ?? const [];
    final accountMap = {for (final a in allAccounts) a.id: a};

    final recent = txns
        .where((t) => t.accountId == accountId || t.toAccountId == accountId)
        .toList();
    recent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final top10 = recent.take(10).toList();

    if (top10.isEmpty) return const SizedBox.shrink();

    final usdRates = ref.watch(usdBaseRatesProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: LoitSpacing.s6),
        Text(
          l.accountFormRecentTransactions,
          style: LoitTypography.bodyM.copyWith(
            color: c.contentPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LoitSpacing.s3),
        for (int i = 0; i < top10.length; i++) ...[
          _txRow(top10[i], accountMap, usdRates, i != top10.length - 1),
        ],
      ],
    );
  }

  double? _convertTo(Txn t, String target, Map<String, double>? usdRates) {
    if (t.currency == target) return t.amount;
    final snap = t.fxSnapshot[target];
    if (snap != null) return t.amount * snap;
    if (usdRates != null) {
      try {
        final r = CurrencyService.convert(
          from: t.currency,
          to: target,
          rates: usdRates,
        );
        return t.amount * r;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Widget _txRow(
    Txn t,
    Map<String, Account> accountMap,
    Map<String, double>? usdRates,
    bool showDivider,
  ) {
    final fromName = t.accountId != null ? accountMap[t.accountId]?.name : null;
    final toName = t.toAccountId != null ? accountMap[t.toAccountId]?.name : null;
    final accountLabel = t.isTransfer && fromName != null && toName != null
        ? '$fromName → $toName'
        : fromName;
    final time = jm(context).format(t.createdAt.toLocal());
    final cat = (t.category ?? 'other');
    final acc = widget.account!.currency;
    final accAmount = t.currency != acc ? _convertTo(t, acc, usdRates) : null;
    final subAmount = accAmount != null
        ? '≈ ${formatMoney(accAmount, acc)}'
        : null;

    return LoitTxRow(
      title: breakdownTitle(t.notes),
      amount: formatMoney(t.amount, t.currency),
      subAmount: subAmount,
      categoryKey: t.isTransfer ? null : t.category,
      subtitle: '${_capitalize(cat)} · $time',
      isIncome: t.isIncome,
      isTransfer: t.isTransfer,
      accountLabel: accountLabel,
      showDivider: showDivider,
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  Widget _picker({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final c = context.loitColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: LoitTypography.bodyM.copyWith(
              color: c.contentPrimary,
              fontWeight: FontWeight.w600,
            )),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: LoitRadius.brM,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: LoitRadius.brM,
              border: Border.all(color: c.borderDefault),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(value,
                      style: LoitTypography.bodyL
                          .copyWith(color: c.contentPrimary)),
                ),
                Icon(Icons.expand_more, color: c.contentSecondary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _KindOption extends StatelessWidget {
  const _KindOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return InkWell(
      onTap: onTap,
      borderRadius: LoitRadius.brM,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          vertical: LoitSpacing.s3,
          horizontal: LoitSpacing.s4,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : c.surface,
          borderRadius: LoitRadius.brM,
          border: Border.all(
            color: selected ? color : c.borderDefault,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : c.contentSecondary),
            const SizedBox(width: 6),
            Text(
              label,
              style: LoitTypography.bodyM.copyWith(
                color: selected ? color : c.contentSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
