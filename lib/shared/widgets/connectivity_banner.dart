import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'loit_banner.dart';

/// Streams [ConnectivityResult] list. Empty / [ConnectivityResult.none] = offline.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final c = Connectivity();
  return c.onConnectivityChanged;
});

bool _isOffline(List<ConnectivityResult> rs) =>
    rs.isEmpty || rs.every((r) => r == ConnectivityResult.none);

/// Inline offline banner. Renders nothing when online.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(connectivityProvider);
    final offline = async.maybeWhen(
      data: _isOffline,
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
