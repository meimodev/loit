import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/connectivity_banner.dart';
import 'auth_providers.dart';
import 'services_providers.dart';

/// Transaction row shape used by UI. Kept as a typed view over Map.
class Txn {
  final String? id;
  final double amount;
  final String currency;
  final double? amountHome;
  final double? fxRate;
  final String? category;
  final String? notes;
  final String? receiptUrl;
  final bool aiParsed;
  final bool isManualFallback;
  final DateTime createdAt;
  final String? roomId;
  final String? roomName;
  final String type; // 'expense' | 'income' | 'transfer'
  final String? accountId;
  final String? toAccountId;

  const Txn({
    required this.id,
    required this.amount,
    required this.currency,
    required this.amountHome,
    required this.fxRate,
    required this.category,
    required this.notes,
    required this.receiptUrl,
    required this.aiParsed,
    required this.isManualFallback,
    required this.createdAt,
    this.roomId,
    this.roomName,
    this.type = 'expense',
    this.accountId,
    this.toAccountId,
  });

  factory Txn.fromRow(Map<String, dynamic> r) {
    final rawType = r['type'] as String?;
    // Backward-compatible: derive type from amount sign when column absent.
    final String type;
    if (rawType != null && (rawType == 'income' || rawType == 'expense' || rawType == 'transfer')) {
      type = rawType;
    } else {
      final amt = ((r['amount'] as num?) ?? 0).toDouble();
      type = amt < 0 ? 'expense' : 'income';
    }
    return Txn(
      id: r['id'] as String?,
      amount: ((r['amount'] as num?) ?? 0).toDouble(),
      currency: (r['currency'] as String?) ?? 'IDR',
      amountHome: (r['amount_home_currency'] as num?)?.toDouble(),
      fxRate: (r['fx_rate'] as num?)?.toDouble(),
      category: r['category'] as String?,
      notes: r['notes'] as String?,
      receiptUrl: r['receipt_url'] as String?,
      aiParsed: (r['ai_parsed'] as bool?) ?? false,
      isManualFallback: (r['is_manual_fallback'] as bool?) ?? false,
      createdAt: DateTime.parse(
        (r['created_at'] as String?) ?? DateTime.now().toUtc().toIso8601String(),
      ),
      roomId: r['room_id'] as String?,
      roomName: (r['rooms'] is Map<String, dynamic>)
          ? (r['rooms'] as Map<String, dynamic>)['name'] as String?
          : null,
      type: type,
      accountId: r['account_id'] as String?,
      toAccountId: r['to_account_id'] as String?,
    );
  }

  bool get isTransfer => type == 'transfer';

  /// Income transactions: type == 'income' (or legacy negative amount).
  bool get isIncome => type == 'income';

  /// Absolute amount for display.
  double get absAmount => amount.abs();
  double get absAmountHome => (amountHome ?? amount).abs();
}

class TransactionsNotifier extends AsyncNotifier<List<Txn>> {
  @override
  Future<List<Txn>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
    final rows = await Supabase.instance.client
        .from('transactions')
        .select('*, rooms(id, name)')
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(200);
    return (rows as List)
        .map((r) => Txn.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Insert a new personal transaction. Writes online if possible, otherwise
  /// enqueues offline. UI state is optimistically updated.
  /// Returns the inserted transaction id when the online insert succeeds,
  /// or `null` when the row was queued offline (no id yet).
  Future<String?> addTransaction(Map<String, dynamic> payload) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not signed in');

    payload['user_id'] = user.id;
    payload['client_updated_at'] = DateTime.now().toUtc().toIso8601String();

    // Defensive defaults: ensure type and account_id are present so offline-queued
    // rows survive the accounts migration constraints when synced later.
    payload['type'] ??= ((payload['amount'] as num?)?.toDouble() ?? 0) < 0
        ? 'expense'
        : 'income';
    if (payload['account_id'] == null) {
      // Best-effort: look up Cash account directly to avoid circular dependency
      // with accountsProvider. SyncService also handles this for queued rows.
      try {
        final rows = await Supabase.instance.client
            .from('accounts')
            .select('id')
            .eq('user_id', user.id)
            .eq('name', 'Cash')
            .limit(1);
        if ((rows as List).isNotEmpty) {
          payload['account_id'] = rows[0]['id'] as String;
        }
      } catch (_) {}
    }

    // Optimistic local add
    final optimistic = Txn.fromRow({
      ...payload,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    });
    state = AsyncData([optimistic, ...(state.value ?? const [])]);

    if (ref.read(offlineDebugOverrideProvider) == true) {
      final db = ref.read(offlineDbProvider);
      await db.enqueue(payload);
      return null;
    }

    try {
      final inserted = await Supabase.instance.client
          .from('transactions')
          .insert(payload)
          .select('*, rooms(id, name)')
          .single();
      // Replace the optimistic head with the canonical row.
      final current = state.value ?? const [];
      final replaced = [Txn.fromRow(inserted), ...current.skip(1)];
      state = AsyncData(replaced);
      return inserted['id'] as String?;
    } catch (_) {
      // Enqueue for later sync.
      final db = ref.read(offlineDbProvider);
      await db.enqueue(payload);
      return null;
    }
  }

  Future<void> updateTransaction(
    String id,
    Map<String, dynamic> payload,
  ) async {
    payload['client_updated_at'] = DateTime.now().toUtc().toIso8601String();
    payload['id'] = id;

    if (ref.read(offlineDebugOverrideProvider) == true) {
      await ref.read(offlineDbProvider).enqueue({...payload});
      ref.invalidateSelf();
      return;
    }

    try {
      await Supabase.instance.client
          .from('transactions')
          .update(payload)
          .eq('id', id);
    } catch (_) {
      await ref.read(offlineDbProvider).enqueue({...payload});
    }
    ref.invalidateSelf();
  }

  Future<void> deleteTransaction(String id) async {
    final cur = state.value ?? const [];
    state = AsyncData(cur.where((t) => t.id != id).toList());

    if (ref.read(offlineDebugOverrideProvider) == true) {
      await ref.read(offlineDbProvider).enqueue({'_op': 'delete', 'id': id});
      return;
    }

    try {
      await Supabase.instance.client.from('transactions').delete().eq('id', id);
    } catch (_) {
      await ref.read(offlineDbProvider).enqueue({'_op': 'delete', 'id': id});
    }
  }

  Future<void> refresh() => ref.refresh(transactionsProvider.future);
}

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<Txn>>(
      TransactionsNotifier.new,
    );
