import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/currency_service.dart';
import '../../shared/providers/supported_currencies_provider.dart';
import '../../core/services/interaction_log_service.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/services_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/widgets/account_picker_sheet.dart';
import '../../shared/widgets/category_picker_sheet.dart';
import '../../shared/widgets/currency_picker_sheet.dart';
import '../../shared/widgets/loit_banner.dart';
import '../../shared/widgets/loit_category_avatar.dart';
import '../../shared/widgets/loit_input.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/utils/locale_date_format.dart';
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

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen>
    with SingleTickerProviderStateMixin {
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
  Map<String, double>? _usdBaseRates;
  bool _ratesStale = false;
  String? _roomId;
  String? _imagePath;
  DateTime _date = DateTime.now();
  late ProviderSubscription<List<Account>> _accountsSub;

  // Notes breakdown editor state.
  _NotesMode _notesMode = _NotesMode.text;
  final _merchant = TextEditingController();
  final List<_ItemRowControllers> _itemRows = [];
  late final TabController _notesTabController;
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
        _category = cat;
      }
      _editId = p['_edit_id'] as String?;
      _accountId = p['account_id'] as String?;
      _toAccountId = p['to_account_id'] as String?;
      _roomId = p['_room_id'] as String?;
      _isManualFallback = (p['_manual_fallback'] as bool?) ?? false;
      _aiParsed = (p['_ai_parsed'] as bool?) ?? false;
      _imagePath = p['_image_path'] as String?;
      // Scan AI returns separate date (YYYY-MM-DD) and time (HH:MM) fields.
      final scanDate = p['date'] as String?;
      final scanTime = p['time'] as String?;
      if (scanDate != null) {
        final d = DateTime.tryParse(scanDate);
        if (d != null) {
          var h = 0, m = 0;
          if (scanTime != null) {
            final parts = scanTime.split(':');
            h = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 0;
            m = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0;
          }
          _date = DateTime(d.year, d.month, d.day, h, m);
        }
      }
      // Edit mode passes created_at as a full ISO timestamp — takes precedence.
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
          _addRow(_ItemRowControllers(
            name: name,
            qty: toD(m['qty']),
            unit: toD(m['unit_price']),
            total: toD(m['total_price']),
          ));
        }
        // Infer missing unit_price ↔ total_price ↔ qty for each row.
        for (final r in _itemRows) {
          _recalcRow(r);
        }
        if (_amount.text.isEmpty) {
          var sum = 0.0;
          for (final r in _itemRows) {
            final t = parseAmountInput(r.totalC.text);
            if (t != null) sum += t;
          }
          if (sum > 0) _amount.text = formatAmountInput(sum);
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

        if (_isManualFallback || _aiParsed) {
          // Scan-origin form with no parsed items: open Items tab so user
          // can add items manually. Merchant belongs in the items editor header.
          _notesMode = _NotesMode.items;
          _merchant.text = merchantPrefill ?? '';
        } else {
          // Existing edited transaction: auto-detect breakdown so editor opens
          // in items mode when notes follow the canonical format.
          final editId = p['_edit_id'] as String?;
          if (editId != null) {
            final parsed = parseBreakdown(_notes.text);
            if (parsed != null) {
              _notesMode = _NotesMode.items;
              _merchant.text = parsed.merchant;
              for (final it in parsed.items) {
                _addRow(_ItemRowControllers(
                  name: it.name,
                  qty: it.qty,
                  unit: it.unitPrice,
                  total: it.totalPrice,
                ));
              }
            }
          }
        }
      }
    }
    _notes.addListener(_onNotesTextChanged);
    _notesTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: _notesMode == _NotesMode.items ? 1 : 0,
    );
    _notesTabController.addListener(_onNotesTabChanged);

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
    _notesTabController.dispose();
    for (final r in _itemRows) {
      r.dispose();
    }
    super.dispose();
  }

  void _onNotesTextChanged() {
    if (_notesMode != _NotesMode.text) return;
    setState(() {});
  }

  void _onNotesTabChanged() {
    if (!_notesTabController.indexIsChanging) return;
    final mode = _notesTabController.index == 0
        ? _NotesMode.text
        : _NotesMode.items;
    if (mode != _notesMode) {
      _setNotesMode(mode);
    }
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
      total: null,
    );
  }

  void _setNotesMode(_NotesMode next) {
    if (next == _notesMode) return;
    final targetIndex = next == _NotesMode.text ? 0 : 1;
    if (_notesTabController.index != targetIndex) {
      _notesTabController.index = targetIndex;
    }
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
          _addRow(_ItemRowControllers(
            name: it.name,
            qty: it.qty,
            unit: it.unitPrice,
            total: it.totalPrice,
          ));
        }
      } else {
        if (_notes.text.trim().isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.txFormExistingNotes),
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
            label: context.l10n.txFormMerchant,
            placeholder: context.l10n.txFormStoreOrPayer,
            size: LoitInputSize.s,
          ),
          const SizedBox(height: LoitSpacing.s3),
          for (var i = 0; i < _itemRows.length; i++) ...[
            _itemRow(c, i),
            const SizedBox(height: LoitSpacing.s2),
          ],
          OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: Text(context.l10n.txFormAddItem),
            onPressed: () {
              setState(() {
                _addRow(_ItemRowControllers());
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _itemRow(LoitColors c, int i) {
    final r = _itemRows[i];
    final symbol = _currencySymbol;
    Widget priceLeading() => Text(
          symbol,
          style: LoitTypography.bodyS.copyWith(color: c.contentSecondary),
        );
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
                  placeholder: context.l10n.txFormItemName,
                  size: LoitInputSize.s,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: context.l10n.txFormRemove,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: LoitInput(
                  controller: r.qtyC,
                  placeholder: context.l10n.txFormQty,
                  size: LoitInputSize.s,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ThousandsInputFormatter(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: LoitSpacing.s2),
                child: Text(
                  '×',
                  style: LoitTypography.bodyM
                      .copyWith(color: c.contentTertiary),
                ),
              ),
              Expanded(
                child: LoitInput(
                  controller: r.unitC,
                  placeholder: context.l10n.txFormUnitPrice,
                  size: LoitInputSize.s,
                  leading: priceLeading(),
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
                  placeholder: context.l10n.txFormTotal,
                  size: LoitInputSize.s,
                  leading: priceLeading(),
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

  void _addRow(_ItemRowControllers r) {
    _itemRows.add(r);
    _attachItemListeners(r);
  }

  void _attachItemListeners(_ItemRowControllers r) {
    void listener() => _recalcRow(r);
    r.qtyC.addListener(listener);
    r.unitC.addListener(listener);
    r.totalC.addListener(listener);
  }

  /// Fills any single missing value among qty / unit / total when the other
  /// two are present. `<= 0` is treated as missing. Re-entrancy guarded.
  void _recalcRow(_ItemRowControllers r) {
    if (r._suppress) return;
    final qty = parseAmountInput(r.qtyC.text);
    final unit = parseAmountInput(r.unitC.text);
    final total = parseAmountInput(r.totalC.text);
    final hasQty = qty != null && qty > 0;
    final hasUnit = unit != null && unit > 0;
    final hasTotal = total != null && total > 0;
    void set(TextEditingController c, double v) {
      final txt = formatAmountInput(v);
      if (c.text == txt) return;
      c.value = TextEditingValue(
        text: txt,
        selection: TextSelection.collapsed(offset: txt.length),
      );
    }
    r._suppress = true;
    try {
      if (!hasTotal && hasQty && hasUnit) {
        set(r.totalC, qty * unit);
      } else if (!hasUnit && hasTotal && hasQty) {
        set(r.unitC, total / qty);
      } else if (!hasQty && hasTotal && hasUnit) {
        set(r.qtyC, total / unit);
      }
    } finally {
      r._suppress = false;
    }
  }

  String get _currencySymbol {
    try {
      return currencySymbol(_currency);
    } catch (_) {
      return _currency;
    }
  }

  Future<void> _loadRates() async {
    final svc = ref.read(currencyServiceProvider);
    try {
      final rates = await svc.loadUsdBaseRates();
      if (!mounted) return;
      setState(() {
        _usdBaseRates = rates;
        _ratesStale = false;
      });
      // Background staleness check; refresh server-side if needed and reload.
      unawaited(svc.refreshIfStale().then((_) async {
        if (!mounted) return;
        try {
          final fresh = await svc.loadUsdBaseRates();
          if (mounted) setState(() => _usdBaseRates = fresh);
        } catch (_) {}
      }));
    } catch (_) {
      if (mounted) setState(() => _ratesStale = true);
    }
  }

  double? _homeRate(String home) {
    final rates = _usdBaseRates;
    if (rates == null) return null;
    if (_currency == home) return 1.0;
    try {
      return CurrencyService.convert(from: _currency, to: home, rates: rates);
    } catch (_) {
      return null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRates();
  }

  bool _validate() {
    final l = context.l10n;
    final amt = parseAmountInput(_amount.text);
    String? amtErr = (amt == null || amt <= 0) ? l.txFormValidAmount : null;
    setState(() {
      _amountError = amtErr;
    });
    if (_accountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.txFormSelectAnAccount)),
      );
      return false;
    }
    if (_type == 'transfer' && _toAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.txFormSelectDestAccount)),
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
      final supported = ref.read(supportedCurrenciesProvider).value;
      Map<String, double>? rates = _usdBaseRates;
      if (rates == null) {
        try {
          rates = await ref.read(currencyServiceProvider).loadUsdBaseRates();
        } catch (_) {
          // Offline + no cache: snapshot with self-rate only. Display will
          // fall back to raw amount when target currency missing.
          rates = null;
        }
      }
      final Map<String, double> fxSnapshot;
      if (rates != null) {
        final codes = supported?.codes ?? rates.keys.toList(growable: false);
        fxSnapshot = CurrencyService.buildSnapshot(
          from: _currency,
          rates: rates,
          supported: codes,
        );
      } else {
        fxSnapshot = {_currency: 1.0};
      }
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
        'fx_snapshot': fxSnapshot,
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

      if (mounted) {
        // When transaction targets a room, jump into the room view instead
        // of popping back to the previous screen (typically scanner/form).
        if (_roomId != null && _type != 'transfer') {
          final highlight = insertedId != null ? '?highlight=$insertedId' : '';
          context.go('/rooms/$_roomId$highlight');
        } else if ((_aiParsed || _isManualFallback) &&
            _editId == null &&
            insertedId != null) {
          // Scan-originated review save — surface the new row on the
          // transactions tab so the user can see the landing.
          context.go('/transactions?highlight=$insertedId');
        } else {
          context.pop();
        }
      }
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
        ).showSnackBar(SnackBar(content: Text(context.l10n.txFormSaveFailed(e.toString()))));
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
      activeRoomId: _roomId,
    );
    if (picked != null) setState(() => _category = picked);
  }

  void _setType(String type) {
    setState(() {
      _type = type;
      final cats = ref.read(userCategoriesProvider).value ?? [];
      final catKind =
          cats.where((c) => c.key == _category).firstOrNull?.kind;
      if (type == 'income' && catKind != 'income') {
        _category = _fallbackKey('income', cats);
      } else if (type == 'expense' && catKind == 'income') {
        _category = _fallbackKey('expense', cats);
      }
      if (type == 'transfer') _toAccountId = null;
    });
  }

  String _fallbackKey(String kind, List<UserCategory> cats) {
    // Prefer current-room category, then personal default key.
    if (_roomId != null) {
      final inRoom = cats.where(
          (c) => c.isRoom && c.roomId == _roomId && c.kind == kind);
      if (inRoom.isNotEmpty) return inRoom.first.key;
    }
    return kind == 'income' ? 'income_other' : 'other';
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
    final picked = await pickCurrency(context, selected: _currency);
    if (picked != null && picked != _currency) {
      setState(() => _currency = picked);
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
    final l = context.l10n;
    final profile = ref.watch(userProfileProvider).value;
    final home = profile?.homeCurrency ?? 'IDR';
    final catLabel = ref.watch(categoryLabelProvider(
        CategoryLabelKey(key: _category, activeRoomId: _roomId)));

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
              ? l.txFormEditTransaction
              : _isManualFallback
                  ? l.txFormManualEntry
                  : (_aiParsed ? l.txFormConfirm : l.txFormNewTransaction),
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
                  title: l.txFormCouldntRead,
                  body: l.txFormPreFilled,
                ),
              ),
            if (_aiParsed)
              Padding(
                padding: const EdgeInsets.only(bottom: LoitSpacing.s4),
                child: LoitBanner(
                  kind: LoitBannerKind.info,
                  title: l.txFormAiParsed,
                  body: l.txFormPleaseReview,
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
                    label: l.txFormAmount,
                    placeholder: '0',
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_type == 'expense')
                          Text('−',
                              style: LoitTypography.bodyL
                                  .copyWith(color: c.danger)),
                        Text(_currencySymbol,
                            style: LoitTypography.bodyL
                                .copyWith(color: c.contentSecondary)),
                      ],
                    ),
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
                    label: l.txFormCurrency,
                    valueWidget: Text(_currency,
                        style: LoitTypography.bodyL
                            .copyWith(color: c.contentPrimary)),
                    onTap: _pickCurrency,
                  ),
                ),
              ],
            ),
            if (_ratesStale) ...[
              const SizedBox(height: LoitSpacing.s3),
              const StaleRateBanner(),
            ],
            if (_homeRate(home) != null && _currency != home)
              Padding(
                padding: const EdgeInsets.only(top: LoitSpacing.s3),
                child: Text(
                  l.txFormOneFxApprox(
                      _currency, _homeRate(home)!.toStringAsFixed(4), home),
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
                          l.txFormAddAccountFirst,
                          style: LoitTypography.bodyS.copyWith(color: c.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            _picker(
              label: _type == 'transfer' ? l.txFormFromAccount : l.txFormAccount,
              valueWidget: Text(
                accountName ?? l.txFormSelectAccount,
                style: LoitTypography.bodyL.copyWith(
                  color: accountName != null ? c.contentPrimary : c.contentTertiary,
                ),
              ),
              onTap: _pickAccount,
            ),
            if (_type == 'transfer') ...[
              const SizedBox(height: LoitSpacing.s4),
              _picker(
                label: l.txFormToAccount,
                valueWidget: Text(
                  toAccountName ?? l.txFormSelectDestination,
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
                label: _type == 'income' ? l.txFormIncomeCategory : l.txFormExpenseCategory,
                valueWidget: Row(
                  children: [
                    LoitCategoryAvatar(categoryKey: _category, size: 28),
                    const SizedBox(width: LoitSpacing.s3),
                    Text(catLabel,
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
                    label: l.txFormDate,
                    valueWidget: Text(
                      yMMMd(context).format(_date),
                      style: LoitTypography.bodyL
                          .copyWith(color: c.contentPrimary),
                    ),
                    onTap: _pickDate,
                  ),
                ),
                const SizedBox(width: LoitSpacing.s4),
                Expanded(
                  child: _picker(
                    label: l.txFormTime,
                    valueWidget: Text(
                      Hm(context).format(_date),
                      style: LoitTypography.bodyL
                          .copyWith(color: c.contentPrimary),
                    ),
                    onTap: _pickTime,
                  ),
                ),
              ],
            ),
            const SizedBox(height: LoitSpacing.s4),
            Text(l.txFormNotes,
                style: LoitTypography.bodyM.copyWith(
                  color: c.contentPrimary,
                  fontWeight: FontWeight.w600,
                )),
            const SizedBox(height: 6),
            TabBar(
              controller: _notesTabController,
              tabs: [Tab(text: l.txFormTabText), Tab(text: l.txFormTabItems)],
            ),
            const SizedBox(height: LoitSpacing.s3),
            if (_notesMode == _NotesMode.text) ...[
              LoitInput(
                controller: _notes,
                placeholder: l.txFormOptional,
                maxLines: 5,
              ),
              if (!_breakdownHintDismissed && looksLikeBreakdown(_notes.text)) ...[
                const SizedBox(height: LoitSpacing.s3),
                LoitBanner(
                  kind: LoitBannerKind.info,
                  title: l.txFormItemBreakdown,
                  body: l.txFormSwitchToItemsMsg,
                  actionLabel: l.txFormSwitchToItemsBtn,
                  onAction: () => _setNotesMode(_NotesMode.items),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () =>
                        setState(() => _breakdownHintDismissed = true),
                    child: Text(l.txFormDismiss),
                  ),
                ),
              ],
            ] else ...[
              _buildItemsEditor(c),
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
                  : Text(l.txFormSave),
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
    final l = context.l10n;
    final options = [
      ('expense', l.txFormExpense),
      ('income', l.txFormIncome),
      ('transfer', l.txFormTransfer),
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
        // Treat 0/null as "missing" so fallback math kicks in.
        qtyC = TextEditingController(
            text: (qty != null && qty > 0) ? formatAmountInput(qty) : ''),
        unitC = TextEditingController(
            text: (unit != null && unit > 0) ? formatAmountInput(unit) : ''),
        totalC = TextEditingController(
            text: (total != null && total > 0) ? formatAmountInput(total) : '');

  final TextEditingController nameC;
  final TextEditingController qtyC;
  final TextEditingController unitC;
  final TextEditingController totalC;

  bool _suppress = false;

  void dispose() {
    nameC.dispose();
    qtyC.dispose();
    unitC.dispose();
    totalC.dispose();
  }
}
