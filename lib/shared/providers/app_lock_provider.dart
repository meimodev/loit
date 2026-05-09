import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True while the app is gated behind a biometric prompt.
/// Toggled by [LoitApp] on cold start + on resume after a backgrounded
/// threshold, cleared by the lock screen on successful authentication.
class AppLockedNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void lock() => state = true;
  void unlock() => state = false;
  set value(bool v) => state = v;
}

final appLockedProvider =
    NotifierProvider<AppLockedNotifier, bool>(AppLockedNotifier.new);
