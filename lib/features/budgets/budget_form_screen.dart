import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/budgets_provider.dart';
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
    if (init != null) _category = init.category;
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amt = parseAmountInput(_amount.text);
    if (amt == null || amt <= 0) return;
    setState(() => _busy = true);
    try {
      await ref.read(budgetsProvider.notifier).upsert(
            category: _category,
            monthlyLimit: amt,
            id: widget.budget?.id,
          );
      if (mounted) context.pop();
    } catch (e) {
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
    final style = LoitCategories.resolve(_category);
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
                  value: style.label,
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
                _row(context, label: 'Period', value: 'Monthly · 1st'),
                _row(context, label: 'Resets on', value: 'Day 1'),
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
