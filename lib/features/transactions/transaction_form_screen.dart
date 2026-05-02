import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/config/categories.dart';
import '../../core/services/analytics_service.dart';
import '../../core/services/currency_service.dart';
import '../../core/services/interaction_log_service.dart';
import '../../core/theme/loit_categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/services_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/account_picker_sheet.dart';
import '../../shared/widgets/category_picker_sheet.dart';
import '../../shared/widgets/loit_banner.dart';
import '../../shared/widgets/loit_category_avatar.dart';
import '../../shared/widgets/loit_input.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/stale_rate_banner.dart';
import '../paywall/feature_gate.dart';
import 'notes_breakdown.dart';

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
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  late String _currency;
  String _category = 'other';
  String _type = 'expense'; // 'expense' | 'income' | 'transfer'
  String? _accountId;
  String? _toAccountId;
  String? _editId; // non-null when editing an existing transaction
  bool _busy = false;
  bool _isManualFallback = false;
  bool _aiParsed = false;
  String? _amountError;
  FxRate? _fx;
  String? _roomId;
  String? _imagePath;
  DateTime _date = DateTime.now();
  late ProviderSubscription<List<Account>> _accountsSub;

  // Notes breakdown editor state.
  _NotesMode _notesMode = _NotesMode.text;
  final _merchant = TextEditingController();
  final _totalC = TextEditingController();
  final List<_ItemRowControllers> _itemRows = [];
  bool _breakdownHintDismissed = false;

  @override
  void initState() {
    super.initState();
    _currency = 'IDR';
    final p = widget.prefill;
    if (p != null) {
      // Detect type from prefill (scanner output) or signed amount.
      final rawType = p['type'] as String?;
      final total = p['total'] ?? p['amount'];
      if (total != null) {
        final n = (total is num) ? total.toDouble() : double.tryParse('$total');
        if (n != null) {
          if (n < 0) _type = 'income';
          _amount.text = formatAmountInput(n.abs());
        }
      }
      if (rawType == 'income') _type = 'income';
      if (rawType == 'transfer') _type = 'transfer';
      _currency = (p['currency'] as String?) ?? 'IDR';
      final cat = p['category'] as String?;
      if (cat != null) {
        if (Categories.isIncomeKey(cat)) {
          _type = 'income';
          _category = cat;
        } else if (Categories.expense.contains(cat)) {
          _category = cat;
        }
      }
      if (_type == 'income' && !Categories.isIncomeKey(_category)) {
        _category = 'income_other';
      }
      _editId = p['_edit_id'] as String?;
      _accountId = p['account_id'] as String?;
      _toAccountId = p['to_account_id'] as String?;
      _roomId = p['_room_id'] as String?;
      _isManualFallback = (p['_manual_fallback'] as bool?) ?? false;
      _aiParsed = (p['_ai_parsed'] as bool?) ?? false;
      _imagePath = p['_image_path'] as String?;
      final rawDate = p['created_at'];
      if (rawDate is String) {
        final parsed = DateTime.tryParse(rawDate);
        if (parsed != null) _date = parsed.toLocal();
      } else if (rawDate is DateTime) {
        _date = rawDate.toLocal();
      }
      final merchantPrefill = (p['merchant'] as String?)?.trim();
      final notesPrefill = (p['notes'] as String?)?.trim();
      final rawItems = p['items'];
      final hasScanItems = rawItems is List && rawItems.isNotEmpty;
      if (hasScanItems) {
        _notesMode = _NotesMode.items;
        _merchant.text = merchantPrefill ?? '';
        for (final raw in rawItems) {
          if (raw is! Map) continue;
          final m = Map<String, dynamic>.from(raw);
          final name = (m['name'] as String?)?.trim() ?? '';
          double? toD(Object? v) {
            if (v is num) return v.toDouble();
            if (v is String) return double.tryParse(v);
            return null;
          }
          _itemRows.add(_ItemRowControllers(
            name: name,
            qty: toD(m['qty']),
            unit: toD(m['unit_price']),
            total: toD(m['total_price']),
          ));
        }
        // Seed canonical text so saving without further edits writes structured notes.
        _notes.text = formatBreakdown(_collectBreakdown());
      } else {
        final composed = [
          if (merchantPrefill != null && merchantPrefill.isNotEmpty)
            merchantPrefill,
          if (notesPrefill != null && notesPrefill.isNotEmpty) notesPrefill,
        ].join('\n');
        if (composed.isNotEmpty) _notes.text = composed;
        // Existing edited transaction: auto-detect breakdown so editor opens
        // in items mode when notes follow the canonical format.
        final editId = p['_edit_id'] as String?;
        if (editId != null) {
          final parsed = parseBreakdown(_notes.text);
          if (parsed != null) {
            _notesMode = _NotesMode.items;
            _merchant.text = parsed.merchant;
            for (final it in parsed.items) {
              _itemRows.add(_ItemRowControllers(
                name: it.name,
                qty: it.qty,
                unit: it.unitPrice,
                total: it.totalPrice,
              ));
            }
            if (parsed.total != null) {
              _totalC.text =
                  NumberFormat('#,##0.##', 'id_ID').format(parsed.total!);
            }
          }
        }
      }
    }
    _notes.addListener(_onNotesTextChanged);

    // Auto-select first active account once accounts load; fires immediately if
    // already cached. Avoids post-frame mutation in build().
    _accountsSub = ref.listenManual<List<Account>>(
      activeAccountsProvider,
      (prev, next) {
        if (mounted && _accountId == null && next.isNotEmpty) {
          setState(() => _accountId = next.first.id);
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _accountsSub.close();
    _amount.dispose();
    _notes.removeListener(_onNotesTextChanged);
    _notes.dispose();
    _merchant.dispose();
    _totalC.dispose();
    for (final r in _itemRows) {
      r.dispose();
    }
    super.dispose();
  }

  void _onNotesTextChanged() {
    if (_notesMode != _NotesMode.text) return;
    setState(() {});
  }

  NotesBreakdown _collectBreakdown() {
    final items = <NotesBreakdownItem>[];
    for (final r in _itemRows) {
      final name = r.nameC.text.trim();
      final qty = parseAmountInput(r.qtyC.text);
      final unit = parseAmountInput(r.unitC.text);
      final total = parseAmountInput(r.totalC.text);
      if (name.isEmpty && qty == null && unit == null && total == null) {
        continue;
      }
      items.add(NotesBreakdownItem(
        name: name,
        qty: qty,
        unitPrice: unit,
        totalPrice: total,
      ));
    }
    return NotesBreakdown(
      merchant: _merchant.text.trim(),
      items: items,
      total: parseAmountInput(_totalC.text),
    );
  }

  void _setNotesMode(_NotesMode next) {
    if (next == _notesMode) return;
    if (next == _NotesMode.items) {
      // Try parse current notes text into editor.
      final parsed = parseBreakdown(_notes.text);
      if (parsed != null) {
        for (final r in _itemRows) {
          r.dispose();
        }
        _itemRows.clear();
        _merchant.text = parsed.merchant;
        for (final it in parsed.items) {
          _itemRows.add(_ItemRowControllers(
            name: it.name,
            qty: it.qty,
            unit: it.unitPrice,
            total: it.totalPrice,
          ));
        }
        _totalC.text = parsed.total != null
            ? NumberFormat('#,##0.##', 'id_ID').format(parsed.total!)
            : '';
      } else {
        if (_notes.text.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Existing notes not recognized — start a fresh breakdown.'),
            ),
          );
        }
      }
      setState(() {
        _notesMode = next;
      });
    } else {
      // Items → Text: serialize.
      _notes.text = formatBreakdown(_collectBreakdown());
      setState(() {
        _notesMode = next;
      });
    }
  }

  bool _amountMismatch() {
    final total = parseAmountInput(_totalC.text);
    if (total == null) return false;
    final amt = parseAmountInput(_amount.text);
    if (amt == null || amt <= 0) return false;
    return (total - amt).abs() > 0.005;
  }

  Widget _buildItemsEditor(LoitColors c) {
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
          LoitInput(
            controller: _merchant,
            label: 'Merchant',
            placeholder: 'Store or payer',
            size: LoitInputSize.s,
          ),
          const SizedBox(height: LoitSpacing.s3),
          for (var i = 0; i < _itemRows.length; i++) ...[
            _itemRow(c, i),
            const SizedBox(height: LoitSpacing.s2),
          ],
          OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add item'),
            onPressed: () {
              setState(() {
                _itemRows.add(_ItemRowControllers());
              });
            },
          ),
          const SizedBox(height: LoitSpacing.s3),
          LoitInput(
            controller: _totalC,
            label: 'Total',
            placeholder: 'Optional',
            size: LoitInputSize.s,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ThousandsInputFormatter(),
            ],
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _itemRow(LoitColors c, int i) {
    final r = _itemRows[i];
    return Container(
      padding: const EdgeInsets.all(LoitSpacing.s3),
      decoration: BoxDecoration(
        color: c.canvas,
        borderRadius: LoitRadius.brS,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: LoitInput(
                  controller: r.nameC,
                  placeholder: 'Item name',
                  size: LoitInputSize.s,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Remove',
                icon: Icon(Icons.delete_outline,
                    size: 18, color: c.contentTertiary),
                onPressed: () {
                  setState(() {
                    final removed = _itemRows.removeAt(i);
                    removed.dispose();
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: LoitSpacing.s2),
          Row(
            children: [
              Expanded(
                child: LoitInput(
                  controller: r.qtyC,
                  placeholder: 'Qty',
                  size: LoitInputSize.s,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ThousandsInputFormatter(),
                  ],
                ),
              ),
              const SizedBox(width: LoitSpacing.s2),
              Expanded(
                child: LoitInput(
                  controller: r.unitC,
                  placeholder: 'Unit price',
                  size: LoitInputSize.s,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ThousandsInputFormatter(),
                  ],
                ),
              ),
              const SizedBox(width: LoitSpacing.s2),
              Expanded(
                child: LoitInput(
                  controller: r.totalC,
                  placeholder: 'Total',
                  size: LoitInputSize.s,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ThousandsInputFormatter(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
    final amt = parseAmountInput(_amount.text);
    String? amtErr = (amt == null || amt <= 0) ? 'Enter a valid amount' : null;
    setState(() {
      _amountError = amtErr;
    });
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select an account')),
      );
      return false;
    }
    if (_type == 'transfer' && _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a destination account')),
      );
      return false;
    }
    return amtErr == null;
  }

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _busy = true);
    try {
      final absAmount = parseAmountInput(_amount.text) ?? 0;
      // Sign convention: income > 0, expense < 0, transfer > 0 (direction
      // captured by from/to account ids).
      final amount = _type == 'expense' ? -absAmount : absAmount;
      final rate = _fx?.rate ?? 1.0;
      final String? notesPayload;
      if (_notesMode == _NotesMode.items) {
        final formatted = formatBreakdown(_collectBreakdown()).trim();
        notesPayload = formatted.isEmpty ? null : formatted;
      } else {
        final t = _notes.text.trim();
        notesPayload = t.isEmpty ? null : t;
      }
      final payload = <String, dynamic>{
        'amount': amount,
        'currency': _currency,
        'amount_home_currency': amount * rate,
        'fx_rate': rate,
        'type': _type,
        'account_id': _accountId,
        if (_type == 'transfer') 'to_account_id': _toAccountId,
        'category': _type == 'transfer' ? null : _category,
        'notes': notesPayload,
        'ai_parsed': _aiParsed,
        'is_manual_fallback': _isManualFallback,
        'created_at': _date.toUtc().toIso8601String(),
        if (_roomId != null) 'room_id': _roomId,
      };
      final String? insertedId;
      if (_editId != null) {
        await ref
            .read(transactionsProvider.notifier)
            .updateTransaction(_editId!, payload);
        insertedId = null;
      } else {
        insertedId = await ref
            .read(transactionsProvider.notifier)
            .addTransaction(payload);
      }

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

      if (_roomId != null && _type != 'transfer') {
        unawaited(
          ref
              .read(roomServiceProvider)
              .notifyRoomTransaction(
                roomId: _roomId!,
                title: (notesPayload == null || notesPayload.isEmpty)
                    ? null
                    : breakdownTitle(notesPayload),
                amount: amount,
                currency: _currency,
                isIncome: _type == 'income',
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
      isIncome: _type == 'income',
    );
    if (picked != null) setState(() => _category = picked);
  }

  void _setType(String type) {
    setState(() {
      _type = type;
      if (type == 'income' && !Categories.isIncomeKey(_category)) {
        _category = 'income_other';
      } else if (type == 'expense' && Categories.isIncomeKey(_category)) {
        _category = 'other';
      }
      if (type == 'transfer') _toAccountId = null;
    });
  }

  Future<void> _pickAccount() async {
    final picked = await pickLoitAccount(
      context,
      selectedId: _accountId,
    );
    if (picked != null) setState(() => _accountId = picked);
  }

  Future<void> _pickToAccount() async {
    final picked = await pickLoitAccount(
      context,
      selectedId: _toAccountId,
      excludeId: _accountId,
    );
    if (picked != null) setState(() => _toAccountId = picked);
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

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day,
            _date.hour, _date.minute);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(_date.year, _date.month, _date.day,
            picked.hour, picked.minute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final profile = ref.watch(userProfileProvider).value;
    final home = profile?.homeCurrency ?? 'IDR';
    final catStyle = LoitCategories.resolve(_category);

    final activeAccounts = ref.watch(activeAccountsProvider);

    // Null-safe account lookup: clear stale id if not found in current list.
    Account? findAccount(String? id) {
      if (id == null) return null;
      for (final a in activeAccounts) {
        if (a.id == id) return a;
      }
      return null;
    }

    final fromAccount = findAccount(_accountId);
    if (fromAccount == null && _accountId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _accountId = null);
      });
    }
    final accountName = fromAccount?.name;

    final toAccount = findAccount(_toAccountId);
    if (toAccount == null && _toAccountId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _toAccountId = null);
      });
    }
    final toAccountName = toAccount?.name;

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(
          _editId != null
              ? 'Edit transaction'
              : _isManualFallback
                  ? 'Manual entry'
                  : (_aiParsed ? 'Confirm' : 'New transaction'),
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
            _TypeSegmented(type: _type, onChanged: _setType),
            const SizedBox(height: LoitSpacing.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: LoitInput(
                    controller: _amount,
                    label: 'Amount',
                    placeholder: '0',
                    leading: _type == 'expense'
                        ? Text('−',
                            style: LoitTypography.bodyL
                                .copyWith(color: c.danger))
                        : null,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ThousandsInputFormatter(),
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
            if (activeAccounts.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: LoitSpacing.s4),
                child: Container(
                  padding: const EdgeInsets.all(LoitSpacing.s4),
                  decoration: BoxDecoration(
                    color: c.dangerSurface,
                    borderRadius: LoitRadius.brM,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: c.danger, size: 18),
                      const SizedBox(width: LoitSpacing.s3),
                      Expanded(
                        child: Text(
                          'Add an account first before saving a transaction.',
                          style: LoitTypography.bodyS.copyWith(color: c.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            _picker(
              label: _type == 'transfer' ? 'From account' : 'Account',
              valueWidget: Text(
                accountName ?? 'Select account',
                style: LoitTypography.bodyL.copyWith(
                  color: accountName != null ? c.contentPrimary : c.contentTertiary,
                ),
              ),
              onTap: _pickAccount,
            ),
            if (_type == 'transfer') ...[
              const SizedBox(height: LoitSpacing.s4),
              _picker(
                label: 'To account',
                valueWidget: Text(
                  toAccountName ?? 'Select destination',
                  style: LoitTypography.bodyL.copyWith(
                    color: toAccountName != null ? c.contentPrimary : c.contentTertiary,
                  ),
                ),
                onTap: _pickToAccount,
              ),
            ],
            if (_type != 'transfer') ...[
              const SizedBox(height: LoitSpacing.s4),
              _picker(
                label: _type == 'income' ? 'Income category' : 'Expense category',
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
            ],
            const SizedBox(height: LoitSpacing.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _picker(
                    label: 'Date',
                    valueWidget: Text(
                      DateFormat.yMMMd().format(_date),
                      style: LoitTypography.bodyL
                          .copyWith(color: c.contentPrimary),
                    ),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: LoitSpacing.s4),
                Expanded(
                  child: _picker(
                    label: 'Time',
                    valueWidget: Text(
                      DateFormat.Hm().format(_date),
                      style: LoitTypography.bodyL
                          .copyWith(color: c.contentPrimary),
                    ),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LoitSpacing.s4),
            Text('Notes',
                style: LoitTypography.bodyM.copyWith(
                  color: c.contentPrimary,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            _NotesModeToggle(
              mode: _notesMode,
              onChanged: _setNotesMode,
            ),
            const SizedBox(height: LoitSpacing.s3),
            if (_notesMode == _NotesMode.text) ...[
              LoitInput(
                controller: _notes,
                placeholder: 'Optional',
                maxLines: 5,
              ),
              if (!_breakdownHintDismissed && looksLikeBreakdown(_notes.text)) ...[
                const SizedBox(height: LoitSpacing.s3),
                LoitBanner(
                  kind: LoitBannerKind.info,
                  title: 'Looks like an item breakdown',
                  body: 'Switch to Items mode for a structured list.',
                  actionLabel: 'Switch to Items',
                  onAction: () => _setNotesMode(_NotesMode.items),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _breakdownHintDismissed = true),
                    child: const Text('Dismiss'),
                  ),
                ),
              ],
            ] else ...[
              _buildItemsEditor(c),
              if (_amountMismatch()) ...[
                const SizedBox(height: LoitSpacing.s3),
                LoitBanner(
                  kind: LoitBannerKind.info,
                  title: 'Total and amount differ',
                  body:
                      "The breakdown total doesn't match the transaction amount.",
                ),
              ],
            ],
            const SizedBox(height: LoitSpacing.s7),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              onPressed: (_busy || activeAccounts.isEmpty) ? null : _save,
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

class _TypeSegmented extends StatelessWidget {
  const _TypeSegmented({required this.type, required this.onChanged});

  final String type;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    const options = [
      ('expense', 'Expense'),
      ('income', 'Income'),
      ('transfer', 'Transfer'),
    ];
    return Row(
      children: [
        for (var i = 0; i < options.length; i++) ...[
          Expanded(
            child: _Segment(
              label: options[i].$2,
              selected: type == options[i].$1,
              color: options[i].$1 == 'income'
                  ? const Color(0xFF2F8F5E)
                  : options[i].$1 == 'expense'
                      ? c.danger
                      : c.info,
              onTap: () => onChanged(options[i].$1),
              isFirst: i == 0,
              isLast: i == options.length - 1,
            ),
          ),
        ],
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    required this.isFirst,
    required this.isLast,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final radius = BorderRadius.horizontal(
      left: isFirst ? const Radius.circular(8) : Radius.zero,
      right: isLast ? const Radius.circular(8) : Radius.zero,
    );
    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : c.surface,
          borderRadius: radius,
          border: Border.all(
            color: selected ? color : c.borderDefault,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: LoitTypography.bodyS.copyWith(
            color: selected ? color : c.contentSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notes breakdown editor support
// ---------------------------------------------------------------------------

enum _NotesMode { text, items }

class _ItemRowControllers {
  _ItemRowControllers({
    String? name,
    double? qty,
    double? unit,
    double? total,
  })  : nameC = TextEditingController(text: name ?? ''),
        qtyC = TextEditingController(
            text: qty != null ? formatAmountInput(qty) : ''),
        unitC = TextEditingController(
            text: unit != null ? formatAmountInput(unit) : ''),
        totalC = TextEditingController(
            text: total != null ? formatAmountInput(total) : '');

  final TextEditingController nameC;
  final TextEditingController qtyC;
  final TextEditingController unitC;
  final TextEditingController totalC;

  void dispose() {
    nameC.dispose();
    qtyC.dispose();
    unitC.dispose();
    totalC.dispose();
  }
}

class _NotesModeToggle extends StatelessWidget {
  const _NotesModeToggle({required this.mode, required this.onChanged});

  final _NotesMode mode;
  final ValueChanged<_NotesMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    Widget seg(String label, _NotesMode value, bool first, bool last) {
      final selected = value == mode;
      final radius = BorderRadius.horizontal(
        left: first ? const Radius.circular(8) : Radius.zero,
        right: last ? const Radius.circular(8) : Radius.zero,
      );
      return Expanded(
        child: InkWell(
          onTap: () => onChanged(value),
          borderRadius: radius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? c.brand.withValues(alpha: 0.10)
                  : c.surface,
              borderRadius: radius,
              border: Border.all(
                color: selected ? c.brand : c.borderDefault,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: LoitTypography.bodyS.copyWith(
                color: selected ? c.brand : c.contentSecondary,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }

    return Row(children: [
      seg('Text', _NotesMode.text, true, false),
      seg('Items', _NotesMode.items, false, true),
    ]);
  }
}
