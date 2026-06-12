import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/loit_categories.dart';
import '../../core/config/categories.dart';
import 'auth_providers.dart';
import 'preferences_provider.dart';

enum CategorySource { personal, room }

class UserCategory {
  final String id;
  final String key;
  final String name;
  final String kind;
  final String? iconName;
  final String? tint;
  final int sortOrder;
  final CategorySource source;
  final String? roomId;
  final String? roomName;
  final String? roomCreatedBy;

  const UserCategory({
    required this.id,
    required this.key,
    required this.name,
    required this.kind,
    this.iconName,
    this.tint,
    required this.sortOrder,
    this.source = CategorySource.personal,
    this.roomId,
    this.roomName,
    this.roomCreatedBy,
  });

  bool get isIncome => kind == 'income';
  bool get isExpense => kind == 'expense';
  bool get isPersonal => source == CategorySource.personal;
  bool get isRoom => source == CategorySource.room;

  bool canManageBy(String? userId) {
    if (isPersonal) return true;
    return userId != null && roomCreatedBy == userId;
  }

  /// Display label given an active room context. Personal labels are
  /// always raw. Room labels are raw inside their owning room and
  /// `<Room name> <Category name>` elsewhere.
  String displayLabel({String? activeRoomId}) {
    if (isPersonal) return name;
    if (roomId != null && roomId == activeRoomId) return name;
    final r = (roomName ?? '').trim();
    return r.isEmpty ? name : '$r $name';
  }

  Color get tintColor {
    if (tint == null) return LoitCategories.defaultOther.tint;
    final hex = tint!.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  IconData get iconData =>
      LoitCategories.iconFromName(iconName) ?? Icons.receipt_long;

  LoitCategoryStyle get style => LoitCategoryStyle(
        tint: tintColor,
        icon: iconData,
        label: name,
      );

  factory UserCategory.fromPersonalRow(Map<String, dynamic> r) => UserCategory(
        id: r['id'] as String,
        key: r['key'] as String,
        name: r['name'] as String,
        kind: r['kind'] as String,
        iconName: r['icon_name'] as String?,
        tint: r['tint'] as String?,
        sortOrder: (r['sort_order'] as int?) ?? 0,
        source: CategorySource.personal,
      );

  factory UserCategory.fromRoomRow(Map<String, dynamic> r) {
    final room = r['rooms'] as Map<String, dynamic>?;
    return UserCategory(
      id: r['id'] as String,
      key: r['key'] as String,
      name: r['name'] as String,
      kind: r['kind'] as String,
      iconName: r['icon_name'] as String?,
      tint: r['tint'] as String?,
      sortOrder: (r['sort_order'] as int?) ?? 0,
      source: CategorySource.room,
      roomId: r['room_id'] as String?,
      roomName: room?['name'] as String?,
      roomCreatedBy: room?['created_by'] as String?,
    );
  }

  /// Backwards-compat alias used in older call sites.
  factory UserCategory.fromRow(Map<String, dynamic> r) =>
      UserCategory.fromPersonalRow(r);
}

class UserCategoriesNotifier extends AsyncNotifier<List<UserCategory>> {
  @override
  Future<List<UserCategory>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
    final client = Supabase.instance.client;
    final personal = await client
        .from('user_categories')
        .select()
        .eq('user_id', user.id)
        .order('sort_order', ascending: true);
    final roomRows = await client
        .from('room_categories')
        .select('*, rooms(name, created_by)')
        .order('sort_order', ascending: true);
    final out = <UserCategory>[
      for (final r in (personal as List))
        UserCategory.fromPersonalRow(r as Map<String, dynamic>),
      for (final r in (roomRows as List))
        UserCategory.fromRoomRow(r as Map<String, dynamic>),
    ];
    return out;
  }

  Future<void> create({
    required String key,
    required String name,
    required String kind,
    String? iconName,
    String? tint,
    String? roomId,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not signed in');
    final cats = state.value ?? [];
    final scoped = roomId == null
        ? cats.where((c) => c.isPersonal)
        : cats.where((c) => c.roomId == roomId);
    final maxSort = scoped.isEmpty
        ? 0
        : scoped.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b);
    final client = Supabase.instance.client;
    if (roomId == null) {
      await client.from('user_categories').insert({
        'user_id': user.id,
        'key': key,
        'name': name,
        'kind': kind,
        'icon_name': iconName,
        'tint': tint,
        'sort_order': maxSort + 1,
      });
    } else {
      await client.from('room_categories').insert({
        'room_id': roomId,
        'key': key,
        'name': name,
        'kind': kind,
        'icon_name': iconName,
        'tint': tint,
        'sort_order': maxSort + 1,
        'created_by': user.id,
      });
    }
    ref.invalidateSelf();
  }

  Future<void> updateCategory({
    required String id,
    String? name,
    String? key,
    String? kind,
    String? iconName,
    String? tint,
  }) async {
    final cats = state.value ?? [];
    final cat = cats.where((c) => c.id == id).firstOrNull;
    final user = ref.read(currentUserProvider);
    if (cat != null && cat.isRoom && !cat.canManageBy(user?.id)) {
      throw StateError('Only the room creator can edit room categories');
    }
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (key != null) payload['key'] = key;
    if (kind != null) payload['kind'] = kind;
    if (iconName != null) payload['icon_name'] = iconName;
    if (tint != null) payload['tint'] = tint;
    payload['updated_at'] = DateTime.now().toUtc().toIso8601String();
    final table = (cat?.isRoom ?? false) ? 'room_categories' : 'user_categories';
    await Supabase.instance.client
        .from(table)
        .update(payload)
        .eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final cats = state.value ?? [];
    final cat = cats.where((c) => c.id == id).firstOrNull;
    final user = ref.read(currentUserProvider);
    if (cat != null && cat.isRoom && !cat.canManageBy(user?.id)) {
      throw StateError('Only the room creator can delete room categories');
    }
    final table = (cat?.isRoom ?? false) ? 'room_categories' : 'user_categories';
    await Supabase.instance.client.from(table).delete().eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> reorder(List<String> orderedIds) async {
    final cats = state.value ?? [];
    final byId = {for (final c in cats) c.id: c};
    final client = Supabase.instance.client;
    for (var i = 0; i < orderedIds.length; i++) {
      final cat = byId[orderedIds[i]];
      final table = (cat?.isRoom ?? false)
          ? 'room_categories'
          : 'user_categories';
      await client
          .from(table)
          .update({'sort_order': i})
          .eq('id', orderedIds[i]);
    }
    ref.invalidateSelf();
  }
}

final userCategoriesProvider = AsyncNotifierProvider<UserCategoriesNotifier,
    List<UserCategory>>(UserCategoriesNotifier.new);

/// Pending category deletes (id set). UI filters these out so the row
/// disappears immediately on swipe; a timer commits the Supabase delete
/// after the snackbar window unless the user undoes.
class PendingCategoryDeletes extends Notifier<Set<String>> {
  final Map<String, Timer> _timers = {};

  @override
  Set<String> build() {
    ref.onDispose(() {
      for (final t in _timers.values) {
        t.cancel();
      }
      _timers.clear();
    });
    return const {};
  }

  void schedule({
    required String categoryId,
    Duration delay = const Duration(seconds: 5),
  }) {
    _timers[categoryId]?.cancel();
    state = {...state, categoryId};
    _timers[categoryId] = Timer(delay, () async {
      _timers.remove(categoryId);
      if (!state.contains(categoryId)) return;
      try {
        await ref.read(userCategoriesProvider.notifier).delete(categoryId);
      } finally {
        state = {...state}..remove(categoryId);
      }
    });
  }

  void undo(String categoryId) {
    _timers[categoryId]?.cancel();
    _timers.remove(categoryId);
    if (!state.contains(categoryId)) return;
    state = {...state}..remove(categoryId);
  }
}

final pendingCategoryDeletesProvider =
    NotifierProvider<PendingCategoryDeletes, Set<String>>(
  PendingCategoryDeletes.new,
);

/// Personal-only expense categories (used by personal flows).
final expenseCategoriesProvider = Provider<List<UserCategory>>((ref) {
  final cats = ref.watch(userCategoriesProvider).value ?? [];
  return cats.where((c) => c.isExpense && c.isPersonal).toList();
});

/// Personal-only income categories.
final incomeCategoriesProvider = Provider<List<UserCategory>>((ref) {
  final cats = ref.watch(userCategoriesProvider).value ?? [];
  return cats.where((c) => c.isIncome && c.isPersonal).toList();
});

/// Personal + inherited room categories filtered to expense.
final allExpenseCategoriesProvider = Provider<List<UserCategory>>((ref) {
  final cats = ref.watch(userCategoriesProvider).value ?? [];
  return cats.where((c) => c.isExpense).toList();
});

/// Personal + inherited room categories filtered to income.
final allIncomeCategoriesProvider = Provider<List<UserCategory>>((ref) {
  final cats = ref.watch(userCategoriesProvider).value ?? [];
  return cats.where((c) => c.isIncome).toList();
});

final categoryStylesMapProvider =
    Provider<Map<String, LoitCategoryStyle>>((ref) {
  final cats = ref.watch(userCategoriesProvider).value ?? [];
  final map = <String, LoitCategoryStyle>{};
  for (final cat in cats) {
    map[cat.key] = cat.style;
  }
  if (!map.containsKey('other')) {
    map['other'] = LoitCategories.defaultOther;
  }
  return map;
});

final categoryStyleProvider =
    Provider.family<LoitCategoryStyle, String?>((ref, key) {
  final map = ref.watch(categoryStylesMapProvider);
  if (key == null) return LoitCategories.defaultOther;
  return map[key] ?? LoitCategories.defaultOther;
});

final categoryKindProvider = Provider.family<String?, String>((ref, key) {
  final cats = ref.watch(userCategoriesProvider).value ?? [];
  return cats.where((c) => c.key == key).firstOrNull?.kind;
});

/// Room-aware label lookup for a category key. When the active room
/// matches the category's owning room, returns the bare name; otherwise
/// prefixes with `<Room name> ` so the user can disambiguate.
class CategoryLabelKey {
  const CategoryLabelKey({required this.key, this.activeRoomId});
  final String? key;
  final String? activeRoomId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryLabelKey &&
          other.key == key &&
          other.activeRoomId == activeRoomId;

  @override
  int get hashCode => Object.hash(key, activeRoomId);
}

final categoryLabelProvider =
    Provider.family<String, CategoryLabelKey>((ref, k) {
  if (k.key == null) return _localizeDefault(ref, 'other');
  final cats = ref.watch(userCategoriesProvider).value ?? const <UserCategory>[];
  final cat = cats.where((c) => c.key == k.key).firstOrNull;
  if (cat == null) {
    return _localizeDefault(ref, k.key!);
  }
  // Room catch-all categories (ADR 0009) store an English name but display a
  // locale-aware label, resolved by key suffix. Outside their owning room they
  // keep the same `<Room name> ` prefix as any other room category.
  if (cat.isRoom) {
    final suffix = cat.key.endsWith(':income_other')
        ? 'income_other'
        : cat.key.endsWith(':other')
            ? 'other'
            : null;
    if (suffix != null) {
      final base = _catchAllLabel(ref, suffix);
      if (cat.roomId == k.activeRoomId) return base;
      final r = (cat.roomName ?? '').trim();
      return r.isEmpty ? base : '$r $base';
    }
  }
  return cat.displayLabel(activeRoomId: k.activeRoomId);
});

/// Locale-aware label for a room catch-all key suffix (`other` /
/// `income_other`). Mirrors the `id` strings in [_idLabels] and the English
/// defaults; kept here because this provider has no [BuildContext] for l10n.
String _catchAllLabel(Ref ref, String suffix) {
  final isId = ref.watch(localePrefProvider)?.languageCode == 'id';
  return switch (suffix) {
    'income_other' => isId ? 'Pemasukan lain' : 'Income other',
    _ => isId ? 'Lainnya' : 'Other',
  };
}

String _localizeDefault(Ref ref, String key) {
  final locale = ref.watch(localePrefProvider);
  if (locale?.languageCode == 'id' && CategoryDefaults.isDefault(key)) {
    return _idLabels[key] ?? key;
  }
  return ref.watch(categoryStyleProvider(key)).label;
}

const _idLabels = <String, String>{
  'dining': 'Makanan',
  'groceries': 'Belanja',
  'transport': 'Transportasi',
  'shopping': 'Belanja',
  'entertainment': 'Hiburan',
  'utilities': 'Utilitas',
  'health': 'Kesehatan',
  'travel': 'Perjalanan',
  'other': 'Lainnya',
  'income_salary': 'Gaji',
  'income_bonus': 'Bonus',
  'income_freelance': 'Freelance',
  'income_investment': 'Investasi',
  'income_gift': 'Hadiah',
  'income_refund': 'Pengembalian',
  'income_other': 'Pemasukan lain',
};
