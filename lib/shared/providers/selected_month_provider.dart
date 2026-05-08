import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  void prev() => state = DateTime(state.year, state.month - 1, 1);
  void next() => state = DateTime(state.year, state.month + 1, 1);

  void setMonth(DateTime d) => state = DateTime(d.year, d.month, 1);

  void reset() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, 1);
  }
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateTime>(
  SelectedMonthNotifier.new,
);
