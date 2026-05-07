import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/utils/amount_input.dart';
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

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      _nameCtrl.text = a.name;
      _kind = a.kind;
      _currency = a.currency;
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
    final err = name.isEmpty ? 'Name required' : null;
    setState(() => _nameError = err);
    return err == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
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
      } else {
        await notifier.updateAccount(widget.account!.id, {
          'name': _nameCtrl.text.trim(),
          'kind': _kind == AccountKind.asset ? 'asset' : 'liability',
          'currency': _currency,
          'initial_balance': initial,
        });
      }
      if (mounted) context.pop();
    } on AccountNameTakenException {
      if (mounted) setState(() => _nameError = 'Name already used');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _archive() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Archive account?'),
        content: const Text('The account will be hidden but data is kept.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Archive')),
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
    final accountId = widget.account!.id;
    final txns = ref.read(transactionsProvider).value ?? const [];
    final affected = txns
        .where((t) => t.accountId == accountId || t.toAccountId == accountId)
        .length;
    final c = context.loitColors;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          affected == 0
              ? 'This permanently deletes "${widget.account!.name}". This cannot be undone.'
              : 'This permanently deletes "${widget.account!.name}" and $affected transaction${affected == 1 ? '' : 's'} that reference it. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
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
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickCurrency() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in kCommonCurrencies)
              ListTile(
                title: Text(c),
                trailing: c == _currency
                    ? Icon(Icons.check_rounded,
                        color: context.loitColors.brand)
                    : null,
                onTap: () => Navigator.pop(context, c),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked != _currency) {
      setState(() => _currency = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final isEdit = widget.account != null;
    if (isEdit && _kind == AccountKind.liability) {
      final balances = ref.watch(accountBalancesProvider);
      final balance = balances[widget.account!.id] ?? 0;
      _balanceCtrl.text = formatAmountInput(balance.abs());
    }

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit account' : 'New account'),
        actions: [
          if (isEdit)
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Archive',
              onPressed: _archive,
            ),
          if (isEdit)
            IconButton(
              icon: Icon(Icons.delete_outline, color: c.danger),
              tooltip: 'Delete',
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(LoitSpacing.s5),
        children: [
          LoitInput(
            controller: _nameCtrl,
            label: 'Name',
            placeholder: 'e.g. BCA Savings',
            error: _nameError,
          ),
          const SizedBox(height: LoitSpacing.s4),
          Text(
            'Type',
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
                  label: 'Asset',
                  icon: Icons.account_balance_wallet_outlined,
                  selected: _kind == AccountKind.asset,
                  color: c.info,
                  onTap: () => setState(() => _kind = AccountKind.asset),
                ),
              ),
              const SizedBox(width: LoitSpacing.s3),
              Expanded(
                child: _KindOption(
                  label: 'Liability',
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
            label: 'Currency',
            value: _currency,
            onTap: _pickCurrency,
          ),
          const SizedBox(height: LoitSpacing.s4),
          LoitInput(
            controller: _balanceCtrl,
            label: isEdit ? 'Current balance' : 'Opening balance',
            enabled: _kind != AccountKind.liability,
            placeholder: '0',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ThousandsInputFormatter(),
            ],
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
                : Text(isEdit ? 'Save changes' : 'Create account'),
          ),
          if (isEdit) _recentTransactions(widget.account!.id),
        ],
      ),
    );
  }

  Widget _liabilityInfoBox() {
    final c = context.loitColors;
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
              'For loans, create a Transfer from this liability account to an asset account.',
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
    final txns = ref.watch(transactionsProvider).value ?? const [];
    final allAccounts = ref.watch(accountsProvider).value ?? const [];
    final accountMap = {for (final a in allAccounts) a.id: a};

    final recent = txns
        .where((t) => t.accountId == accountId || t.toAccountId == accountId)
        .toList();
    recent.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final top10 = recent.take(10).toList();

    if (top10.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: LoitSpacing.s6),
        Text(
          'Recent transactions',
          style: LoitTypography.bodyM.copyWith(
            color: c.contentPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: LoitSpacing.s3),
        for (int i = 0; i < top10.length; i++) ...[
          _txRow(top10[i], accountMap, i != top10.length - 1),
        ],
      ],
    );
  }

  Widget _txRow(Txn t, Map<String, Account> accountMap, bool showDivider) {
    final fromName = t.accountId != null ? accountMap[t.accountId]?.name : null;
    final toName = t.toAccountId != null ? accountMap[t.toAccountId]?.name : null;
    final accountLabel = t.isTransfer && fromName != null && toName != null
        ? '$fromName → $toName'
        : fromName;
    final time = DateFormat.jm().format(t.createdAt.toLocal());
    final cat = (t.category ?? 'other');

    return LoitTxRow(
      title: breakdownTitle(t.notes),
      amount: NumberFormat.simpleCurrency(name: t.currency, decimalDigits: currencyDecimals(t.currency))
          .format(t.amount),
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
