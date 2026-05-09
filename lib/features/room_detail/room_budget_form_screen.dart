import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/log_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/budgets_provider.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/category_picker_sheet.dart';
import '../../shared/widgets/loit_group_label.dart';

class RoomBudgetFormScreen extends ConsumerStatefulWidget {
  const RoomBudgetFormScreen({
    super.key,
    required this.roomId,
    this.currency,
    this.budget,
    this.budgetId,
  });

  final String roomId;
  final String? currency;
  final Map<String, dynamic>? budget;
  final String? budgetId;

  @override
  ConsumerState<RoomBudgetFormScreen> createState() =>
      _RoomBudgetFormScreenState();
}

class _RoomBudgetFormScreenState extends ConsumerState<RoomBudgetFormScreen> {
  late final TextEditingController _amount;
  String _category = 'dining';
  BudgetPeriod _period = BudgetPeriod.monthly;
  int _resetDay = 1;
  int _customDays = 14;
  bool _busy = false;
  bool _hydrated = false;
  Map<String, dynamic>? _budget;
  String? _currency;

  bool get _isEdit => widget.budget != null || widget.budgetId != null;

  @override
  void initState() {
    super.initState();
    _budget = widget.budget;
    _currency = widget.currency;
    final init = _budget;
    final initLimit = (init?['budget_limit'] as num?)?.toDouble();
    _amount = TextEditingController(
      text: initLimit == null ? '' : formatAmountInput(initLimit),
    );
    final initCat = init?['category'] as String?;
    if (initCat != null && initCat.isNotEmpty) _category = initCat;
    if (init != null) {
      _period = BudgetPeriodX.fromWire(init['period'] as String?);
      _resetDay = ((init['reset_day'] as num?) ?? 1).toInt();
      _customDays = ((init['custom_days'] as num?) ?? 14).toInt();
    }
    if (init != null && _currency != null) _hydrated = true;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amt = parseAmountInput(_amount.text);
    if (amt == null || amt <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an amount greater than 0')),
        );
      }
      return;
    }
    final currency = _currency;
    if (currency == null) return;
    setState(() => _busy = true);
    try {
      final svc = ref.read(roomServiceProvider);
      final existingId = _budget?['id'] as String? ?? widget.budgetId;
      final pWire = _period.wire;
      final rDay = _period == BudgetPeriod.custom ? 1 : _resetDay;
      final cDays = _period == BudgetPeriod.custom ? _customDays : null;
      if (_isEdit && existingId != null) {
        Log.i('RoomBudgetForm', 'Updating $existingId → $_category=$amt');
        await svc.updateRoomBudget(
          budgetId: existingId,
          roomId: widget.roomId,
          category: _category,
          budgetLimit: amt,
          currency: currency,
          period: pWire,
          resetDay: rDay,
          customDays: cDays,
        );
      } else {
        Log.i('RoomBudgetForm', 'Upserting $_category=$amt');
        await svc.upsertRoomBudget(
          roomId: widget.roomId,
          category: _category,
          budgetLimit: amt,
          currency: currency,
          period: pWire,
          resetDay: rDay,
          customDays: cDays,
        );
      }
      ref.invalidate(roomBudgetsProvider(widget.roomId));
      if (mounted) context.pop();
    } catch (e) {
      Log.e('RoomBudgetForm', 'Save failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final existingId = _budget?['id'] as String? ?? widget.budgetId;
    if (existingId == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete budget?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(roomServiceProvider).deleteRoomBudget(
            budgetId: existingId,
            roomId: widget.roomId,
          );
      ref.invalidate(roomBudgetsProvider(widget.roomId));
      if (mounted) context.pop();
    } catch (e) {
      Log.e('RoomBudgetForm', 'Delete failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;

    // Hydrate from server when route extra is absent.
    if (!_hydrated) {
      // Currency from room detail if not provided.
      if (_currency == null) {
        final roomAsync = ref.watch(roomDetailProvider(widget.roomId));
        roomAsync.whenData((r) {
          final cur = r['base_currency'] as String? ?? 'IDR';
          if (mounted && _currency != cur) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              setState(() => _currency = cur);
            });
          }
        });
      }
      // Budget row from id if edit mode and not pre-supplied.
      if (_budget == null && widget.budgetId != null) {
        final budgetAsync = ref.watch(roomBudgetProvider(RoomBudgetKey(
          roomId: widget.roomId,
          budgetId: widget.budgetId!,
        )));
        return budgetAsync.when(
          loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator())),
          error: (e, _) => Scaffold(
              appBar: AppBar(),
              body: Center(child: Text('Error: $e'))),
          data: (row) {
            if (row == null) {
              return Scaffold(
                appBar: AppBar(title: const Text('Edit room budget')),
                body: const Center(child: Text('Budget not found')),
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final limit = (row['budget_limit'] as num?)?.toDouble();
              final cat = row['category'] as String?;
              setState(() {
                _budget = row;
                _amount.text =
                    limit == null ? '' : formatAmountInput(limit);
                if (cat != null && cat.isNotEmpty) _category = cat;
                _period = BudgetPeriodX.fromWire(row['period'] as String?);
                _resetDay = ((row['reset_day'] as num?) ?? 1).toInt();
                _customDays = ((row['custom_days'] as num?) ?? 14).toInt();
                _currency ??= row['currency'] as String?;
                if (_currency != null) _hydrated = true;
              });
            });
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          },
        );
      }
      if (_currency == null) {
        return const Scaffold(
            body: Center(child: CircularProgressIndicator()));
      }
      _hydrated = true;
    }

    final currency = _currency!;
    final style = ref.watch(categoryStyleProvider(_category));
    final catLabel = ref.watch(categoryLabelProvider(
        CategoryLabelKey(key: _category, activeRoomId: widget.roomId)));
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit room budget' : 'New room budget'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: _busy ? null : _delete,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                Container(
                  color: c.surface,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text('LIMIT',
                          style: LoitTypography.bodyS.copyWith(
                            color: c.contentSecondary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4,
                          )),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: TextField(
                          controller: _amount,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]')),
                            ThousandsInputFormatter(),
                          ],
                          style: LoitTypography.displayM.copyWith(
                            fontSize: 44,
                            fontWeight: FontWeight.w600,
                            color: c.contentPrimary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(color: c.contentTertiary),
                            prefixText: _currencyPrefix(currency),
                            prefixStyle: LoitTypography.titleL
                                .copyWith(color: c.contentSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: c.borderSubtle),
                const LoitGroupLabel(label: 'SETUP'),
                _row(
                  context,
                  label: 'Category',
                  value: catLabel,
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: style.tint.withValues(alpha: 0.14),
                      borderRadius: LoitRadius.brS,
                    ),
                    child: Icon(style.icon, color: style.tint, size: 16),
                  ),
                  onTap: () async {
                    final picked = await pickLoitCategory(context,
                        selectedKey: _category,
                        activeRoomId: widget.roomId);
                    if (picked != null) setState(() => _category = picked);
                  },
                ),
                _row(
                  context,
                  label: 'Period',
                  value: _period.label,
                  onTap: _pickPeriod,
                ),
                _row(
                  context,
                  label: 'Resets on',
                  value: _resetsOnLabel(),
                  onTap: _pickResetsOn,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: LoitPalette.teal50,
                      borderRadius: LoitRadius.brM,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: LoitPalette.teal700),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                              'Room budgets apply to this room only. All members can see them.',
                              style: LoitTypography.bodyS.copyWith(
                                  color: LoitPalette.teal800, height: 1.4)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(LoitSpacing.s4),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border(top: BorderSide(color: c.borderSubtle)),
            ),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _busy ? null : _save,
                  child: Text(_isEdit ? 'Save changes' : 'Create budget'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];
  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _resetsOnLabel() {
    switch (_period) {
      case BudgetPeriod.weekly:
        return _weekdayNames[(_resetDay - 1).clamp(0, 6)];
      case BudgetPeriod.monthly:
        return _resetDay == 0 ? 'Last day' : 'Day $_resetDay';
      case BudgetPeriod.yearly:
        return '1 ${_monthNames[(_resetDay - 1).clamp(0, 11)]}';
      case BudgetPeriod.custom:
        return 'Every $_customDays days';
    }
  }

  Future<void> _pickPeriod() async {
    final picked = await showModalBottomSheet<BudgetPeriod>(
      context: context,
      backgroundColor: context.loitColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: BudgetPeriod.values
              .map((p) => ListTile(
                    title: Text(p.label),
                    trailing: p == _period
                        ? const Icon(Icons.check, size: 18)
                        : null,
                    onTap: () => Navigator.pop(ctx, p),
                  ))
              .toList(),
        ),
      ),
    );
    if (picked == null || picked == _period) return;
    setState(() {
      _period = picked;
      _resetDay = 1;
    });
  }

  Future<void> _pickResetsOn() async {
    switch (_period) {
      case BudgetPeriod.weekly:
        final picked = await _pickFromList<int>(
          title: 'Resets on',
          options: List.generate(7, (i) => (i + 1, _weekdayNames[i])),
          selected: _resetDay,
        );
        if (picked != null) setState(() => _resetDay = picked);
        return;
      case BudgetPeriod.monthly:
        final opts = <(int, String)>[
          for (var d = 1; d <= 28; d++) (d, 'Day $d'),
          (0, 'Last day'),
        ];
        final picked = await _pickFromList<int>(
          title: 'Resets on',
          options: opts,
          selected: _resetDay,
        );
        if (picked != null) setState(() => _resetDay = picked);
        return;
      case BudgetPeriod.yearly:
        final picked = await _pickFromList<int>(
          title: 'Resets on',
          options: [
            for (var m = 1; m <= 12; m++) (m, '1 ${_monthNames[m - 1]}'),
          ],
          selected: _resetDay,
        );
        if (picked != null) setState(() => _resetDay = picked);
        return;
      case BudgetPeriod.custom:
        final picked = await _pickFromList<int>(
          title: 'Every',
          options: const [
            (7, 'Every 7 days'),
            (10, 'Every 10 days'),
            (14, 'Every 14 days'),
            (21, 'Every 21 days'),
            (30, 'Every 30 days'),
            (60, 'Every 60 days'),
            (90, 'Every 90 days'),
          ],
          selected: _customDays,
        );
        if (picked != null) setState(() => _customDays = picked);
        return;
    }
  }

  Future<T?> _pickFromList<T>({
    required String title,
    required List<(T, String)> options,
    required T selected,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: context.loitColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(title,
                      style: LoitTypography.titleM.copyWith(
                          color: ctx.loitColors.contentPrimary)),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: options
                      .map((o) => ListTile(
                            title: Text(o.$2),
                            trailing: o.$1 == selected
                                ? const Icon(Icons.check, size: 18)
                                : null,
                            onTap: () => Navigator.pop(ctx, o.$1),
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _currencyPrefix(String code) {
    switch (code.toUpperCase()) {
      case 'IDR':
        return 'Rp ';
      case 'USD':
        return r'$ ';
      case 'EUR':
        return '€ ';
      default:
        return '$code ';
    }
  }

  Widget _row(BuildContext context,
      {required String label,
      required String value,
      Widget? leading,
      VoidCallback? onTap}) {
    final c = context.loitColors;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(bottom: BorderSide(color: c.borderSubtle)),
        ),
        child: Row(
          children: [
            if (leading != null) ...[leading, const SizedBox(width: 12)],
            Expanded(
              child: Text(label,
                  style: LoitTypography.bodyL
                      .copyWith(color: c.contentPrimary)),
            ),
            Text(value,
                style: LoitTypography.bodyL.copyWith(
                    color: c.contentSecondary, fontWeight: FontWeight.w500)),
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: c.contentTertiary),
            ],
          ],
        ),
      ),
    );
  }
}
