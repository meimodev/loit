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
import '../../core/theme/loit_categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/services_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/category_picker_sheet.dart';
import '../../shared/widgets/loit_banner.dart';
import '../../shared/widgets/loit_category_avatar.dart';
import '../../shared/widgets/loit_input.dart';
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
  bool _isIncome = false;
  bool _busy = false;
  bool _isManualFallback = false;
  bool _aiParsed = false;
  String? _amountError;
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
      // Detect income flag from prefill (scanner output) or signed amount.
      final rawType = p['type'] as String?;
      final total = p['total'] ?? p['amount'];
      if (total != null) {
        final n = (total is num) ? total.toDouble() : double.tryParse('$total');
        if (n != null) {
          if (n < 0) _isIncome = true;
          _amount.text = n.abs().toString();
        }
      }
      if (rawType == 'income') _isIncome = true;
      _currency = (p['currency'] as String?) ?? 'IDR';
      final cat = p['category'] as String?;
      if (cat != null) {
        if (Categories.isIncomeKey(cat)) {
          _isIncome = true;
          _category = cat;
        } else if (Categories.expense.contains(cat)) {
          _category = cat;
        }
      }
      if (_isIncome && !Categories.isIncomeKey(_category)) {
        _category = 'income_other';
      }
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

  bool _validate() {
    final amt = double.tryParse(_amount.text.trim());
    setState(() {
      _amountError = (amt == null || amt <= 0) ? 'Enter a valid amount' : null;
    });
    return _amountError == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _busy = true);
    try {
      final absAmount = double.parse(_amount.text.trim());
      final amount = _isIncome ? -absAmount : absAmount;
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
                isIncome: _isIncome,
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

  Future<void> _pickCategory() async {
    final picked = await pickLoitCategory(
      context,
      selectedKey: _category,
      isIncome: _isIncome,
    );
    if (picked != null) setState(() => _category = picked);
  }

  void _toggleSign() {
    setState(() {
      _isIncome = !_isIncome;
      _category = _isIncome ? 'income_other' : 'other';
    });
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
                    ? Icon(Icons.check_rounded, color: context.loitColors.brand)
                    : null,
                onTap: () => Navigator.pop(context, c),
              ),
          ],
        ),
      ),
    );
    if (picked != null && picked != _currency) {
      setState(() => _currency = picked);
      _recomputeFx();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final profile = ref.watch(userProfileProvider).value;
    final home = profile?.homeCurrency ?? 'IDR';
    final catStyle = LoitCategories.resolve(_category);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(
          _isManualFallback
              ? 'Manual entry'
              : (_aiParsed
                  ? 'Confirm'
                  : (_isIncome ? 'New income' : 'New expense')),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(LoitSpacing.s5),
          children: [
            if (_isManualFallback)
              Padding(
                padding: const EdgeInsets.only(bottom: LoitSpacing.s4),
                child: LoitBanner(
                  kind: LoitBannerKind.warning,
                  title: "Couldn't read this receipt",
                  body: 'Fields below were pre-filled with what we recovered.',
                ),
              ),
            if (_aiParsed)
              Padding(
                padding: const EdgeInsets.only(bottom: LoitSpacing.s4),
                child: LoitBanner(
                  kind: LoitBannerKind.info,
                  title: 'AI parsed this receipt',
                  body: 'Please review before saving.',
                ),
              ),
            LoitInput(
              controller: _merchant,
              label: 'Merchant',
              placeholder: 'e.g. Starbucks',
            ),
            const SizedBox(height: LoitSpacing.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: _SignToggle(isIncome: _isIncome, onTap: _toggleSign),
                ),
                const SizedBox(width: LoitSpacing.s3),
                Expanded(
                  flex: 2,
                  child: LoitInput(
                    controller: _amount,
                    label: _isIncome ? 'Amount (income)' : 'Amount',
                    placeholder: '0',
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    error: _amountError,
                  ),
                ),
                const SizedBox(width: LoitSpacing.s4),
                Expanded(
                  child: _picker(
                    label: 'Currency',
                    valueWidget: Text(_currency,
                        style: LoitTypography.bodyL
                            .copyWith(color: c.contentPrimary)),
                    onTap: _pickCurrency,
                  ),
                ),
              ],
            ),
            if (_fx?.isStale == true) ...[
              const SizedBox(height: LoitSpacing.s3),
              const StaleRateBanner(),
            ],
            if (_fx != null && _currency != home)
              Padding(
                padding: const EdgeInsets.only(top: LoitSpacing.s3),
                child: Text(
                  '1 $_currency ≈ ${_fx!.rate.toStringAsFixed(4)} $home',
                  style: LoitTypography.bodyS.copyWith(color: c.contentTertiary),
                ),
              ),
            const SizedBox(height: LoitSpacing.s4),
            _picker(
              label: 'Category',
              valueWidget: Row(
                children: [
                  LoitCategoryAvatar(categoryKey: _category, size: 28),
                  const SizedBox(width: LoitSpacing.s3),
                  Text(catStyle.label,
                      style: LoitTypography.bodyL
                          .copyWith(color: c.contentPrimary)),
                ],
              ),
              onTap: _pickCategory,
            ),
            const SizedBox(height: LoitSpacing.s4),
            LoitInput(
              controller: _notes,
              label: 'Notes',
              placeholder: 'Optional',
              maxLines: 3,
            ),
            if (_items != null && _items!.isNotEmpty) ...[
              const SizedBox(height: LoitSpacing.s5),
              Text('Line items',
                  style: LoitTypography.labelM
                      .copyWith(color: c.contentSecondary)),
              const SizedBox(height: LoitSpacing.s3),
              Container(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: LoitRadius.brM,
                  border: Border.all(color: c.borderSubtle),
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < _items!.length; i++) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: LoitSpacing.s3,
                          horizontal: LoitSpacing.s4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                (_items![i]['name'] as String?) ?? 'Item',
                                style: LoitTypography.bodyM
                                    .copyWith(color: c.contentPrimary),
                              ),
                            ),
                            Text(
                              '${_items![i]['qty'] ?? 1} × ${_items![i]['unit_price'] ?? _items![i]['total_price'] ?? ''}',
                              style: LoitTypography.bodyS
                                  .copyWith(color: c.contentSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (i != _items!.length - 1)
                        Divider(
                            height: 1,
                            color: c.borderSubtle,
                            indent: LoitSpacing.s4,
                            endIndent: LoitSpacing.s4),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: LoitSpacing.s7),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
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

  Widget _picker({
    required String label,
    required Widget valueWidget,
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
                Expanded(child: valueWidget),
                Icon(Icons.expand_more, color: c.contentSecondary, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Pill button next to the amount input. Tapping flips between expense (`+`)
/// and income (`−`). Persists as the sign on the saved `amount`.
class _SignToggle extends StatelessWidget {
  const _SignToggle({required this.isIncome, required this.onTap});

  final bool isIncome;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final tint = isIncome
        ? const Color(0xFF2F8F5E)
        : c.contentPrimary;
    return Semantics(
      button: true,
      label: isIncome ? 'Switch to expense' : 'Switch to income',
      child: InkWell(
        onTap: onTap,
        borderRadius: LoitRadius.brM,
        child: Container(
          height: 44,
          width: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isIncome ? tint.withValues(alpha: 0.12) : c.surface,
            borderRadius: LoitRadius.brM,
            border: Border.all(color: isIncome ? tint : c.borderDefault),
          ),
          child: Text(
            isIncome ? '−' : '+',
            style: LoitTypography.bodyL.copyWith(
              color: tint,
              fontWeight: FontWeight.w700,
              fontSize: 22,
            ),
          ),
        ),
      ),
    );
  }
}
