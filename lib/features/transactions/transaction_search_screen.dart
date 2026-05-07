import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/loit_chip.dart';
import '../../shared/widgets/loit_empty_state.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_input.dart';
import '../../shared/widgets/loit_tx_row.dart';

/// In-memory recents. Persists across navigation within session.
final List<String> _recentSearches = <String>[];

/// Active search state for transactions. Top input + recent searches +
/// live results filtered by merchant/notes/category.
class TransactionSearchScreen extends ConsumerStatefulWidget {
  const TransactionSearchScreen({super.key});

  @override
  ConsumerState<TransactionSearchScreen> createState() =>
      _TransactionSearchScreenState();
}

class _TransactionSearchScreenState
    extends ConsumerState<TransactionSearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _commit(String q) {
    final trimmed = q.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _recentSearches.remove(trimmed);
      _recentSearches.insert(0, trimmed);
      if (_recentSearches.length > 6) _recentSearches.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final txns = ref.watch(transactionsProvider);
    final recents = _recentSearches;

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: LoitSpacing.s4),
          child: LoitInput(
            controller: _ctrl,
            placeholder: 'Search notes, category…',
            leading: const Icon(Icons.search),
            trailing: _query.isEmpty
                ? null
                : GestureDetector(
                    onTap: () {
                      _ctrl.clear();
                      setState(() => _query = '');
                    },
                    child: const Icon(Icons.close),
                  ),
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            onSubmitted: _commit,
          ),
        ),
      ),
      body: txns.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (_query.trim().isEmpty) {
            return ListView(
              children: [
                if (recents.isNotEmpty) ...[
                  const LoitGroupLabel(label: 'Recent'),
                  for (final r in recents)
                    ListTile(
                      leading: Icon(Icons.history,
                          color: c.contentTertiary, size: 20),
                      title: Text(r,
                          style: LoitTypography.bodyL
                              .copyWith(color: c.contentPrimary)),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() => _recentSearches.remove(r));
                        },
                      ),
                      onTap: () {
                        _ctrl.text = r;
                        setState(() => _query = r);
                      },
                    ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 80),
                    child: LoitEmptyState(
                      icon: Icons.search_rounded,
                      title: 'Search your transactions',
                      body: 'Type a category or note.',
                    ),
                  ),
                const SizedBox(height: LoitSpacing.s4),
                const LoitGroupLabel(label: 'Filters'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    LoitSpacing.s5,
                    LoitSpacing.s3,
                    LoitSpacing.s5,
                    LoitSpacing.s5,
                  ),
                  child: Wrap(
                    spacing: LoitSpacing.s3,
                    runSpacing: LoitSpacing.s3,
                    children: [
                      for (final s in const [
                        'AI parsed',
                        'This week',
                        'Manual',
                        'Has receipt',
                      ])
                        LoitChip(
                          label: s,
                          variant: LoitChipVariant.outline,
                          onTap: () {
                            _ctrl.text = s;
                            setState(() => _query = s);
                          },
                        ),
                    ],
                  ),
                ),
              ],
            );
          }

          final q = _query.toLowerCase();
          String labelFor(String? key) => ref.read(categoryLabelProvider(
              CategoryLabelKey(key: key)));
          final results = items.where((t) {
            final label = labelFor(t.category).toLowerCase();
            return (t.notes ?? '').toLowerCase().contains(q) ||
                (t.category ?? '').toLowerCase().contains(q) ||
                label.contains(q);
          }).toList();

          if (results.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 80),
              child: LoitEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matches',
                body: 'Nothing matched "$_query".',
              ),
            );
          }

          return ListView.builder(
            itemCount: results.length,
            itemBuilder: (_, i) {
              final t = results[i];
              final label = labelFor(t.category);
              final dateStr =
                  DateFormat.MMMd().add_jm().format(t.createdAt.toLocal());
              return LoitTxRow(
                title: t.notes ?? '',
                categoryKey: t.category,
                subtitle: '$label · $dateStr',
                amount: NumberFormat.simpleCurrency(
                  name: t.currency,
                  decimalDigits: currencyDecimals(t.currency),
                ).format(t.amount),
                showDivider: i != results.length - 1,
                onTap: () {
                  _commit(_query);
                  if (t.id != null) context.push('/transactions/${t.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}
