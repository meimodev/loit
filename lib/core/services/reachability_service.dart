import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

import '../config/env.dart';
import '../../shared/widgets/connectivity_banner.dart'
    show offlineDebugOverrideProvider;
import 'log_service.dart';

/// Reachability gate — combines `connectivity_plus` interface state with an
/// active HEAD probe (`internet_connection_checker_plus`). The interface check
/// alone reports "online" whenever wifi/mobile is up, even on captive portals
/// or hotspots with no upstream. Write paths that trusted it would attempt
/// online inserts that hang or fail, then fall through to the offline queue —
/// producing the symptom of "queued even though I'm online".
///
/// Probe targets:
/// - Supabase project URL (verifies our own backend, not just generic internet).
/// - `https://one.one.one.one` (Cloudflare) as a fallback for cases where
///   Supabase is reachable through a private network but real internet isn't.
///
/// Non-strict mode: returns `connected` as soon as any one probe succeeds, so
/// a single slow target doesn't extend the perceived save latency.
class ReachabilityService {
  ReachabilityService._(this._checker);

  factory ReachabilityService.create() {
    final supabaseUri = Uri.tryParse(Env.supabaseUrl);
    final options = <InternetCheckOption>[
      if (supabaseUri != null && supabaseUri.host.isNotEmpty)
        InternetCheckOption(
          uri: supabaseUri,
          timeout: const Duration(seconds: 3),
          // Any non-5xx response from Supabase means the host is reachable.
          responseStatusFn: (r) => r.statusCode < 500,
        ),
      InternetCheckOption(
        uri: Uri.parse('https://one.one.one.one'),
        timeout: const Duration(seconds: 3),
      ),
    ];
    final checker = InternetConnection.createInstance(
      checkInterval: const Duration(seconds: 10),
      customCheckOptions: options,
      useDefaultOptions: false,
    );
    return ReachabilityService._(checker);
  }

  final InternetConnection _checker;

  /// Stream of reachability — `true` when at least one probe target is
  /// reachable, `false` otherwise. Emits on connectivity change and on the
  /// internal periodic check (every 10s).
  Stream<bool> get onStatusChange =>
      _checker.onStatusChange.map((s) => s == InternetStatus.connected);

  /// One-shot probe used by write paths. Fast-fails if the network interface
  /// is `none`, otherwise runs the HEAD probe with [timeout].
  Future<bool> isReachable({
    Duration timeout = const Duration(milliseconds: 1500),
  }) async {
    try {
      final interface = await Connectivity().checkConnectivity();
      if (interface.isEmpty ||
          interface.every((r) => r == ConnectivityResult.none)) {
        return false;
      }
      return await _checker.hasInternetAccess.timeout(
        timeout,
        onTimeout: () => false,
      );
    } catch (e) {
      Log.w('Reachability', 'probe failed', error: e);
      return false;
    }
  }

  void dispose() {
    // InternetConnection has no public close — its internal subscription is
    // released when the stream has no listeners. Nothing to do here.
  }
}

/// Holds the singleton ReachabilityService.
final reachabilityServiceProvider = Provider<ReachabilityService>((ref) {
  final svc = ReachabilityService.create();
  ref.onDispose(svc.dispose);
  return svc;
});

/// Stream of online state. `true` = reachable, `false` = offline. Honors
/// [offlineDebugOverrideProvider] so the dev "Simulate offline" toggle still
/// drives every consumer (banner, sync, write paths).
final reachabilityProvider = StreamProvider<bool>((ref) {
  final override = ref.watch(offlineDebugOverrideProvider);
  if (override != null) {
    return Stream.value(!override);
  }
  final svc = ref.watch(reachabilityServiceProvider);
  return svc.onStatusChange;
});
