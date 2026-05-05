import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/loit_group_label.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final accountsAsync = ref.watch(accountsProvider);
    final balances = ref.watch(accountBalancesProvider);
    final profile = ref.watch(userProfileProvider).value;
    final currency = profile?.homeCurrency ?? 'IDR';

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: const Text('Accounts'),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: accountsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (accounts) {
          final assets =
              accounts.where((a) => a.kind == AccountKind.asset).toList();
          final liabilities =
              accounts.where((a) => a.kind == AccountKind.liability).toList();

          if (accounts.isEmpty) {
            return _EmptyAccountsState(currency: currency);
          }

          return ListView(
            children: [
              if (assets.isNotEmpty) ...[
                const LoitGroupLabel(label: 'Assets'),
                Container(
                  color: c.surface,
                  child: Column(
                    children: [
                      for (var i = 0; i < assets.length; i++)
                        Dismissible(
                          key: ValueKey(assets[i].id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            final txns =
                                ref.read(transactionsProvider).value ?? const [];
                            final account = assets[i];
                            final affected = txns
                                .where((t) =>
                                    t.accountId == account.id ||
                                    t.toAccountId == account.id)
                                .length;
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete account?'),
                                    content: Text(
                                      affected == 0
                                          ? 'This permanently deletes "${account.name}". This cannot be undone.'
                                          : 'This permanently deletes "${account.name}" and $affected transaction${affected == 1 ? '' : 's'} that reference it. This cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                            backgroundColor: c.danger),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (_) {
                            ref
                                .read(accountsProvider.notifier)
                                .deleteAccount(assets[i].id);
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: c.danger,
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white),
                          ),
                          child: _AccountRow(
                            account: assets[i],
                            balance: balances[assets[i].id] ?? 0,
                            currency: currency,
                            showDivider: i != assets.length - 1,
                            onTap: () => context.push(
                              '/accounts/${assets[i].id}/edit',
                              extra: assets[i],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (liabilities.isNotEmpty) ...[
                const LoitGroupLabel(label: 'Liabilities'),
                Container(
                  color: c.surface,
                  child: Column(
                    children: [
                      for (var i = 0; i < liabilities.length; i++)
                        Dismissible(
                          key: ValueKey(liabilities[i].id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) async {
                            final txns =
                                ref.read(transactionsProvider).value ?? const [];
                            final account = liabilities[i];
                            final affected = txns
                                .where((t) =>
                                    t.accountId == account.id ||
                                    t.toAccountId == account.id)
                                .length;
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Delete account?'),
                                    content: Text(
                                      affected == 0
                                          ? 'This permanently deletes "${account.name}". This cannot be undone.'
                                          : 'This permanently deletes "${account.name}" and $affected transaction${affected == 1 ? '' : 's'} that reference it. This cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                            backgroundColor: c.danger),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (_) {
                            ref
                                .read(accountsProvider.notifier)
                                .deleteAccount(liabilities[i].id);
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: c.danger,
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white),
                          ),
                          child: _AccountRow(
                            account: liabilities[i],
                            balance: balances[liabilities[i].id] ?? 0,
                            currency: currency,
                            showDivider: i != liabilities.length - 1,
                            onTap: () => context.push(
                              '/accounts/${liabilities[i].id}/edit',
                              extra: liabilities[i],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/accounts/new'),
        icon: const Icon(Icons.add),
        label: const Text('Add account'),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.balance,
    required this.currency,
    required this.showDivider,
    required this.onTap,
  });

  final Account account;
  final double balance;
  final String currency;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final fmt = NumberFormat.simpleCurrency(name: currency, decimalDigits: 0);
    final isAsset = account.kind == AccountKind.asset;
    final iconColor = isAsset ? c.info : c.danger;

    final row = InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LoitSpacing.s5,
          vertical: LoitSpacing.s4,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: LoitRadius.brM,
              ),
              alignment: Alignment.center,
              child: Icon(
                isAsset
                    ? Icons.account_balance_wallet_outlined
                    : Icons.credit_card_outlined,
                size: 18,
                color: iconColor,
              ),
            ),
            const SizedBox(width: LoitSpacing.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: LoitTypography.bodyM.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    isAsset ? 'Asset · ${account.currency}' : 'Liability · ${account.currency}',
                    style: LoitTypography.bodyS.copyWith(
                      color: c.contentTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              fmt.format(balance),
              style: LoitTypography.amountDefault.copyWith(
                // Assets: red when overdrawn. Liabilities: red when owed (> 0).
                color: isAsset
                    ? (balance >= 0 ? c.contentPrimary : c.danger)
                    : (balance > 0 ? c.danger : c.success),
              ),
            ),
            const SizedBox(width: LoitSpacing.s2),
            Icon(Icons.chevron_right, size: 16, color: c.contentTertiary),
          ],
        ),
      ),
    );

    if (!showDivider) return row;
    return Column(
      children: [
        row,
        Container(
          height: 1,
          color: c.borderSubtle,
          margin: const EdgeInsets.only(
              left: LoitSpacing.s5 + 36 + LoitSpacing.s4),
        ),
      ],
    );
  }
}

class _EmptyAccountsState extends StatelessWidget {
  const _EmptyAccountsState({required this.currency});
  final String currency;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LoitSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 48, color: c.brand),
            const SizedBox(height: LoitSpacing.s4),
            Text(
              'No accounts yet',
              style: LoitTypography.titleM.copyWith(color: c.contentPrimary),
            ),
            const SizedBox(height: LoitSpacing.s2),
            Text(
              'Add your cash, bank accounts, and cards to track balances.',
              textAlign: TextAlign.center,
              style: LoitTypography.bodyM.copyWith(color: c.contentSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
