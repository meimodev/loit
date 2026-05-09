import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/loit_group_label.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l = context.l10n;
    final accountsAsync = ref.watch(accountsProvider);
    final balances = ref.watch(accountBalancesProvider);
    final profile = ref.watch(userProfileProvider).value;
    final currency = profile?.homeCurrency ?? 'IDR';

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l.accountsScreenTitle),
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
                LoitGroupLabel(label: l.accountsScreenAssets),
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
                                    title: Text(l.accountFormDeleteTitle),
                                    content: Text(
                                      _deleteBody(l, account.name, affected),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(l.accountFormCancel),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                            backgroundColor: c.danger),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(l.accountFormDelete),
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
                LoitGroupLabel(label: l.accountsScreenLiabilities),
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
                                    title: Text(l.accountFormDeleteTitle),
                                    content: Text(
                                      _deleteBody(l, account.name, affected),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: Text(l.accountFormCancel),
                                      ),
                                      FilledButton(
                                        style: FilledButton.styleFrom(
                                            backgroundColor: c.danger),
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: Text(l.accountFormDelete),
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
        label: Text(l.accountsScreenAddAccount),
      ),
    );
  }

  String _deleteBody(AppLocalizations l, String name, int affected) {
    if (affected == 0) {
      return l.accountFormDeleteBody(name);
    }
    return l.accountFormDeleteBodyWithTxns(name, affected,
        affected == 1 ? '' : 's');
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
    final l = context.l10n;
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
                    isAsset
                        ? l.accountsScreenAssetType(account.currency)
                        : l.accountsScreenLiabilityType(account.currency),
                    style: LoitTypography.bodyS.copyWith(
                      color: c.contentTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              formatMoney(balance, currency),
              style: LoitTypography.amountDefault.copyWith(
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
    final l = context.l10n;
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
              l.accountsScreenNoAccounts,
              style: LoitTypography.titleM.copyWith(color: c.contentPrimary),
            ),
            const SizedBox(height: LoitSpacing.s2),
            Text(
              l.accountsScreenEmptyBody,
              textAlign: TextAlign.center,
              style: LoitTypography.bodyM.copyWith(color: c.contentSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
