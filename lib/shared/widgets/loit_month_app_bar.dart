import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../providers/selected_month_provider.dart';
import 'loit_app_bar_month.dart';

/// Shared month app bar wired to [selectedMonthProvider].
///
/// Single widget instance per screen; the underlying month state is shared
/// across screens (Home, Transactions, ...) so paging on one updates all.
class LoitMonthAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const LoitMonthAppBar({super.key, this.actions = const []});

  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedMonthProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);
    return LoitAppBarMonth(
      label: DateFormat.yMMM().format(month),
      onPrev: notifier.prev,
      onNext: notifier.next,
      actions: actions,
    );
  }
}
