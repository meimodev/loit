import 'package:supabase_flutter/supabase_flutter.dart';
import 'log_service.dart';

class RoomService {
  static const _tag = 'RoomService';

  final SupabaseClient _client;

  RoomService([SupabaseClient? client])
      : _client = client ?? Supabase.instance.client;

  String get _uid => _client.auth.currentUser!.id;

  Future<List<Map<String, dynamic>>> listMyRooms() async {
    final memberRows = await _client
        .from('room_members')
        .select('room_id')
        .eq('user_id', _uid);

    final roomIds =
        memberRows.map((r) => r['room_id'] as String).toList();
    if (roomIds.isEmpty) return [];

    return _client
        .from('rooms')
        .select('*, room_members(user_id, role)')
        .inFilter('id', roomIds)
        .order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> getRoom(String roomId) async {
    return _client
        .from('rooms')
        .select('*, room_members(user_id, role, users(name, avatar_url))')
        .eq('id', roomId)
        .single();
  }

  Future<Map<String, dynamic>> createRoom({
    required String name,
    String? description,
    String baseCurrency = 'IDR',
  }) async {
    Log.i(_tag, 'Creating room: $name');
    final row = await _client
        .from('rooms')
        .insert({
          'name': name,
          'description': description,
          'base_currency': baseCurrency,
          'created_by': _uid,
        })
        .select()
        .single();
    Log.i(_tag, 'Room created: ${row['id']}');
    return row;
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> updates) async {
    await _client.from('rooms').update(updates).eq('id', roomId);
  }

  Future<void> archiveRoom(String roomId) async {
    await _client.from('rooms').update({
      'is_archived': true,
      'archived_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', roomId);
  }

  Future<void> leaveRoom(String roomId) async {
    await _client
        .from('room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', _uid);
  }

  Future<void> kickMember(String roomId, String userId) async {
    await _client
        .from('room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', userId);
  }

  Future<String?> acceptInvite(String token) async {
    Log.i(_tag, 'Accepting invite');
    final result = await _client.rpc(
      'accept_room_invite',
      params: {'p_invite_token': token},
    );
    Log.i(_tag, 'Invite accepted: roomId=$result');
    return result as String?;
  }

  Future<List<Map<String, dynamic>>> getPendingInvites() async {
    return _client
        .from('room_invites')
        .select('*, rooms(name)')
        .eq('invited_user_id', _uid)
        .eq('status', 'pending')
        .gt('expires_at', DateTime.now().toUtc().toIso8601String());
  }

  Future<Map<String, dynamic>> createInvite({
    required String roomId,
    required String invitedEmail,
  }) async {
    final resp = await _client.functions.invoke(
      'create-room-invite',
      body: {'room_id': roomId, 'invited_email': invitedEmail},
    );
    if (resp.status >= 400) {
      throw Exception(resp.data?.toString() ?? 'Failed to create invite');
    }
    return resp.data as Map<String, dynamic>;
  }

  Future<void> notifyRoomTransaction({
    required String roomId,
    String? title,
    required num amount,
    required String currency,
    bool isIncome = false,
  }) async {
    await _client.functions.invoke(
      'room-transaction-notify',
      body: {
        'room_id': roomId,
        'actor_id': _uid,
        'title': title,
        'amount': amount,
        'currency': currency,
        'type': isIncome ? 'income' : 'expense',
      },
    );
  }

  // Room budgets
  Future<List<Map<String, dynamic>>> getRoomBudgets(String roomId) async {
    return _client
        .from('room_budgets')
        .select()
        .eq('room_id', roomId)
        .order('created_at');
  }

  Future<void> upsertRoomBudget({
    required String roomId,
    required String category,
    required num budgetLimit,
    required String currency,
  }) async {
    await _client.from('room_budgets').upsert(
      {
        'room_id': roomId,
        'category': category,
        'budget_limit': budgetLimit,
        'currency': currency,
        'created_by': _uid,
      },
      onConflict: 'room_id,category',
    );
  }
}
