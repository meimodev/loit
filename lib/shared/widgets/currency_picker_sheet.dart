import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../providers/supported_currencies_provider.dart';
import 'loit_input.dart';
import 'loit_sheet.dart';

/// Shared currency picker. Reads `supportedCurrenciesProvider` (db registry).
/// Returns the selected `code` (e.g. `IDR`) or null if dismissed.
Future<String?> pickCurrency(
  BuildContext context, {
  String? selected,
  String? title,
}) {
  final resolvedTitle = title ?? context.l10n.currencyPickerTitle;
  return showLoitSheet<String>(
    context,
    builder: (_) => _CurrencyPickerSheet(selected: selected, title: resolvedTitle),
  );
}

class _CurrencyPickerSheet extends ConsumerStatefulWidget {
  const _CurrencyPickerSheet({required this.selected, required this.title});
  final String? selected;
  final String title;

  @override
  ConsumerState<_CurrencyPickerSheet> createState() =>
      _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends ConsumerState<_CurrencyPickerSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final async = ref.watch(supportedCurrenciesProvider);
    return LoitSheet(
      title: widget.title,
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LoitSpacing.s5,
                LoitSpacing.s3,
                LoitSpacing.s5,
                LoitSpacing.s3,
              ),
              child: LoitInput(
                controller: _searchCtrl,
                placeholder: context.l10n.currencySearchPlaceholder,
                leading: Icon(
                  Icons.search,
                  size: 18,
                  color: c.contentTertiary,
                ),
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: async.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(LoitSpacing.s4),
                    child: Text(
                      context.l10n.currencyLoadError('$e'),
                      style: LoitTypography.bodyS
                          .copyWith(color: c.contentSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                data: (registry) {
                  final all = registry.all;
                  final list = _query.isEmpty
                      ? all
                      : all.where((cc) {
                          return cc.code.toLowerCase().contains(_query) ||
                              cc.name.toLowerCase().contains(_query) ||
                              cc.symbol.toLowerCase().contains(_query);
                        }).toList(growable: false);
                  if (list.isEmpty) {
                    return Center(
                      child: Text(
                        context.l10n.currencyNoMatches,
                        style: LoitTypography.bodyM
                            .copyWith(color: c.contentTertiary),
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, i) {
                      final cur = list[i];
                      final isSelected = cur.code == widget.selected;
                      return InkWell(
                        onTap: () => Navigator.pop(context, cur.code),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: LoitSpacing.s5,
                            vertical: LoitSpacing.s3,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: c.muted,
                                  borderRadius: LoitRadius.brS,
                                ),
                                child: Text(
                                  cur.symbol,
                                  style: LoitTypography.bodyM.copyWith(
                                    color: c.contentPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: LoitSpacing.s3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cur.code,
                                      style: LoitTypography.bodyL.copyWith(
                                        color: c.contentPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      cur.name,
                                      style: LoitTypography.bodyS.copyWith(
                                        color: c.contentSecondary,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check_rounded, color: c.brand),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
