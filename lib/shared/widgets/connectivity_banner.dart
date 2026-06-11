import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/reachability_service.dart';
import '../../l10n/l10n_x.dart';
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

/// Inline offline banner. Renders nothing when online. Backed by
/// [reachabilityProvider] (interface + active probe) so it agrees with the
/// write-path gate in `transactions_provider`.
class ConnectivityBanner extends ConsumerWidget {
  const ConnectivityBanner({super.key, this.padding});

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reachabilityProvider);
    final offline = async.maybeWhen(
      data: (online) => !online,
      orElse: () => false,
    );
    if (!offline) return const SizedBox.shrink();
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: LoitBanner(
        kind: LoitBannerKind.offline,
        title: context.l10n.connectivityOfflineTitle,
        body: context.l10n.connectivityOfflineBody,
      ),
    );
  }
}
