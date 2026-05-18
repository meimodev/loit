import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/locale_date_format.dart';

import '../providers/selected_month_provider.dart';
import 'loit_app_bar_month.dart';

/// Shared month app bar wired to [selectedMonthProvider].
///
/// Single widget instance per screen; the underlying month state is shared
/// across screens (Home, Transactions, ...) so paging on one updates all.
class LoitMonthAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  const LoitMonthAppBar({super.key, this.actions = const []});

  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  ConsumerState<LoitMonthAppBar> createState() => _LoitMonthAppBarState();
}

class _LoitMonthAppBarState extends ConsumerState<LoitMonthAppBar> {
  DateTime? _prevMonth;
  int _direction = 0;

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(selectedMonthProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);
    if (_prevMonth != null && _prevMonth != month) {
      _direction = month.isAfter(_prevMonth!) ? 1 : -1;
    }
    _prevMonth = month;
    return LoitAppBarMonth(
      label: yMMM(context).format(month),
      direction: _direction,
      onPrev: notifier.prev,
      onNext: notifier.next,
      actions: widget.actions,
    );
  }
}
