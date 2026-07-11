import 'package:supabase_flutter/supabase_flutter.dart';
import 'log_service.dart';
import 'reachability_service.dart';

/// One church chart-of-accounts seed row for [RoomService.seedChurchCategories]
/// (ADR 0021). `iconName`/`tint` are null for user-added free-text categories.
typedef ChurchSeedCategory = ({String name, String? iconName, String? tint});

class RoomService {
  static const _tag = 'RoomService';

  final SupabaseClient _client;

  /// Offline gate injected by the provider (reachability probe + dev override).
  /// Defaults to always-online so a bare `RoomService()` (tests) still works;
  /// in that mode the [runOnline] wrap degrades to network-error mapping only.
  final Future<bool> Function() _isOffline;

  RoomService([SupabaseClient? client, Future<bool> Function()? isOffline])
      : _client = client ?? Supabase.instance.client,
        _isOffline = isOffline ?? (() async => false);

  String get _uid => _client.auth.currentUser!.id;

  /// Routes a room mutation through the online-only gate (ADR 0014): pre-write
  /// reachability probe, then network-class errors mapped to
  /// [OnlineOnlyActionException]. Reads deliberately skip this — they surface
  /// the raw error so the UI can classify offline vs server failure.
  Future<T> _online<T>(Future<T> Function() action) =>
      runOnline(_isOffline, action);

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
        .select(
            '*, room_members(user_id, role, users:room_member_profile(name, email, avatar_url))')
        .eq('id', roomId)
        .single();
  }

  Future<Map<String, dynamic>> createRoom({
    required String name,
    String? description,
    String baseCurrency = 'IDR',
    String orgType = 'general',
    Map<String, dynamic>? orgConfig,
  }) async {
    Log.i(_tag, 'Creating room: $name (org_type=$orgType)');
    // NOTE (ADR 0014): the one non-idempotent room write. A lost response after
    // the insert lands may, on retry, create a duplicate room — accepted limit.
    final row = await _online(() => _client
        .from('rooms')
        .insert({
          'name': name,
          'description': description,
          'base_currency': baseCurrency,
          'created_by': _uid,
          'org_type': orgType,
          if (orgConfig != null) 'org_config': orgConfig,
        })
        .select()
        .single());
    Log.i(_tag, 'Room created: ${row['id']}');
    return row;
  }

  /// Seeds a church room's chart of accounts (ADR 0021) as ordinary
  /// `room_categories` rows in a single batch insert. [penerimaan] become
  /// income rows, [pengeluaran] expense rows, each carrying its `icon_name` /
  /// `tint` when set; the two catch-all rows are already
  /// seeded by the DB trigger. Keys obey `room_categories_key_format`. Best
  /// effort: a failure leaves the room with only the catch-all (still
  /// usable) — the creator can add categories via the normal editor.
  Future<void> seedChurchCategories({
    required String roomId,
    required List<ChurchSeedCategory> penerimaan,
    required List<ChurchSeedCategory> pengeluaran,
  }) async {
    final rows = <Map<String, dynamic>>[];
    var sort = 0;
    void add(ChurchSeedCategory cat, String kind) {
      final slug = categorySlug(cat.name, kind);
      if (slug.isEmpty) return;
      rows.add({
        'room_id': roomId,
        'key': 'room:$roomId:$slug',
        'name': cat.name,
        'kind': kind,
        // null for user-added free-text categories → default style.
        if (cat.iconName != null) 'icon_name': cat.iconName,
        if (cat.tint != null) 'tint': cat.tint,
        'sort_order': sort++,
        'created_by': _uid,
      });
    }

    for (final c in penerimaan) {
      add(c, 'income');
    }
    for (final c in pengeluaran) {
      add(c, 'expense');
    }
    if (rows.isEmpty) return;
    await _online(() =>
        _client.from('room_categories').upsert(rows, onConflict: 'room_id,key'));
  }

  /// Mirrors the SQL `room_category_slug(name, kind)`: income prefix +
  /// lowercased name with non-alphanumerics collapsed to `_`. Output must
  /// satisfy `room_categories_key_format` once prefixed with `room:<id>:`.
  static String categorySlug(String name, String kind) {
    final base = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'(^_+|_+$)'), '');
    return kind == 'income' ? 'income_$base' : base;
  }

  /// Seeds the three **Default room accounts** ("Tunai", "Bank 1", "Bank 2")
  /// into a newly created Room in a single batch insert. Best-effort: a
  /// failure leaves the room with zero accounts (still usable — the admin can
  /// add accounts manually). "Tunai" is inserted first so it becomes the
  /// **first active Room account** and the default funding source for AI
  /// Captures routed to this room.
  Future<void> seedDefaultAccounts({
    required String roomId,
    required String currency,
  }) async {
    const names = ['Tunai', 'Bank 1', 'Bank 2'];
    final now = DateTime.now().toUtc().toIso8601String();
    final rows = <Map<String, dynamic>>[
      for (final name in names)
        {
          'room_id': roomId,
          'name': name,
          'kind': 'asset',
          'currency': currency,
          'initial_balance': 0,
          'client_updated_at': now,
        },
    ];
    await _online(() => _client.from('accounts').insert(rows));
  }

  Future<void> updateRoom(String roomId, Map<String, dynamic> updates) async {
    await _online(
        () => _client.from('rooms').update(updates).eq('id', roomId));
  }

  Future<void> archiveRoom(String roomId) async {
    await _online(() => _client.from('rooms').update({
          'is_archived': true,
          'archived_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', roomId));
  }

  Future<void> leaveRoom(String roomId) async {
    await _online(() => _client
        .from('room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', _uid));
  }

  Future<void> kickMember(String roomId, String userId) async {
    await _online(() => _client
        .from('room_members')
        .delete()
        .eq('room_id', roomId)
        .eq('user_id', userId));
  }

  Future<String?> acceptInvite(String token) async {
    Log.i(_tag, 'Accepting invite');
    final result = await _online(() => _client.rpc(
          'accept_room_invite',
          params: {'p_invite_token': token},
        ));
    Log.i(_tag, 'Invite accepted: roomId=$result');
    return result as String?;
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
  Future<Map<String, dynamic>?> getRoomBudget({
    required String roomId,
    required String budgetId,
  }) async {
    return _client
        .from('room_budgets')
        .select()
        .eq('id', budgetId)
        .eq('room_id', roomId)
        .maybeSingle();
  }

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
    String period = 'monthly',
    int resetDay = 1,
    int? customDays,
  }) async {
    await _online(() => _client.from('room_budgets').upsert(
          {
            'room_id': roomId,
            'category': category,
            'budget_limit': budgetLimit,
            'currency': currency,
            'period': period,
            'reset_day': resetDay,
            'custom_days': period == 'custom' ? customDays : null,
            'created_by': _uid,
          },
          onConflict: 'room_id,category',
        ));
  }

  Future<void> updateRoomBudget({
    required String budgetId,
    required String roomId,
    required String category,
    required num budgetLimit,
    required String currency,
    String period = 'monthly',
    int resetDay = 1,
    int? customDays,
  }) async {
    await _online(() => _client.from('room_budgets').update({
          'category': category,
          'budget_limit': budgetLimit,
          'currency': currency,
          'period': period,
          'reset_day': resetDay,
          'custom_days': period == 'custom' ? customDays : null,
        }).eq('id', budgetId).eq('room_id', roomId));
  }

  Future<void> deleteRoomBudget({
    required String budgetId,
    required String roomId,
  }) async {
    await _online(() => _client
        .from('room_budgets')
        .delete()
        .eq('id', budgetId)
        .eq('room_id', roomId));
  }

  // Room accounts — the room's shared balance sheet (ADR 0007).
  // Currency is fixed to the room's base_currency by the caller; admin-only
  // writes are enforced by RLS.
  Future<Map<String, dynamic>> createRoomAccount({
    required String roomId,
    required String name,
    required String kind, // 'asset' | 'debt'
    required String currency,
    double initialBalance = 0,
    String? icon,
    String? color,
  }) async {
    return _online(() => _client
        .from('accounts')
        .insert({
          'room_id': roomId,
          'name': name,
          'kind': kind,
          'currency': currency,
          'initial_balance': initialBalance,
          if (icon != null) 'icon': icon,
          if (color != null) 'color': color,
          'client_updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .select()
        .single());
  }

  Future<void> updateRoomAccount(
    String accountId,
    Map<String, dynamic> updates,
  ) async {
    updates['client_updated_at'] = DateTime.now().toUtc().toIso8601String();
    await _online(
        () => _client.from('accounts').update(updates).eq('id', accountId));
  }

  /// Archive-only — room accounts are never hard-deleted (a mirror transfer is
  /// one row shared with a member's personal ledger). See ADR 0007.
  Future<void> archiveRoomAccount(String accountId) async {
    await _online(() => _client.from('accounts').update({
          'archived_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', accountId));
  }
}
