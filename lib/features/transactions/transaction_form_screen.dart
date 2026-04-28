import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/categories.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/currency_service.dart';
import '../../core/services/interaction_log_service.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/services_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/stale_rate_banner.dart';
import '../paywall/feature_gate.dart';

/// Manual transaction entry. Also used as the manual-fallback form when
/// the scanner returns [ScanErrorType.aiFailure] — pre-filled with
/// `partial_fields` from the server.
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({super.key, this.prefill});
  final Map<String, dynamic>? prefill;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchant = TextEditingController();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  late String _currency;
  String _category = 'other';
  bool _busy = false;
  bool _isManualFallback = false;
  bool _aiParsed = false;
  List<Map<String, dynamic>>? _items;
  FxRate? _fx;
  String? _roomId;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _currency = 'IDR';
    final p = widget.prefill;
    if (p != null) {
      _merchant.text = (p['merchant'] as String?) ?? '';
      final total = p['total'] ?? p['amount'];
      if (total != null) _amount.text = total.toString();
      _currency = (p['currency'] as String?) ?? 'IDR';
      final cat = p['category'] as String?;
      if (cat != null && Categories.all.contains(cat)) _category = cat;
      _roomId = p['_room_id'] as String?;
      _isManualFallback = (p['_manual_fallback'] as bool?) ?? false;
      _aiParsed = (p['_ai_parsed'] as bool?) ?? false;
      _imagePath = p['_image_path'] as String?;
      final rawItems = p['items'];
      if (rawItems is List) {
        _items = rawItems
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      }
    }
  }

  @override
  void dispose() {
    _merchant.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _recomputeFx() async {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null) return;
    final home = profile.homeCurrency;
    if (_currency == home) {
      setState(() => _fx = const FxRate(rate: 1.0, isStale: false));
      return;
    }
    try {
      final fx = await ref
          .read(currencyServiceProvider)
          .getRate(from: _currency, to: home, tier: UserTier.fromString(profile.tier));
      if (mounted) setState(() => _fx = fx);
    } catch (_) {
      if (mounted) setState(() => _fx = null);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recomputeFx();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      final amount = double.parse(_amount.text.trim());
      final rate = _fx?.rate ?? 1.0;
      final payload = <String, dynamic>{
        'merchant': _merchant.text.trim().isEmpty
            ? null
            : _merchant.text.trim(),
        'amount': amount,
        'currency': _currency,
        'amount_home_currency': amount * rate,
        'fx_rate': rate,
        'category': _category,
        'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'ai_parsed': _aiParsed,
        'is_manual_fallback': _isManualFallback,
        if (_roomId != null) 'room_id': _roomId,
      };
      final insertedId = await ref
          .read(transactionsProvider.notifier)
          .addTransaction(payload);

      if (insertedId != null && _imagePath != null) {
        final tier = ref.read(userProfileProvider).value?.tier;
        final canStore = FeatureFlags.forTier(tier ?? 'free').receiptStorage;
        InteractionLog.info(
          action: 'receipt_upload_check',
          screen: 'transaction_form',
          message: 'tier=$tier canStore=$canStore path=$_imagePath',
          metadata: {'txn_id': insertedId, 'tier': tier},
        );
        if (canStore) {
          try {
            final bytes = await File(_imagePath!).readAsBytes();
            final user = ref.read(currentUserProvider);
            if (user != null) {
              final path = await ref
                  .read(receiptServiceProvider)
                  .uploadReceipt(
                    userId: user.id,
                    transactionId: insertedId,
                    imageBytes: bytes,
                  );
              InteractionLog.success(
                action: 'receipt_upload',
                screen: 'transaction_form',
                message: 'uploaded $path',
                metadata: {'txn_id': insertedId},
              );
            }
          } catch (e) {
            InteractionLog.error(
              action: 'receipt_upload',
              screen: 'transaction_form',
              message: '$e',
              metadata: {'txn_id': insertedId},
            );
          }
        }
      }

      if (_roomId != null) {
        unawaited(
          ref
              .read(roomServiceProvider)
              .notifyRoomTransaction(
                roomId: _roomId!,
                merchant: _merchant.text.trim().isEmpty
                    ? null
                    : _merchant.text.trim(),
                amount: amount,
                currency: _currency,
              )
              .catchError((Object e, StackTrace _) {
                InteractionLog.error(
                  action: 'room_notify',
                  screen: 'transaction_form',
                  message: '$e',
                  metadata: {'room_id': _roomId},
                );
              }),
        );
      }

      final method = _aiParsed
          ? 'scan'
          : _isManualFallback
              ? 'manual_fallback'
              : 'manual';

      if (_aiParsed) {
        await Analytics.scanCompleted(aiSuccess: true);
        await Analytics.transactionAdded(method: 'scan', category: _category);
      } else if (_isManualFallback) {
        await Analytics.scanCompleted(aiSuccess: false);
        await Analytics.transactionAdded(
          method: 'manual_fallback',
          category: _category,
        );
      } else {
        await Analytics.transactionAdded(method: 'manual', category: _category);
      }

      InteractionLog.success(
        action: 'transaction_added',
        screen: 'transaction_form',
        message: '$method / $_category',
        metadata: {
          'method': method,
          'category': _category,
          'amount': amount,
          'currency': _currency,
        },
      );

      if (mounted) context.pop();
    } catch (e) {
      InteractionLog.error(
        action: 'transaction_save',
        screen: 'transaction_form',
        message: '$e',
        metadata: {'category': _category, 'currency': _currency},
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    final home = profile?.homeCurrency ?? 'IDR';
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isManualFallback
              ? 'Manual entry'
              : (_aiParsed ? 'Confirm transaction' : 'New transaction'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isManualFallback)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "We couldn't read this receipt — fields below were pre-filled "
                  'with what we could recover. Please review and complete.',
                ),
              ),
            if (_aiParsed)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'We parsed this receipt. Please review before saving.',
                ),
              ),
            TextFormField(
              controller: _merchant,
              decoration: const InputDecoration(
                labelText: 'Merchant',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _amount,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final parsed = double.tryParse(v);
                      if (parsed == null || parsed <= 0) return 'Invalid';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final c in kCommonCurrencies)
                        DropdownMenuItem(value: c, child: Text(c)),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _currency = v);
                      _recomputeFx();
                    },
                  ),
                ),
              ],
            ),
            if (_fx?.isStale == true) ...[
              const SizedBox(height: 8),
              const StaleRateBanner(),
            ],
            if (_fx != null && _currency != home)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  '1 $_currency ≈ ${_fx!.rate.toStringAsFixed(4)} $home',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final c in Categories.all)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) => setState(() => _category = v ?? 'other'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_items != null && _items!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Line items', style: Theme.of(context).textTheme.titleSmall),
              for (final it in _items!)
                ListTile(
                  dense: true,
                  title: Text((it['name'] as String?) ?? 'Item'),
                  trailing: Text(
                    '${it['qty'] ?? 1} × ${it['unit_price'] ?? it['total_price'] ?? ''}',
                  ),
                ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
