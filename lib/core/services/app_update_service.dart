import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';

import 'log_service.dart';

/// Performs the actual app update for the Update gate (ADR-0015). The server
/// gate decides *state*; Play performs the *update*. Uses the in-app update
/// flow when a newer build is live and propagated to this device, and falls
/// back to launching the store URL otherwise (covers the propagation gap where
/// the gate says Blocked but Play hasn't served the new APK here yet).
class AppUpdateService {
  const AppUpdateService();

  /// Whether this device has a **remedy** — an update Play can install right now
  /// (CONTEXT.md → Remedy). Below-floor clients hard-block only when one exists;
  /// otherwise they land in Stranded (ADR-0030). Play availability is per-device
  /// (staged rollout, region, Play Store version, on-device cache), so this is
  /// the only oracle that answers it. Failure or `unknown` => no remedy: fail
  /// toward usable, legal because a breaking migration rejects old writes rather
  /// than misreading them.
  Future<bool> hasRemedy() async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      return info.updateAvailability == UpdateAvailability.updateAvailable ||
          info.updateAvailability ==
              UpdateAvailability.developerTriggeredUpdateInProgress;
    } catch (e) {
      Log.w('AppUpdate', 'remedy check failed, treating as Stranded', error: e);
      return false;
    }
  }

  /// [immediate] true for Blocked (Play's full-screen blocking flow); false for
  /// Recommended/Optional (flexible background download).
  Future<void> performUpdate({
    required bool immediate,
    required String storeUrl,
  }) async {
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (immediate && info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
          return;
        }
        if (!immediate && info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
          return;
        }
      }
    } catch (e) {
      Log.w('AppUpdate', 'in-app update flow failed, falling back to store',
          error: e);
    }
    await _launchStore(storeUrl);
  }

  Future<void> _launchStore(String storeUrl) async {
    // Prefer the Play app via market:// (skips the browser bounce); fall back
    // to the https URL if the market scheme can't be handled.
    final market = _toMarketUri(storeUrl);
    if (market != null &&
        await launchUrl(market, mode: LaunchMode.externalApplication)) {
      return;
    }
    final web = Uri.tryParse(storeUrl);
    if (web != null) {
      await launchUrl(web, mode: LaunchMode.externalApplication);
    }
  }

  Uri? _toMarketUri(String storeUrl) {
    final uri = Uri.tryParse(storeUrl);
    final id = uri?.queryParameters['id'];
    if (id == null || id.isEmpty) return null;
    return Uri.parse('market://details?id=$id');
  }
}

final appUpdateService = AppUpdateService();
