import 'package:shared_preferences/shared_preferences.dart';

/// Per-device memory for one-time feature-discovery **coach marks** (CONTEXT.md
/// "Feature discovery (coach marks)"). Deliberately local, not a server flag
/// like `has_seen_rooms_intro` — a hint reappearing after a reinstall is fine.
class CoachMarkStore {
  const CoachMarkStore._();

  /// Center capture FAB spotlight (scan + voice).
  static const captureFab = 'seen_capture_coach';

  /// Bottom-nav Transactions → Rooms spotlights (fires after [captureFab]).
  static const navCoach = 'seen_nav_coach';

  /// Room detail Account → Budget tab spotlights.
  static const roomTabs = 'seen_room_tabs_coach';

  static Future<bool> wasSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  static Future<void> markSeen(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }
}
