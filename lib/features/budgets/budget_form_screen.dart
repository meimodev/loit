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
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/category_picker_sheet.dart';
import '../../shared/widgets/loit_group_label.dart';

class BudgetFormScreen extends ConsumerStatefulWidget {
  const BudgetFormScreen({super.key, this.budget});

  final Budget? budget;

  @override
  ConsumerState<BudgetFormScreen> createState() => _BudgetFormScreenState();
}

class _BudgetFormScreenState extends ConsumerState<BudgetFormScreen> {
  late final TextEditingController _amount;
  String _category = 'dining';
  BudgetPeriod _period = BudgetPeriod.monthly;
  int _resetDay = 1;
  int _customDays = 14;
  bool _alert70 = true;
  bool _alert100 = true;
  bool _alertDaily = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final init = widget.budget;
    _amount = TextEditingController(
        text: init == null ? '' : formatAmountInput(init.monthlyLimit));
    if (init != null) {
      _category = init.category;
      _period = init.period;
      _resetDay = init.resetDay;
      _customDays = init.customDays ?? 14;
    }
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
    setState(() => _busy = true);
    try {
      Log.i('BudgetForm', 'Upserting budget: $_category = $amt');
      await ref.read(budgetsProvider.notifier).upsert(
            category: _category,
            monthlyLimit: amt,
            period: _period,
            resetDay: _period == BudgetPeriod.custom ? 1 : _resetDay,
            customDays: _period == BudgetPeriod.custom ? _customDays : null,
            id: widget.budget?.id,
          );
      Log.i('BudgetForm', 'Upsert completed successfully');
      if (mounted) context.pop();
    } catch (e) {
      Log.e('BudgetForm', 'Upsert failed', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final style = ref.watch(categoryStyleProvider(_category));
    final catLabel = ref
        .watch(categoryLabelProvider(CategoryLabelKey(key: _category)));
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(widget.budget == null ? 'New budget' : 'Edit budget'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
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
                            prefixText: 'Rp ',
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
                        selectedKey: _category);
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
                const LoitGroupLabel(label: 'ALERTS'),
                _toggle(context, label: 'At 70%', value: _alert70,
                    onChanged: (v) => setState(() => _alert70 = v)),
                _toggle(context, label: 'At 100%', value: _alert100,
                    onChanged: (v) => setState(() => _alert100 = v)),
                _toggle(context, label: 'Daily over budget', value: _alertDaily,
                    onChanged: (v) => setState(() => _alertDaily = v)),
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
                              "You'll see this in Personal only. Room budgets are set in each room.",
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
                  child: Text(widget.budget == null
                      ? 'Create budget'
                      : 'Save changes'),
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
      _resetDay = switch (picked) {
        BudgetPeriod.weekly => 1,
        BudgetPeriod.monthly => 1,
        BudgetPeriod.yearly => 1,
        BudgetPeriod.custom => 1,
      };
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
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, size: 18, color: c.contentTertiary),
          ],
        ),
      ),
    );
  }

  Widget _toggle(BuildContext context,
      {required String label,
      required bool value,
      required ValueChanged<bool> onChanged}) {
    final c = context.loitColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.borderSubtle)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: LoitTypography.bodyL
                    .copyWith(color: c.contentPrimary)),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
