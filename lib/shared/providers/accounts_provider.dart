import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_providers.dart';
import 'transactions_provider.dart';

enum AccountKind { asset, liability }

/// Thrown when inserting an account whose name already exists for the user
/// (Postgres unique_violation code 23505 on accounts_name_lower_user_idx).
class AccountNameTakenException implements Exception {
  const AccountNameTakenException();
  @override
  String toString() => 'An account with that name already exists.';
}

class Account {
  final String id;
  final String userId;
  final String name;
  final AccountKind kind;
  final String currency;
  final double initialBalance;
  final String? icon;
  final String? color;
  final DateTime? archivedAt;
  final DateTime createdAt;

  const Account({
    required this.id,
    required this.userId,
    required this.name,
    required this.kind,
    required this.currency,
    required this.initialBalance,
    this.icon,
    this.color,
    this.archivedAt,
    required this.createdAt,
  });

  factory Account.fromRow(Map<String, dynamic> r) => Account(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        name: r['name'] as String,
        kind: (r['kind'] as String?) == 'liability'
            ? AccountKind.liability
            : AccountKind.asset,
        currency: (r['currency'] as String?) ?? 'IDR',
        initialBalance: ((r['initial_balance'] as num?) ?? 0).toDouble(),
        icon: r['icon'] as String?,
        color: r['color'] as String?,
        archivedAt: r['archived_at'] != null
            ? DateTime.parse(r['archived_at'] as String)
            : null,
        createdAt: DateTime.parse(
          (r['created_at'] as String?) ?? DateTime.now().toUtc().toIso8601String(),
        ),
      );
}

class AccountsNotifier extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
    // Fetch ALL accounts (including archived) so lookup maps for transactions
    // remain complete after archiving. Use activeAccountsProvider for UI lists/pickers.
    final rows = await Supabase.instance.client
        .from('accounts')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: true);
    final accounts = (rows as List)
        .map((r) => Account.fromRow(r as Map<String, dynamic>))
        .toList();
    // Client-side fallback: ensure new users always have a default Cash account
    // even if the DB trigger failed or was added later.
    if (accounts.isEmpty) {
      try {
        final profile = await Supabase.instance.client
            .from('users')
            .select('home_currency')
            .eq('id', user.id)
            .single();
        final currency = (profile['home_currency'] as String?) ?? 'IDR';
        final inserted = await Supabase.instance.client
            .from('accounts')
            .insert({
              'user_id': user.id,
              'name': 'Cash',
              'kind': 'asset',
              'currency': currency,
              'initial_balance': 0,
            })
            .select()
            .single();
        return [Account.fromRow(inserted)];
      } catch (_) {
        return const [];
      }
    }
    return accounts;
  }

  Future<Account> addAccount({
    required String name,
    required AccountKind kind,
    required String currency,
    double initialBalance = 0,
    String? icon,
    String? color,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not signed in');
    final payload = {
      'user_id': user.id,
      'name': name,
      'kind': kind == AccountKind.asset ? 'asset' : 'liability',
      'currency': currency,
      'initial_balance': initialBalance,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      'client_updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    try {
      final inserted = await Supabase.instance.client
          .from('accounts')
          .insert(payload)
          .select()
          .single();
      final account = Account.fromRow(inserted);
      final cur = state.value ?? const [];
      state = AsyncData([...cur, account]);
      return account;
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const AccountNameTakenException();
      rethrow;
    }
  }

  Future<void> updateAccount(
    String id,
    Map<String, dynamic> payload,
  ) async {
    payload['client_updated_at'] = DateTime.now().toUtc().toIso8601String();
    await Supabase.instance.client
        .from('accounts')
        .update(payload)
        .eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> archiveAccount(String id) async {
    await Supabase.instance.client.from('accounts').update({
      'archived_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', id);
    final cur = state.value ?? const [];
    state = AsyncData(cur.where((a) => a.id != id).toList());
  }

  /// Permanently deletes an account and all transactions referencing it
  /// (either as source or destination). Transactions FK uses ON DELETE RESTRICT
  /// so they must be removed first.
  Future<void> deleteAccount(String id) async {
    final client = Supabase.instance.client;
    await client
        .from('transactions')
        .delete()
        .or('account_id.eq.$id,to_account_id.eq.$id');
    await client.from('accounts').delete().eq('id', id);
    final cur = state.value ?? const [];
    state = AsyncData(cur.where((a) => a.id != id).toList());
    ref.invalidate(transactionsProvider);
  }

  Future<void> refresh() => ref.refresh(accountsProvider.future);
}

final accountsProvider =
    AsyncNotifierProvider<AccountsNotifier, List<Account>>(
      AccountsNotifier.new,
    );

/// Active (non-archived) accounts for pickers and dashboard card lists.
/// Use accountsProvider directly when building lookup maps for transactions.
final activeAccountsProvider = Provider<List<Account>>((ref) {
  final accounts = ref.watch(accountsProvider).value ?? const [];
  return accounts.where((a) => a.archivedAt == null).toList();
});

/// Balance per account in home currency.
///
/// Liability initial balance stored negative; income adds (pay debt),
/// expense subtracts (charge increases debt). Liability balance stays ≤ 0.
/// Asset convention: income adds, expense subtracts.
final accountBalancesProvider = Provider<Map<String, double>>((ref) {
  final accounts = ref.watch(accountsProvider).value ?? const [];
  final txns = ref.watch(transactionsProvider).value ?? const [];
  final map = <String, double>{};
  for (final a in accounts) {
    map[a.id] = a.initialBalance;
  }
  for (final t in txns) {
    if (t.accountId == null) continue;
    final double v;
    if (t.amountHome != null) {
      v = t.amountHome!.abs();
    } else if (t.fxRate != null) {
      v = (t.amount * t.fxRate!).abs();
    } else {
      continue;
    }

    if (t.type == 'transfer') {
      map[t.accountId!] = (map[t.accountId!] ?? 0) - v;
      if (t.toAccountId != null) {
        map[t.toAccountId!] = (map[t.toAccountId!] ?? 0) + v;
      }
    } else if (t.type == 'income') {
      map[t.accountId!] = (map[t.accountId!] ?? 0) + v;
    } else {
      map[t.accountId!] = (map[t.accountId!] ?? 0) - v;
    }
  }
  return map;
});

final totalAssetsProvider = Provider<double>((ref) {
  final balances = ref.watch(accountBalancesProvider);
  return balances.values.where((v) => v > 0).fold(0.0, (s, v) => s + v);
});

final totalLiabilitiesProvider = Provider<double>((ref) {
  final balances = ref.watch(accountBalancesProvider);
  return balances.values.where((v) => v < 0).fold(0.0, (s, v) => s + v);
});

final netWorthProvider = Provider<double>((ref) {
  return ref.watch(totalAssetsProvider) + ref.watch(totalLiabilitiesProvider);
});
