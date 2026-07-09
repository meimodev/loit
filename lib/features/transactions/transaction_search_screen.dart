import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/utils/locale_date_format.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/selected_month_provider.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/loit_chip.dart';
import '../../shared/widgets/loit_empty_state.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_input.dart';
import '../../shared/widgets/loit_room_origin_badge.dart';
import '../../shared/widgets/loit_tx_row.dart';
import '../rooms/room_colors.dart';

final List<String> _recentSearches = <String>[];

enum _TypeFilter { income, expense }

enum _DateFilter { week, month, year, custom }

enum _ScopeFilter { rooms, personal }

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

  _TypeFilter? _type;
  _DateFilter? _date;
  _ScopeFilter? _source;
  DateTime? _customDate;

  bool get _anyFilter => _type != null || _date != null || _source != null;

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

  bool _matchesDate(DateTime created) {
    if (_date == null) return true;
    final now = DateTime.now();
    final d = created.toLocal();
    switch (_date!) {
      case _DateFilter.week:
        final today = DateTime(now.year, now.month, now.day);
        final weekStart = today.subtract(Duration(days: now.weekday - 1));
        return !d.isBefore(weekStart);
      case _DateFilter.month:
        return d.year == now.year && d.month == now.month;
      case _DateFilter.year:
        return d.year == now.year;
      case _DateFilter.custom:
        final cd = _customDate;
        if (cd == null) return true;
        return d.year == cd.year && d.month == cd.month && d.day == cd.day;
    }
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked == null) return;
    setState(() {
      _customDate = picked;
      _date = _DateFilter.custom;
    });
  }

  bool _matchesType(Txn t) {
    if (_type == null) return true;
    switch (_type!) {
      case _TypeFilter.income:
        return t.isIncome;
      case _TypeFilter.expense:
        return !t.isIncome && !t.isTransfer;
    }
  }

  bool _matchesSource(Txn t) {
    if (_source == null) return true;
    switch (_source!) {
      case _ScopeFilter.rooms:
        return t.roomId != null;
      case _ScopeFilter.personal:
        return t.roomId == null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final txns = ref.watch(transactionsProvider);
    final roomTxns = ref.watch(myRoomsTransactionsProvider);
    final myRooms = ref.watch(myRoomsProvider).value ?? const [];
    final roomNameById = <String, String>{
      for (final r in myRooms)
        if (r['id'] is String && r['name'] is String)
          r['id'] as String: r['name'] as String,
    };
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
            placeholder: l.txSearchPlaceholder,
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
        error: (e, _) => Center(child: Text(context.l10n.commonErrorWithDetail('$e'))),
        data: (items) {
          final merged = <Txn>[...items];
          final seenIds = <String>{
            for (final t in items)
              if (t.id != null) t.id!,
          };
          for (final t in roomTxns.value ?? const <Txn>[]) {
            if (t.id != null && !seenIds.add(t.id!)) continue;
            merged.add(t);
          }
          merged.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final filtered = merged
              .where((t) =>
                  _matchesType(t) &&
                  _matchesSource(t) &&
                  _matchesDate(t.createdAt))
              .toList();

          final q = _query.toLowerCase();
          String labelFor(String? key) =>
              ref.read(categoryLabelProvider(CategoryLabelKey(key: key)));

          final results = q.isEmpty
              ? filtered
              : filtered.where((t) {
                  final label = labelFor(t.category).toLowerCase();
                  final roomName = (t.roomName ??
                          (t.roomId != null
                              ? roomNameById[t.roomId!]
                              : null) ??
                          '')
                      .toLowerCase();
                  return (t.notes ?? '').toLowerCase().contains(q) ||
                      (t.category ?? '').toLowerCase().contains(q) ||
                      label.contains(q) ||
                      roomName.contains(q);
                }).toList();

          final showRecents = q.isEmpty && !_anyFilter;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FiltersBar(
                type: _type,
                date: _date,
                source: _source,
                customDate: _customDate,
                onTypeChanged: (v) => setState(() => _type = v),
                onDateChanged: (v) => setState(() {
                  _date = v;
                  if (v != _DateFilter.custom) _customDate = null;
                }),
                onSourceChanged: (v) => setState(() => _source = v),
                onCustomTap: _pickCustomDate,
              ),
              Divider(height: 1, color: c.borderDefault),
              Expanded(
                child: showRecents
                    ? _RecentsView(
                        recents: recents,
                        onTap: (r) {
                          _ctrl.text = r;
                          setState(() => _query = r);
                        },
                        onRemove: (r) =>
                            setState(() => _recentSearches.remove(r)),
                      )
                    : results.isEmpty
                        ? _CenteredEmpty(
                            child: LoitEmptyState(
                              icon: Icons.search_off_rounded,
                              title: l.txSearchNoMatches,
                              body: q.isEmpty
                                  ? l.txSearchNoMatchesBody
                                  : l.txSearchNoMatchesQuery(_query),
                            ),
                          )
                        : RefreshIndicator(
                          onRefresh: () async {
                            await ref
                                .read(transactionsProvider.notifier)
                                .refresh();
                            ref.invalidate(myRoomsTransactionsProvider);
                          },
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: results.length,
                            itemBuilder: (_, i) {
                              final t = results[i];
                              final label = labelFor(t.category);
                              final dateStr = MMMd(context)
                                  .add_jm()
                                  .format(t.createdAt.toLocal());
                              final isRoomTx = t.roomId != null;
                              final roomAccent = isRoomTx
                                  ? RoomColors.forId(t.roomId!)
                                  : null;
                              final roomBadge = isRoomTx
                                  ? LoitRoomOriginBadge(
                                      accent: roomAccent!,
                                      name: t.roomName ??
                                          roomNameById[t.roomId!] ??
                                          l.txSearchRoom,
                                    )
                                  : null;
                              return LoitTxRow(
                                title: t.notes ?? '',
                                categoryKey: t.category,
                                subtitle: '$label · $dateStr',
                                amount: formatMoney(t.amount, t.currency),
                                isIncome: t.isIncome,
                                isTransfer: t.isTransfer,
                                showDivider: i != results.length - 1,
                                roomBadge: roomBadge,
                                accentStripeColor: roomAccent,
                                onTap: () {
                                  _commit(_query);
                                  ref
                                      .read(selectedMonthProvider.notifier)
                                      .setMonth(t.createdAt.toLocal());
                                  if (isRoomTx) {
                                    final highlight = t.id != null
                                        ? '?highlight=${t.id}'
                                        : '';
                                    context
                                        .go('/rooms/${t.roomId}$highlight');
                                  } else if (t.id != null) {
                                    context.go(
                                        '/transactions?highlight=${t.id}');
                                  }
                                },
                              );
                            },
                          ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    required this.type,
    required this.date,
    required this.source,
    required this.customDate,
    required this.onTypeChanged,
    required this.onDateChanged,
    required this.onSourceChanged,
    required this.onCustomTap,
  });

  final _TypeFilter? type;
  final _DateFilter? date;
  final _ScopeFilter? source;
  final DateTime? customDate;
  final ValueChanged<_TypeFilter?> onTypeChanged;
  final ValueChanged<_DateFilter?> onDateChanged;
  final ValueChanged<_ScopeFilter?> onSourceChanged;
  final VoidCallback onCustomTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: LoitSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChipGroup(
            label: l.txSearchType,
            chips: [
              _ChipSpec(
                label: l.txSearchIncome,
                leading: Icons.arrow_downward_rounded,
                selected: type == _TypeFilter.income,
                onTap: () => onTypeChanged(
                    type == _TypeFilter.income ? null : _TypeFilter.income),
              ),
              _ChipSpec(
                label: l.txSearchExpense,
                leading: Icons.arrow_upward_rounded,
                selected: type == _TypeFilter.expense,
                onTap: () => onTypeChanged(
                    type == _TypeFilter.expense ? null : _TypeFilter.expense),
              ),
            ],
          ),
          _ChipGroup(
            label: l.txSearchDate,
            chips: [
              _ChipSpec(
                label: l.txSearchThisWeek,
                selected: date == _DateFilter.week,
                onTap: () => onDateChanged(
                    date == _DateFilter.week ? null : _DateFilter.week),
              ),
              _ChipSpec(
                label: l.txSearchThisMonth,
                selected: date == _DateFilter.month,
                onTap: () => onDateChanged(
                    date == _DateFilter.month ? null : _DateFilter.month),
              ),
              _ChipSpec(
                label: l.txSearchThisYear,
                selected: date == _DateFilter.year,
                onTap: () => onDateChanged(
                    date == _DateFilter.year ? null : _DateFilter.year),
              ),
              _ChipSpec(
                label: (date == _DateFilter.custom && customDate != null)
                    ? yMMMd(context).format(customDate!)
                    : l.txSearchCustom,
                leading: Icons.event_outlined,
                selected: date == _DateFilter.custom,
                onTap: () {
                  if (date == _DateFilter.custom) {
                    onDateChanged(null);
                  } else {
                    onCustomTap();
                  }
                },
              ),
            ],
          ),
          _ChipGroup(
            label: l.txSearchScope,
            chips: [
              _ChipSpec(
                label: l.txSearchPersonal,
                leading: Icons.person_outline_rounded,
                selected: source == _ScopeFilter.personal,
                onTap: () => onSourceChanged(source == _ScopeFilter.personal
                    ? null
                    : _ScopeFilter.personal),
              ),
              _ChipSpec(
                label: l.txSearchRooms,
                leading: Icons.groups_outlined,
                selected: source == _ScopeFilter.rooms,
                onTap: () => onSourceChanged(source == _ScopeFilter.rooms
                    ? null
                    : _ScopeFilter.rooms),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChipSpec {
  const _ChipSpec({
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? leading;
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({required this.label, required this.chips});
  final String label;
  final List<_ChipSpec> chips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LoitGroupLabel(label: label),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: LoitSpacing.s5,
              vertical: 4,
            ),
            itemCount: chips.length,
            separatorBuilder: (_, __) =>
                const SizedBox(width: LoitSpacing.s3),
            itemBuilder: (_, i) {
              final s = chips[i];
              return LoitChip(
                label: s.label,
                leading: s.leading,
                selected: s.selected,
                variant: s.selected
                    ? LoitChipVariant.selected
                    : LoitChipVariant.outline,
                onTap: s.onTap,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CenteredEmpty extends StatelessWidget {
  const _CenteredEmpty({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RecentsView extends StatelessWidget {
  const _RecentsView({
    required this.recents,
    required this.onTap,
    required this.onRemove,
  });
  final List<String> recents;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    if (recents.isEmpty) {
      return _CenteredEmpty(
        child: LoitEmptyState(
          icon: Icons.search_rounded,
          title: l.txSearchEmptyTitle,
          body: l.txSearchEmptyBody,
        ),
      );
    }
    return ListView(
      children: [
        LoitGroupLabel(label: l.txSearchRecent),
        for (final r in recents)
          ListTile(
            leading:
                Icon(Icons.history, color: c.contentTertiary, size: 20),
            title: Text(r,
                style: LoitTypography.bodyL
                    .copyWith(color: c.contentPrimary)),
            trailing: IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => onRemove(r),
            ),
            onTap: () => onTap(r),
          ),
      ],
    );
  }
}
