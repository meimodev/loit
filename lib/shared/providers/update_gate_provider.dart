import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/log_service.dart';

/// The client's standing against the [UpdateGate] (CONTEXT.md → Update state).
/// Exactly one of four, derived by comparing the device version to the
/// thresholds. See ADR-0015.
enum UpdateState {
  /// `version >= latest` — no prompt.
  current,

  /// `recommended <= version < latest` — prompt once, then passive marker.
  optional,

  /// `min <= version < recommended` — dismissible prompt every launch.
  recommended,

  /// `version < min` — non-dismissible overlay; the app is unusable until
  /// updated. Breaking releases only.
  blocked,
}

/// The server-side authority deciding whether a running client build is too old
/// (CONTEXT.md → Update gate). Three semantic-version thresholds plus the Play
/// fallback URL. Keyed on the semver string, never the build number.
class UpdateGate {
  const UpdateGate({
    required this.minVersion,
    required this.recommendedVersion,
    required this.latestVersion,
    required this.storeUrl,
  });

  final String minVersion;
  final String recommendedVersion;
  final String latestVersion;
  final String storeUrl;

  static const _open = UpdateGate(
    minVersion: '0.0.0',
    recommendedVersion: '0.0.0',
    latestVersion: '0.0.0',
    storeUrl: 'https://play.google.com/store/apps/details?id=id.activid.loit',
  );

  factory UpdateGate.fromJson(Map<String, dynamic> json) => UpdateGate(
        minVersion: (json['min_version'] as String?) ?? '0.0.0',
        recommendedVersion:
            (json['recommended_version'] as String?) ?? '0.0.0',
        latestVersion: (json['latest_version'] as String?) ?? '0.0.0',
        storeUrl: (json['store_url'] as String?) ?? _open.storeUrl,
      );

  Map<String, dynamic> toJson() => {
        'min_version': minVersion,
        'recommended_version': recommendedVersion,
        'latest_version': latestVersion,
        'store_url': storeUrl,
      };

  /// Resolve the [UpdateState] for [deviceVersion] against these thresholds.
  UpdateState stateFor(String deviceVersion) {
    if (_compare(deviceVersion, minVersion) < 0) return UpdateState.blocked;
    if (_compare(deviceVersion, recommendedVersion) < 0) {
      return UpdateState.recommended;
    }
    if (_compare(deviceVersion, latestVersion) < 0) return UpdateState.optional;
    return UpdateState.current;
  }
}

/// Result of evaluating the gate this session: the resolved [state], the
/// effective [gate], and the [deviceVersion] it was judged against.
class UpdateGateStatus {
  const UpdateGateStatus({
    required this.state,
    required this.gate,
    required this.deviceVersion,
  });

  final UpdateState state;
  final UpdateGate gate;
  final String deviceVersion;
}

const _kGateCacheKey = 'update_gate_cache_v1';

/// SharedPreferences key holding the `latest_version` for which the Optional
/// prompt was already shown. Optional nags exactly once per release.
const updateOptionalDismissedKey = 'update_optional_dismissed_version';

/// Fetches the [UpdateGate], caches it, and resolves the [UpdateStatus] for the
/// running build. Fail-open: a failed fetch falls back to the last-known cached
/// gate (so a Blocked user can't dodge by going offline); a never-fetched
/// client resolves to [UpdateState.current]. Re-fetched on resume via
/// `ref.invalidate`.
final updateGateProvider = FutureProvider<UpdateGateStatus>((ref) async {
  final deviceVersion = (await PackageInfo.fromPlatform()).version;
  final prefs = await SharedPreferences.getInstance();

  UpdateGate gate;
  try {
    final row = await Supabase.instance.client
        .from('app_release_gate')
        .select('min_version, recommended_version, latest_version, store_url')
        .eq('id', 1)
        .single();
    gate = UpdateGate.fromJson(row);
    await prefs.setString(_kGateCacheKey, jsonEncode(gate.toJson()));
  } catch (e) {
    // Fail open: never block on a fetch failure. Reuse the last-known gate so a
    // previously-Blocked user stays Blocked offline; an unseen gate => open.
    final cached = prefs.getString(_kGateCacheKey);
    if (cached != null) {
      try {
        gate = UpdateGate.fromJson(
            jsonDecode(cached) as Map<String, dynamic>);
        Log.w('UpdateGate', 'fetch failed, using cached gate', error: e);
      } catch (_) {
        gate = UpdateGate._open;
      }
    } else {
      gate = UpdateGate._open;
      Log.w('UpdateGate', 'fetch failed, no cache, open', error: e);
    }
  }

  return UpdateGateStatus(
    state: gate.stateFor(deviceVersion),
    gate: gate,
    deviceVersion: deviceVersion,
  );
});

/// Compare two dotted version strings numerically (`1.0.9 < 1.0.10`). Any
/// pre-release / build suffix (`-breaking`, `+42`) is stripped before parsing;
/// the gate compares bare semver only. Returns <0, 0, or >0.
int _compare(String a, String b) {
  final pa = _segments(a);
  final pb = _segments(b);
  final n = pa.length > pb.length ? pa.length : pb.length;
  for (var i = 0; i < n; i++) {
    final va = i < pa.length ? pa[i] : 0;
    final vb = i < pb.length ? pb[i] : 0;
    if (va != vb) return va < vb ? -1 : 1;
  }
  return 0;
}

List<int> _segments(String v) {
  final core = v.split(RegExp(r'[-+]')).first;
  return core
      .split('.')
      .map((s) => int.tryParse(s.trim()) ?? 0)
      .toList(growable: false);
}
