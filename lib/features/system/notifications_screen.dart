import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/notifications_provider.dart';
import '../../shared/widgets/loit_empty_state.dart';

/// Notifications feed (system K · `screens-system.jsx` Notifications artboard).
/// Backed by `public.notifications` table; realtime insert subscribed via provider.
class SystemNotificationsScreen extends ConsumerWidget {
  const SystemNotificationsScreen({super.key});

  String _formatWhen(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'now';
    if (d.inMinutes < 60) return '${d.inMinutes} min ago';
    if (d.inHours < 24) return '${d.inHours} h ago';
    if (d.inDays < 7) return '${d.inDays} d ago';
    return '${(d.inDays / 7).floor()} w ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l = context.l10n;
    final async = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        title: Text(l.notifFeedTitle),
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if ((async.value ?? const []).any((n) => n.isUnread))
            TextButton(
              onPressed: () =>
                  ref.read(notificationsProvider.notifier).markAllRead(),
              child: Text(
                'Mark all read',
                style: LoitTypography.bodyM.copyWith(
                  color: c.brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: LoitEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: "You're all caught up",
                  body:
                      'New activity in your rooms, budgets, and receipts will land here.',
                ),
              ),
            );
          }
          final unread = items.where((n) => n.isUnread).toList();
          final earlier = items.where((n) => !n.isUnread).toList();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 32),
              children: [
                if (unread.isNotEmpty) ...[
                  _SectionLabel('New · ${unread.length}'),
                  _NotifGroup(items: unread, formatWhen: _formatWhen),
                ],
                if (earlier.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const _SectionLabel('Earlier'),
                  _NotifGroup(items: earlier, formatWhen: _formatWhen),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: Text(
        label.toUpperCase(),
        style: LoitTypography.labelS.copyWith(
          color: c.contentSecondary,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NotifGroup extends ConsumerWidget {
  const _NotifGroup({required this.items, required this.formatWhen});
  final List<NotificationItem> items;
  final String Function(DateTime) formatWhen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.borderSubtle),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Dismissible(
              key: ValueKey(items[i].id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => ref
                  .read(notificationsProvider.notifier)
                  .dismiss(items[i].id),
              background: Container(
                color: c.dangerSurface,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.delete_outline, color: c.danger),
              ),
              child: InkWell(
                onTap: () async {
                  final n = items[i];
                  await ref.read(notificationsProvider.notifier).markRead(n.id);
                  if (n.deepLink != null && context.mounted) {
                    context.push(n.deepLink!);
                  }
                },
                child: _NotifTile(item: items[i], formatWhen: formatWhen),
              ),
            ),
            if (i != items.length - 1)
              Divider(height: 1, thickness: 1, color: c.borderSubtle),
          ],
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  const _NotifTile({required this.item, required this.formatWhen});
  final NotificationItem item;
  final String Function(DateTime) formatWhen;

  (Color, IconData) _styleFor(BuildContext context) {
    final c = context.loitColors;
    return switch (item.kind) {
      NotificationKind.budgetAlert => (c.danger, Icons.error_outline),
      NotificationKind.roomActivity ||
      NotificationKind.invite =>
        (const Color(0xFF7A4FBF), Icons.group_outlined),
      NotificationKind.receipt => (c.brand, Icons.receipt_long_outlined),
      NotificationKind.subscription => (c.brand, Icons.workspace_premium),
      NotificationKind.info => (c.info, Icons.info_outline),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final (color, icon) = _styleFor(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
      color: c.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 12,
            child: Center(
              child: item.isUnread
                  ? Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: c.brand,
                        shape: BoxShape.circle,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: LoitTypography.bodyM.copyWith(
                    color: c.contentPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if ((item.body ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.body!,
                    style: LoitTypography.bodyS.copyWith(
                      color: c.contentSecondary,
                      height: 17 / 13,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  formatWhen(item.createdAt),
                  style: LoitTypography.bodyS.copyWith(
                    color: c.contentTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
