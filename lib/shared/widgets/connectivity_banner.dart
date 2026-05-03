import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'loit_banner.dart';

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

/// Streams [ConnectivityResult] list. When [offlineDebugOverrideProvider] is
/// non-null the platform stream is replaced with a simulated value so every
/// downstream watcher (banner, SyncService, etc.) sees the simulated state.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final override = ref.watch(offlineDebugOverrideProvider);
  if (override != null) {
    final result = override ? ConnectivityResult.none : ConnectivityResult.wifi;
    return Stream.value([result]);
  }
  final c = Connectivity();
  return c.onConnectivityChanged;
});

bool isOffline(List<ConnectivityResult> rs) =>
    rs.isEmpty || rs.every((r) => r == ConnectivityResult.none);

/// Inline offline banner. Renders nothing when online.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(connectivityProvider);
    final offline = async.maybeWhen(
      data: isOffline,
      orElse: () => false,
    );
    if (!offline) return const SizedBox.shrink();
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: const LoitBanner(
        kind: LoitBannerKind.offline,
        title: "You're offline",
        body: 'Changes are saved locally and will sync when you reconnect.',
      ),
    );
  }
}
