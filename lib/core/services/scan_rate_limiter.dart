import 'package:drift/drift.dart';

import 'log_service.dart';
import 'offline_database.dart';

/// Step 4 — local rate-limit guard. Rolling 60-second window, hard cap 10.
/// Abuse protection only; not a normal user UX path.
class ScanRateLimiter {
  static const _tag = 'ScanRateLimiter';
  static const int windowMs = 60 * 1000;
  static const int maxInWindow = 10;

  final OfflineDatabase _db;

  ScanRateLimiter(this._db);

  /// Returns true if the call is allowed. On allow, records the timestamp.
  Future<bool> tryConsume() async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final cutoff = now - windowMs;

    // Prune old rows opportunistically — keeps the table tiny.
    await (_db.delete(_db.scanRateLog)..where((t) => t.callMs.isSmallerThanValue(cutoff)))
        .go();

    final recent = await (_db.select(_db.scanRateLog)
          ..where((t) => t.callMs.isBiggerOrEqualValue(cutoff)))
        .get();

    if (recent.length >= maxInWindow) {
      Log.w(_tag, 'Rate-limited: ${recent.length} calls in last 60s');
      return false;
    }

    await _db.into(_db.scanRateLog).insert(
          ScanRateLogCompanion.insert(callMs: now),
        );
    return true;
  }
}
