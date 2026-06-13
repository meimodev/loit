import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debug override for testing offline behavior.
/// `true` = simulate offline, `false` = simulate online, `null` = use real connectivity.
final offlineDebugOverrideProvider = NotifierProvider<OfflineDebugOverride, bool?>(
  OfflineDebugOverride.new,
);

class OfflineDebugOverride extends Notifier<bool?> {
  @override
  bool? build() => null;

  void set(bool? v) => state = v;
}
