import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/loit_categories.dart';
import 'auth_providers.dart';

class UserCategory {
  final String id;
  final String key;
  final String name;
  final String kind;
  final String? iconName;
  final String? tint;
  final int sortOrder;

  const UserCategory({
    required this.id,
    required this.key,
    required this.name,
    required this.kind,
    this.iconName,
    this.tint,
    required this.sortOrder,
  });

  bool get isIncome => kind == 'income';
  bool get isExpense => kind == 'expense';

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

  factory UserCategory.fromRow(Map<String, dynamic> r) => UserCategory(
        id: r['id'] as String,
        key: r['key'] as String,
        name: r['name'] as String,
        kind: r['kind'] as String,
        iconName: r['icon_name'] as String?,
        tint: r['tint'] as String?,
        sortOrder: (r['sort_order'] as int?) ?? 0,
      );
}

class UserCategoriesNotifier extends AsyncNotifier<List<UserCategory>> {
  @override
  Future<List<UserCategory>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
    final rows = await Supabase.instance.client
        .from('user_categories')
        .select()
        .eq('user_id', user.id)
        .order('sort_order', ascending: true);
    return (rows as List)
        .map((r) => UserCategory.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> create({
    required String key,
    required String name,
    required String kind,
    String? iconName,
    String? tint,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw StateError('Not signed in');
    final cats = state.value ?? [];
    final maxSort = cats.isEmpty
        ? 0
        : cats.map((c) => c.sortOrder).reduce((a, b) => a > b ? a : b);
    final payload = {
      'user_id': user.id,
      'key': key,
      'name': name,
      'kind': kind,
      'icon_name': iconName,
      'tint': tint,
      'sort_order': maxSort + 1,
    };
    await Supabase.instance.client.from('user_categories').insert(payload);
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
    final payload = <String, dynamic>{};
    if (name != null) payload['name'] = name;
    if (key != null) payload['key'] = key;
    if (kind != null) payload['kind'] = kind;
    if (iconName != null) payload['icon_name'] = iconName;
    if (tint != null) payload['tint'] = tint;
    payload['updated_at'] = DateTime.now().toUtc().toIso8601String();
    await Supabase.instance.client
        .from('user_categories')
        .update(payload)
        .eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    await Supabase.instance.client
        .from('user_categories')
        .delete()
        .eq('id', id);
    ref.invalidateSelf();
  }

  Future<void> reorder(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await Supabase.instance.client
          .from('user_categories')
          .update({'sort_order': i})
          .eq('id', orderedIds[i]);
    }
    ref.invalidateSelf();
  }
}

final userCategoriesProvider = AsyncNotifierProvider<UserCategoriesNotifier,
    List<UserCategory>>(UserCategoriesNotifier.new);

final expenseCategoriesProvider = Provider<List<UserCategory>>((ref) {
  final cats = ref.watch(userCategoriesProvider).value ?? [];
  return cats.where((c) => c.isExpense).toList();
});

final incomeCategoriesProvider = Provider<List<UserCategory>>((ref) {
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
