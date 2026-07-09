import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Id of the room whose detail screen is currently mounted, or null.
///
/// The shell's Rooms nav tab tints to this room's color so you can tell a room
/// is open even after switching to another tab — `StatefulShellRoute.indexedStack`
/// keeps the room detail alive in the background, so a path-based signal (which
/// only reflects the active branch) can't see it. The room detail screen sets
/// this on mount and clears it on dispose.
class OpenRoomIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void open(String id) => state = id;

  /// Clear only if [id] is still the open room — a newer room detail pushed on
  /// top owns the state, so its predecessor's dispose must not stomp it.
  void close(String id) {
    if (state == id) state = null;
  }
}

final openRoomIdProvider =
    NotifierProvider<OpenRoomIdNotifier, String?>(OpenRoomIdNotifier.new);
