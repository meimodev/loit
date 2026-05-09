import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/log_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/budgets_provider.dart';
import '../../shared/providers/home_currency_provider.dart';
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
        final l = context.l10n;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.budgetFormInvalidAmount)),
        );
      }
      return;
    }
    setState(() => _busy = true);
    try {
      Log.i('BudgetForm', 'Upserting budget: $_category = $amt');
      final String budgetCurrency = ref.read(homeCurrencyProvider);
      await ref.read(budgetsProvider.notifier).upsert(
            category: _category,
            monthlyLimit: amt,
            currency: budgetCurrency,
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
    final l = context.l10n;
    final style = ref.watch(categoryStyleProvider(_category));
    final catLabel = ref
        .watch(categoryLabelProvider(CategoryLabelKey(key: _category)));
    final homeCurrency = ref.watch(homeCurrencyProvider);
    final symbol = currencySymbol(homeCurrency);
    final isEdit = widget.budget != null;
    final existingBudgets = ref.watch(budgetsProvider).value ?? const [];
    final usedCategories = <String>{
      for (final b in existingBudgets)
        if (b.id != widget.budget?.id) b.category,
    };
    if (!isEdit && usedCategories.contains(_category)) {
      final personalCats = ref.watch(expenseCategoriesProvider);
      final next = personalCats
          .map((c) => c.key)
          .firstWhere((k) => !usedCategories.contains(k), orElse: () => '');
      if (next.isNotEmpty && next != _category) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _category = next);
        });
      }
    }
    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(isEdit ? l.budgetFormEditBudget : l.budgetFormNewBudget),
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
                      Text(l.budgetFormLimit,
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
                            prefixText: '$symbol ',
                            prefixStyle: LoitTypography.titleL
                                .copyWith(color: c.contentSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: c.borderSubtle),
                LoitGroupLabel(label: l.budgetFormSetup),
                _row(
                  context,
                  label: l.budgetFormCategory,
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
                  showChevron: !isEdit,
                  onTap: isEdit
                      ? null
                      : () async {
                          final picked = await pickLoitCategory(
                            context,
                            selectedKey: _category,
                            excludeKeys: usedCategories,
                          );
                          if (picked != null) {
                            setState(() => _category = picked);
                          }
                        },
                ),
                _row(
                  context,
                  label: l.budgetFormPeriod,
                  value: _periodLabel(l, _period),
                  onTap: _pickPeriod,
                ),
                _row(
                  context,
                  label: l.budgetFormResetsOn,
                  value: _resetsOnLabel(l),
                  onTap: _pickResetsOn,
                ),
                LoitGroupLabel(label: l.budgetFormAlerts),
                _toggle(context, label: l.budgetFormAt70, value: _alert70,
                    onChanged: (v) => setState(() => _alert70 = v)),
                _toggle(context, label: l.budgetFormAt100, value: _alert100,
                    onChanged: (v) => setState(() => _alert100 = v)),
                _toggle(context, label: l.budgetFormDailyOverBudget, value: _alertDaily,
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
                              l.budgetFormPersonalOnlyInfo,
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
                  child: Text(isEdit
                      ? l.budgetFormSaveChanges
                      : l.budgetFormCreateBudget),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _weekdayList(AppLocalizations l) => [
        l.budgetFormMonday,
        l.budgetFormTuesday,
        l.budgetFormWednesday,
        l.budgetFormThursday,
        l.budgetFormFriday,
        l.budgetFormSaturday,
        l.budgetFormSunday,
      ];

  List<String> _monthList(AppLocalizations l) => [
        l.budgetFormJanuary,
        l.budgetFormFebruary,
        l.budgetFormMarch,
        l.budgetFormApril,
        l.budgetFormMay,
        l.budgetFormJune,
        l.budgetFormJuly,
        l.budgetFormAugust,
        l.budgetFormSeptember,
        l.budgetFormOctober,
        l.budgetFormNovember,
        l.budgetFormDecember,
      ];

  String _periodLabel(AppLocalizations l, BudgetPeriod p) => switch (p) {
        BudgetPeriod.weekly => l.budgetsScreenWeekly,
        BudgetPeriod.monthly => l.budgetsScreenMonthly,
        BudgetPeriod.yearly => p.label,
        BudgetPeriod.custom => l.budgetsScreenCustom,
      };

  String _resetsOnLabel(AppLocalizations l) {
    switch (_period) {
      case BudgetPeriod.weekly:
        return _weekdayList(l)[(_resetDay - 1).clamp(0, 6)];
      case BudgetPeriod.monthly:
        return _resetDay == 0 ? l.budgetFormLastDay : l.budgetFormDay(_resetDay);
      case BudgetPeriod.yearly:
        return l.budgetForm1Month(_monthList(l)[(_resetDay - 1).clamp(0, 11)]);
      case BudgetPeriod.custom:
        return l.budgetFormEveryNDays(_customDays);
    }
  }

  Future<void> _pickPeriod() async {
    final l = context.l10n;
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
                    title: Text(_periodLabel(l, p)),
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
    final l = context.l10n;
    final weekdays = _weekdayList(l);
    final months = _monthList(l);
    switch (_period) {
      case BudgetPeriod.weekly:
        final picked = await _pickFromList<int>(
          title: l.budgetFormResetsOn,
          options: List.generate(7, (i) => (i + 1, weekdays[i])),
          selected: _resetDay,
        );
        if (picked != null) setState(() => _resetDay = picked);
        return;
      case BudgetPeriod.monthly:
        final opts = <(int, String)>[
          for (var d = 1; d <= 28; d++) (d, l.budgetFormDay(d)),
          (0, l.budgetFormLastDay),
        ];
        final picked = await _pickFromList<int>(
          title: l.budgetFormResetsOn,
          options: opts,
          selected: _resetDay,
        );
        if (picked != null) setState(() => _resetDay = picked);
        return;
      case BudgetPeriod.yearly:
        final picked = await _pickFromList<int>(
          title: l.budgetFormResetsOn,
          options: [
            for (var m = 1; m <= 12; m++) (m, l.budgetForm1Month(months[m - 1])),
          ],
          selected: _resetDay,
        );
        if (picked != null) setState(() => _resetDay = picked);
        return;
      case BudgetPeriod.custom:
        final picked = await _pickFromList<int>(
          title: l.budgetFormEvery,
          options: [
            (7, l.budgetFormEveryNDays(7)),
            (10, l.budgetFormEveryNDays(10)),
            (14, l.budgetFormEveryNDays(14)),
            (21, l.budgetFormEveryNDays(21)),
            (30, l.budgetFormEveryNDays(30)),
            (60, l.budgetFormEveryNDays(60)),
            (90, l.budgetFormEveryNDays(90)),
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
      VoidCallback? onTap,
      bool showChevron = true}) {
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
            if (showChevron) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: c.contentTertiary),
            ],
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
