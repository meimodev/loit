import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/room_service.dart';

// Service singleton
final roomServiceProvider = Provider<RoomService>((ref) => RoomService());

// My rooms list — invalidate after create/join/leave
final myRoomsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(roomServiceProvider).listMyRooms();
});

// Single room detail
final roomDetailProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, roomId) async {
  return ref.watch(roomServiceProvider).getRoom(roomId);
});

// Room budgets
final roomBudgetsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, roomId) async {
  return ref.watch(roomServiceProvider).getRoomBudgets(roomId);
});

// Pending invites for current user
final pendingInvitesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(roomServiceProvider).getPendingInvites();
});

// Real-time room feed (transactions in a room)
final roomFeedProvider = FutureProvider.family<List<Map<String, dynamic>>, String>(
    (ref, roomId) async {
  final supabase = Supabase.instance.client;

  final initial = await supabase
      .from('transactions')
      .select('*, users(name, avatar_url)')
      .eq('room_id', roomId)
      .order('created_at', ascending: false)
      .limit(50);

  // Subscribe to realtime
  final channel = supabase
      .channel('room:$roomId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'transactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: roomId,
        ),
        callback: (_) {
          // On any change, invalidate to re-fetch with joined user data
          ref.invalidateSelf();
        },
      )
      .subscribe();

  ref.onDispose(() => channel.unsubscribe());

  return List<Map<String, dynamic>>.from(initial);
});

// Room member count — derived from detail
final roomMemberCountProvider =
    Provider.family<int, String>((ref, roomId) {
  final detail = ref.watch(roomDetailProvider(roomId));
  return detail.maybeWhen(
    data: (room) {
      final members = room['room_members'];
      if (members is List) return members.length;
      return 0;
    },
    orElse: () => 0,
  );
});
