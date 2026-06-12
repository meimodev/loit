import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/loit_categories.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/room_accounts_provider.dart';
import '../../shared/providers/room_aggregations_provider.dart';
import '../../shared/providers/room_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/providers/preferences_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/utils/locale_date_format.dart';
import '../../shared/widgets/account_picker_sheet.dart';
import '../../shared/widgets/category_picker_sheet.dart';
import '../../shared/widgets/loit_amount_text.dart';
import '../../shared/widgets/loit_animations.dart';
import '../../shared/widgets/loit_avatar.dart';
import '../../shared/widgets/loit_banner.dart';
import '../../shared/widgets/loit_category_avatar.dart';
import '../../shared/widgets/loit_group_label.dart';
import '../../shared/widgets/loit_paid_from_segment.dart';
import '../../shared/widgets/loit_receipt_image.dart';
import '../../shared/widgets/loit_sheet.dart';
import '../rooms/room_colors.dart';
import 'notes_breakdown.dart';

/// Unified, room-aware transaction detail + inline edit surface (ADR 0010).
///
/// When [roomId] is set the row is a Room-account movement and the Payer is
/// shown. Inline edit + delete share one gate: the **Payer of a synced row**
/// (`isPayer && !isUnsynced`). Rooms never queue offline, and synced personal
/// rows are always the user's own, so the single rule covers both contexts.
/// The full add-transaction edit form has been removed — this screen is the
/// complete edit surface.
class TransactionDetailScreen extends ConsumerWidget {
  const TransactionDetailScreen({
    super.key,
    required this.transactionId,
    this.roomId,
    this.txn,
  });

  final String transactionId;
  final String? roomId;

  /// Offline/unsynced personal seed row (Drift queue). Never set for rooms.
  final Txn? txn;

  bool get _isRoom => roomId != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l = context.l10n;

    AsyncValue<Txn?> resolved;
    if (txn != null) {
      resolved = AsyncData(txn);
    } else if (_isRoom) {
      resolved = ref.watch(
        roomTransactionProvider(
          RoomTxKey(roomId: roomId!, txId: transactionId),
        ),
      );
    } else {
      resolved = ref
          .watch(transactionsProvider)
          .whenData(
            (items) => items.where((e) => e.id == transactionId).firstOrNull,
          );
    }

    final me = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(title: Text(l.txDetailTitle)),
      body: resolved.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(context.l10n.commonErrorWithDetail('$e'))),
        data: (t) {
          if (t == null) return Center(child: Text(l.txDetailNotFound));
          final isUnsynced = txn != null;
          final isPayer = me != null && t.userId == me.id;
          // One gate for inline edit + delete: the Payer of a synced row.
          // Rooms never queue offline (isUnsynced always false there); synced
          // personal rows are always the user's own, so isPayer holds. A null
          // `me` (pre-auth) is by definition not the Payer → locked.
          final canEdit = isPayer && !isUnsynced;
          return _DetailBody(
            t: t,
            roomId: roomId,
            isUnsynced: isUnsynced,
            canEdit: canEdit,
          );
        },
      ),
    );
  }
}

/// Invalidate the right providers after an inline save, for both contexts.
Future<void> _afterSave(WidgetRef ref, String? roomId, String txId) async {
  if (roomId != null) {
    ref.invalidate(
      roomTransactionProvider(RoomTxKey(roomId: roomId, txId: txId)),
    );
    invalidateRoomData(ref, roomId);
  }
  ref.invalidate(accountsProvider);
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({
    required this.t,
    required this.roomId,
    required this.isUnsynced,
    required this.canEdit,
  });

  final Txn t;
  final String? roomId;
  final bool isUnsynced;
  final bool canEdit;

  bool get _isRoom => roomId != null;
  // Any row carrying an item breakdown edits amount + date via the breakdown
  // editor (single owner of amount). Gated on breakdown presence, not origin:
  // scanned, bot, or manually entered breakdowns are treated identically.
  // `aiParsed` is provenance only and never gates editing.
  bool get _hasBreakdown =>
      t.id != null &&
      !isUnsynced &&
      !t.isTransfer &&
      parseBreakdown(t.notes) != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l = context.l10n;
    final catStyle = ref.watch(categoryStyleProvider(t.category));
    final catLabel = ref.watch(
      categoryLabelProvider(
        CategoryLabelKey(key: t.category, activeRoomId: roomId),
      ),
    );
    final homeCurrency = ref
        .watch(preferencesProvider)
        .maybeWhen(data: (p) => p.currency, orElse: () => 'IDR');

    return RefreshIndicator(
      onRefresh: () async {
        if (_isRoom) {
          ref.invalidate(
            roomTransactionProvider(RoomTxKey(roomId: roomId!, txId: t.id!)),
          );
          invalidateRoomData(ref, roomId!);
        } else {
          await ref.read(transactionsProvider.notifier).refresh();
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          LoitSpacing.s5,
          LoitSpacing.s5,
          LoitSpacing.s5,
          LoitSpacing.s8,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (isUnsynced) ...[
            LoitFadeSlideIn(
              child: LoitBanner(
                kind: LoitBannerKind.warning,
                title: l.txDetailNotSynced,
                body: l.txDetailNotSyncedBody,
              ),
            ),
            const SizedBox(height: LoitSpacing.s4),
          ],
          LoitFadeSlideIn(
            delay: const Duration(milliseconds: 40),
            offset: 16,
            child: _heroCard(context, catStyle, catLabel, homeCurrency),
          ),
          if (_isRoom) ...[
            const SizedBox(height: LoitSpacing.s5),
            LoitGroupLabel(label: l.roomCreatedBy),
            _payerRow(context),
          ],
          const SizedBox(height: LoitSpacing.s5),
          LoitGroupLabel(label: l.txDetailDetails),
          // Transfers are amount-only (ADR 0010): every non-amount field stays
          // read-only.
          // Date — inline editable unless the breakdown editor owns it or this
          // is a transfer.
          if (_hasBreakdown || t.isTransfer)
            _row(
              context,
              l.txDetailDate,
              yMMMMEEEEd(context).add_jm().format(t.createdAt.toLocal()),
            )
          else
            _DateRow(t: t, roomId: roomId, canEdit: canEdit),
          _row(context, l.txDetailType, _typeName(l, t.type)),
          // From account — inline editable (read-only for transfers).
          _AccountInlineRow(
            t: t,
            roomId: roomId,
            canEdit: canEdit && !t.isTransfer,
          ),
          if (t.isTransfer && t.toAccountId != null)
            _ToAccountRow(t: t, roomId: roomId),
          if (!t.isTransfer)
            _CategoryRow(
              t: t,
              roomId: roomId,
              canEdit: canEdit,
              label: catLabel,
            ),
          _row(context, l.txDetailCurrency, t.currency),
          if (t.currency != homeCurrency &&
              t.fxSnapshot.containsKey(homeCurrency))
            _row(
              context,
              l.txDetailFxRate,
              t.fxSnapshot[homeCurrency]!.toStringAsFixed(4),
            ),
          if (t.currency != homeCurrency &&
              t.fxSnapshot.containsKey(homeCurrency))
            _row(
              context,
              l.txDetailHomeAmount,
              formatMoney(t.amountIn(homeCurrency), homeCurrency),
            ),
          // Amount — inline editable unless the breakdown editor owns it.
          if (!_hasBreakdown)
            _AmountRow(t: t, roomId: roomId, canEdit: canEdit),
          _row(context, l.txDetailSource, _sourceLabel(l, t.source)),
          // Notes / breakdown.
          ..._notesSection(context, ref, c, l),
          if (t.receiptUrl != null && t.receiptUrl!.isNotEmpty) ...[
            const SizedBox(height: LoitSpacing.s4),
            LoitGroupLabel(label: l.txDetailReceipt),
            ClipRRect(
              borderRadius: LoitRadius.brM,
              child: LoitReceiptImage(path: t.receiptUrl!),
            ),
          ],
          // canEdit already implies a synced Payer row, so it is the single
          // gate for delete too.
          if (canEdit) ...[
            const SizedBox(height: LoitSpacing.s6),
            _deleteButton(context, ref, c, l),
          ],
        ],
      ),
    );
  }

  List<Widget> _notesSection(
    BuildContext context,
    WidgetRef ref,
    LoitColors c,
    AppLocalizations l,
  ) {
    final parsed = parseBreakdown(t.notes);
    // Any breakdown-bearing row (scanned, bot, or manual) routes through the
    // breakdown editor, which self-gates its edit affordance on `canEdit` — a
    // non-Payer / unsynced viewer sees the same widget read-only.
    if (_hasBreakdown && parsed != null) {
      return [
        const SizedBox(height: LoitSpacing.s4),
        LoitGroupLabel(label: l.txDetailNotes),
        _BreakdownEditor(
          txn: t,
          roomId: roomId,
          canEdit: canEdit,
          parsed: parsed,
        ),
      ];
    }
    // No structured breakdown: plain notes, inline-editable when permitted.
    return [
      const SizedBox(height: LoitSpacing.s4),
      LoitGroupLabel(label: l.txDetailNotes),
      _NotesRow(t: t, roomId: roomId, canEdit: canEdit && !t.isTransfer),
    ];
  }

  Widget _deleteButton(
    BuildContext context,
    WidgetRef ref,
    LoitColors c,
    AppLocalizations l,
  ) {
    return LoitFadeSlideIn(
      delay: const Duration(milliseconds: 380),
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.danger,
          side: BorderSide(color: c.danger.withValues(alpha: 0.4)),
          minimumSize: const Size.fromHeight(48),
        ),
        icon: const Icon(Icons.delete_outline),
        label: Text(l.txDetailDeleteTransaction),
        onPressed: () async {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: Text(l.txDetailDeleteTitle),
              content: Text(
                _isRoom ? l.roomTxnRemoveBody : l.txDetailDeleteBody,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l.txDetailCancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: c.danger),
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l.txDetailDelete),
                ),
              ],
            ),
          );
          if (ok != true) return;
          await ref
              .read(transactionsProvider.notifier)
              .deleteTransaction(t.id!);
          await _afterSave(ref, roomId, t.id!);
          if (context.mounted) context.pop();
        },
      ),
    );
  }

  Widget _payerRow(BuildContext context) {
    final c = context.loitColors;
    final rawName = (t.payerName ?? '').trim();
    final email = (t.payerEmail ?? '').trim();
    final emailHandle = email.contains('@') ? email.split('@').first : email;
    final name = rawName.isNotEmpty
        ? rawName
        : emailHandle.isNotEmpty
        ? emailHandle
        : 'Unknown';
    final color = RoomColors.forId(name);
    return Container(
      padding: const EdgeInsets.all(LoitSpacing.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: LoitRadius.brM,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              image: loitAvatarImage(t.payerAvatarUrl),
            ),
            alignment: Alignment.center,
            child: t.payerAvatarUrl == null || t.payerAvatarUrl!.isEmpty
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: LoitSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: LoitTypography.bodyM.copyWith(
                    color: c.contentPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: LoitTypography.bodyS.copyWith(
                      color: c.contentSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _sourceLabel(AppLocalizations l, TxnSource s) {
    switch (s) {
      case TxnSource.scanned:
        return l.txDetailSourceScanned;
      case TxnSource.botImage:
        return l.txDetailSourceBotImage;
      case TxnSource.botChat:
        return l.txDetailSourceBotChat;
      case TxnSource.manual:
        return l.txDetailSourceManual;
    }
  }

  String _typeName(AppLocalizations l, String type) {
    switch (type) {
      case 'income':
        return l.txFormIncome;
      case 'transfer':
        return l.txDetailFallbackTransfer;
      default:
        return l.txFormExpense;
    }
  }

  Widget _heroCard(
    BuildContext context,
    LoitCategoryStyle catStyle,
    String catLabel,
    String homeCurrency,
  ) {
    final c = context.loitColors;
    final l = context.l10n;
    final showConverted =
        !t.isTransfer &&
        t.currency != homeCurrency &&
        t.fxSnapshot.containsKey(homeCurrency);
    return Container(
      padding: const EdgeInsets.all(LoitSpacing.s5),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: LoitRadius.brL,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (t.isTransfer)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.contentSecondary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.swap_horiz,
                    color: c.contentSecondary,
                    size: 24,
                  ),
                )
              else
                LoitCategoryAvatar(categoryKey: t.category, size: 48),
              const SizedBox(width: LoitSpacing.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(
                      builder: (_) {
                        final t0 = breakdownTitle(t.notes);
                        final fallback = t.isTransfer
                            ? l.txDetailFallbackTransfer
                            : l.txDetailTitle;
                        return Text(
                          t0.isEmpty ? fallback : t0,
                          style: LoitTypography.titleM.copyWith(
                            color: c.contentPrimary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.isTransfer ? l.txDetailFallbackTransfer : catLabel,
                      style: LoitTypography.bodyS.copyWith(
                        color: c.contentSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: LoitSpacing.s5),
          Align(
            alignment: Alignment.centerLeft,
            child: LoitScaleIn(
              from: 0.9,
              duration: LoitMotion.emphasized,
              delay: const Duration(milliseconds: 120),
              child: LoitAmountText.money(
                amount: t.isTransfer ? t.absAmount : t.amount,
                currency: t.currency,
                variant: LoitAmountVariant.hero,
                convertedAmount: showConverted
                    ? t.amountIn(homeCurrency)
                    : null,
                convertedCurrency: showConverted ? homeCurrency : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value) =>
      _StaticRow(label: label, value: value);
}

/// Read-only label/value row.
class _StaticRow extends StatelessWidget {
  const _StaticRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: LoitTypography.bodyM.copyWith(color: c.contentSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: LoitTypography.bodyM.copyWith(
                color: c.contentPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable editable row: label + value + chevron, with a busy state during
/// the write. [onTap] performs the picker + persist.
class _EditableRow extends StatelessWidget {
  const _EditableRow({
    required this.label,
    required this.value,
    required this.busy,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final String value;
  final bool busy;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    if (!enabled) return _StaticRow(label: label, value: value);
    return InkWell(
      onTap: busy ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s3),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: LoitTypography.bodyM.copyWith(color: c.contentSecondary),
              ),
            ),
            Expanded(
              child: busy
                  ? const _ValueShimmer()
                  : Text(
                      value,
                      style: LoitTypography.bodyM.copyWith(
                        color: c.contentPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
            Icon(Icons.chevron_right, size: 18, color: c.contentTertiary),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends ConsumerStatefulWidget {
  const _CategoryRow({
    required this.t,
    required this.roomId,
    required this.canEdit,
    required this.label,
  });
  final Txn t;
  final String? roomId;
  final bool canEdit;
  final String label;

  @override
  ConsumerState<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends ConsumerState<_CategoryRow> {
  bool _busy = false;

  Future<void> _edit() async {
    final picked = await pickLoitCategory(
      context,
      selectedKey: widget.t.category,
      isIncome: widget.t.isIncome,
      activeRoomId: widget.roomId,
    );
    if (picked == null || picked == widget.t.category) return;
    setState(() => _busy = true);
    try {
      await ref.read(transactionsProvider.notifier).updateTransaction(
        widget.t.id!,
        {'category': picked},
      );
      await _afterSave(ref, widget.roomId, widget.t.id!);
    } catch (e) {
      if (mounted) _snack(context, ref, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditableRow(
      label: context.l10n.txDetailCategory,
      value: widget.label,
      busy: _busy,
      enabled: widget.canEdit && widget.t.id != null,
      onTap: _edit,
    );
  }
}

class _AccountInlineRow extends ConsumerStatefulWidget {
  const _AccountInlineRow({
    required this.t,
    required this.roomId,
    required this.canEdit,
  });
  final Txn t;
  final String? roomId;
  final bool canEdit;

  @override
  ConsumerState<_AccountInlineRow> createState() => _AccountInlineRowState();
}

class _AccountInlineRowState extends ConsumerState<_AccountInlineRow> {
  bool _busy = false;

  bool get _isRoom => widget.roomId != null;

  Future<void> _writeAccount(String? picked) async {
    if (picked == null || picked == widget.t.accountId) return;
    setState(() => _busy = true);
    try {
      await ref.read(transactionsProvider.notifier).updateTransaction(
        widget.t.id!,
        {'account_id': picked},
      );
      await _afterSave(ref, widget.roomId, widget.t.id!);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    } catch (e) {
      if (mounted) _snack(context, ref, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Pick within the current funding pool. [scopeRoomId] null ⇒ personal pool.
  Future<void> _edit(String? scopeRoomId) async {
    final picked = await pickLoitAccount(
      context,
      selectedId: widget.t.accountId,
      excludeId: widget.t.toAccountId,
      roomId: scopeRoomId,
    );
    await _writeAccount(picked);
  }

  /// Switch funding source (ADR 0011): open the target pool's picker and
  /// re-point account_id. Cancelling leaves the row unchanged.
  Future<void> _switchPaidFrom(PaidFrom target) async {
    final scope = target == PaidFrom.roomPool ? widget.roomId : null;
    final picked = await pickLoitAccount(
      context,
      selectedId: widget.t.accountId,
      excludeId: widget.t.toAccountId,
      roomId: scope,
    );
    await _writeAccount(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final roomAccounts = _isRoom
        ? ref.watch(activeRoomAccountsProvider(widget.roomId!))
        : const <Account>[];
    final personal = ref.watch(accountsProvider).value ?? const <Account>[];

    // Funding source is derived from the current account leg: a room account ⇒
    // Room pool (Room-account movement); a personal account ⇒ My money
    // (Out-of-pocket room expense).
    final inRoomPool =
        roomAccounts.any((a) => a.id == widget.t.accountId);
    final mode = inRoomPool ? PaidFrom.roomPool : PaidFrom.myMoney;
    final pool = _isRoom && mode == PaidFrom.roomPool ? roomAccounts : personal;
    final acc = pool.where((a) => a.id == widget.t.accountId).firstOrNull;
    final value =
        acc?.name ??
        (widget.t.accountId == null ? l.txDetailChooseAccount : 'Unknown');

    // The "Paid from" segment appears only on editable, non-transfer room rows.
    final showPaidFrom = _isRoom && widget.canEdit && !widget.t.isTransfer;

    final accountRow = _EditableRow(
      label: l.txDetailAccount,
      value: value,
      busy: _busy,
      enabled: widget.canEdit && widget.t.id != null,
      onTap: () => _edit(mode == PaidFrom.roomPool ? widget.roomId : null),
    );

    if (!showPaidFrom) return accountRow;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s3),
          child: LoitPaidFromSegment(
            value: mode,
            poolEnabled: roomAccounts.isNotEmpty,
            onChanged: _busy ? (_) {} : (v) {
              if (v != mode) _switchPaidFrom(v);
            },
          ),
        ),
        accountRow,
      ],
    );
  }
}

/// Read-only destination leg for transfers.
class _ToAccountRow extends ConsumerWidget {
  const _ToAccountRow({required this.t, required this.roomId});
  final Txn t;
  final String? roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = roomId != null
        ? ref.watch(activeRoomAccountsProvider(roomId!))
        : (ref.watch(accountsProvider).value ?? const <Account>[]);
    final acc = accounts.where((a) => a.id == t.toAccountId).firstOrNull;
    return _StaticRow(
      label: context.l10n.txDetailToAccount,
      value: acc?.name ?? 'Unknown',
    );
  }
}

class _AmountRow extends ConsumerStatefulWidget {
  const _AmountRow({
    required this.t,
    required this.roomId,
    required this.canEdit,
  });
  final Txn t;
  final String? roomId;
  final bool canEdit;

  @override
  ConsumerState<_AmountRow> createState() => _AmountRowState();
}

class _AmountRowState extends ConsumerState<_AmountRow> {
  bool _busy = false;

  Future<void> _edit() async {
    final entered = await _promptAmount(
      context,
      currency: widget.t.currency,
      initial: widget.t.absAmount,
    );
    if (entered == null) return;
    final signed = widget.t.type == 'expense' ? -entered.abs() : entered.abs();
    if (signed == widget.t.amount) return;
    setState(() => _busy = true);
    try {
      await ref.read(transactionsProvider.notifier).updateTransaction(
        widget.t.id!,
        {'amount': signed},
      );
      await _afterSave(ref, widget.roomId, widget.t.id!);
    } catch (e) {
      if (mounted) _snack(context, ref, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.t.isIncome;
    final prefix = widget.t.isTransfer ? '' : (isIncome ? '+' : '');
    return _EditableRow(
      label: context.l10n.txFormAmount,
      value: '$prefix${formatMoney(widget.t.absAmount, widget.t.currency)}',
      busy: _busy,
      enabled: widget.canEdit && widget.t.id != null,
      onTap: _edit,
    );
  }
}

class _DateRow extends ConsumerStatefulWidget {
  const _DateRow({
    required this.t,
    required this.roomId,
    required this.canEdit,
  });
  final Txn t;
  final String? roomId;
  final bool canEdit;

  @override
  ConsumerState<_DateRow> createState() => _DateRowState();
}

class _DateRowState extends ConsumerState<_DateRow> {
  bool _busy = false;

  Future<void> _edit() async {
    final current = widget.t.createdAt.toLocal();
    final day = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (day == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (!mounted) return;
    final next = DateTime(
      day.year,
      day.month,
      day.day,
      time?.hour ?? current.hour,
      time?.minute ?? current.minute,
    );
    setState(() => _busy = true);
    try {
      await ref.read(transactionsProvider.notifier).updateTransaction(
        widget.t.id!,
        {'created_at': next.toUtc().toIso8601String()},
      );
      await _afterSave(ref, widget.roomId, widget.t.id!);
    } catch (e) {
      if (mounted) _snack(context, ref, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _EditableRow(
      label: context.l10n.txDetailDate,
      value: yMMMMEEEEd(context).add_jm().format(widget.t.createdAt.toLocal()),
      busy: _busy,
      enabled: widget.canEdit && widget.t.id != null,
      onTap: _edit,
    );
  }
}

class _NotesRow extends ConsumerStatefulWidget {
  const _NotesRow({
    required this.t,
    required this.roomId,
    required this.canEdit,
  });
  final Txn t;
  final String? roomId;
  final bool canEdit;

  @override
  ConsumerState<_NotesRow> createState() => _NotesRowState();
}

class _NotesRowState extends ConsumerState<_NotesRow> {
  bool _busy = false;

  Future<void> _edit() async {
    final entered = await _promptNotes(context, initial: widget.t.notes ?? '');
    if (entered == null || entered == (widget.t.notes ?? '')) return;
    setState(() => _busy = true);
    try {
      await ref.read(transactionsProvider.notifier).updateTransaction(
        widget.t.id!,
        {'notes': entered},
      );
      await _afterSave(ref, widget.roomId, widget.t.id!);
    } catch (e) {
      if (mounted) _snack(context, ref, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final notes = widget.t.notes ?? '';
    final canEdit = widget.canEdit && widget.t.id != null;
    return Container(
      padding: const EdgeInsets.all(LoitSpacing.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: LoitRadius.brM,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _busy
                ? const _ValueShimmer()
                : Text(
                    notes.isEmpty ? l.txDetailAddNote : notes,
                    style: LoitTypography.bodyM.copyWith(
                      color: notes.isEmpty
                          ? c.contentTertiary
                          : c.contentPrimary,
                    ),
                  ),
          ),
          if (canEdit)
            IconButton(
              tooltip: l.txDetailEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: _busy ? null : _edit,
            ),
        ],
      ),
    );
  }
}

Future<double?> _promptAmount(
  BuildContext context, {
  required String currency,
  required double initial,
}) {
  // The controller is owned by the sheet body (a StatefulWidget) so it is
  // disposed only after the route fully unmounts — disposing it eagerly in
  // `whenComplete` would race the route's exit animation, which keeps
  // rebuilding the TextField against a disposed controller.
  return showLoitSheet<double>(
    context,
    builder: (_) => _AmountSheet(currency: currency, initial: initial),
  );
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({required this.currency, required this.initial});
  final String currency;
  final double initial;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: NumberFormat('#,##0.##', 'id_ID').format(widget.initial),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() => Navigator.of(context).pop(parseAmountInput(_ctrl.text));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LoitSheet(
      title: l.txFormAmount,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixText: '${widget.currency} ',
              isDense: true,
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: LoitSpacing.s4),
          FilledButton(onPressed: _submit, child: Text(l.txFormSave)),
        ],
      ),
    );
  }
}

Future<String?> _promptNotes(BuildContext context, {required String initial}) {
  return showLoitSheet<String>(
    context,
    builder: (_) => _NotesSheet(initial: initial),
  );
}

class _NotesSheet extends StatefulWidget {
  const _NotesSheet({required this.initial});
  final String initial;

  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return LoitSheet(
      title: l.txFormNotes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _ctrl,
            autofocus: true,
            minLines: 2,
            maxLines: 5,
            decoration: const InputDecoration(isDense: true),
          ),
          const SizedBox(height: LoitSpacing.s4),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_ctrl.text.trim()),
            child: Text(l.txFormSave),
          ),
        ],
      ),
    );
  }
}

void _snack(BuildContext context, WidgetRef ref, Object e) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(context.l10n.roomUpdateFailed(e.toString()))),
  );
}

class _ValueShimmer extends StatefulWidget {
  const _ValueShimmer();
  @override
  State<_ValueShimmer> createState() => _ValueShimmerState();
}

class _ValueShimmerState extends State<_ValueShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return SizedBox(
      height: 16,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = _ctrl.value;
          return ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(
                  width: 120,
                  height: 16,
                  color: c.muted.withValues(alpha: 0.6),
                ),
                Positioned(
                  left: -60 + 180 * t,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.transparent,
                          c.surface.withValues(alpha: 0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BreakdownEditor extends ConsumerStatefulWidget {
  const _BreakdownEditor({
    required this.txn,
    required this.parsed,
    required this.roomId,
    required this.canEdit,
  });

  final Txn txn;
  final NotesBreakdown parsed;
  final String? roomId;
  final bool canEdit;

  @override
  ConsumerState<_BreakdownEditor> createState() => _BreakdownEditorState();
}

class _BreakdownEditorState extends ConsumerState<_BreakdownEditor> {
  bool _editing = false;
  bool _saving = false;
  late TextEditingController _merchantCtl;
  late TextEditingController _totalCtl;
  late List<_ItemDraft> _items;

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  void _hydrate() {
    final p = widget.parsed;
    _merchantCtl = TextEditingController(text: p.merchant);
    final total = p.total ?? widget.txn.absAmount;
    _totalCtl = TextEditingController(text: _fmt(total));
    _items = [
      for (final it in p.items)
        _ItemDraft(
          name: TextEditingController(text: it.name),
          qty: TextEditingController(text: it.qty != null ? _fmt(it.qty!) : ''),
          unit: TextEditingController(
            text: it.unitPrice != null ? _fmt(it.unitPrice!) : '',
          ),
          total: TextEditingController(
            text: it.totalPrice != null ? _fmt(it.totalPrice!) : '',
          ),
        ),
    ];
  }

  static final NumberFormat _f = NumberFormat('#,##0.##', 'id_ID');
  String _fmt(double v) => _f.format(v);

  double? _parseNum(String s) => parseAmountInput(s);

  @override
  void dispose() {
    _merchantCtl.dispose();
    _totalCtl.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  void _toggleEdit(bool on) {
    setState(() {
      _merchantCtl.dispose();
      _totalCtl.dispose();
      for (final i in _items) {
        i.dispose();
      }
      _hydrate();
      _editing = on;
    });
  }

  void _addItem() => setState(() => _items.add(_ItemDraft.empty()));

  void _removeItem(int i) {
    setState(() {
      _items[i].dispose();
      _items.removeAt(i);
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final l = context.l10n;
    try {
      final items = <NotesBreakdownItem>[
        for (final d in _items)
          NotesBreakdownItem(
            name: d.name.text.trim(),
            qty: _parseNum(d.qty.text),
            unitPrice: _parseNum(d.unit.text),
            totalPrice: _parseNum(d.total.text),
          ),
      ];
      final totalParsed = _parseNum(_totalCtl.text);
      final breakdown = NotesBreakdown(
        merchant: _merchantCtl.text.trim(),
        items: items,
        total: totalParsed,
        currency: widget.txn.currency,
      );
      final notes = formatBreakdown(breakdown);
      final itemsPayload = [
        for (final it in items)
          if (it.name.isNotEmpty ||
              it.qty != null ||
              it.unitPrice != null ||
              it.totalPrice != null)
            {
              'name': it.name,
              if (it.qty != null) 'qty': it.qty,
              if (it.unitPrice != null) 'unit_price': it.unitPrice,
              if (it.totalPrice != null) 'total_price': it.totalPrice,
            },
      ];
      final payload = <String, dynamic>{'notes': notes, 'items': itemsPayload};
      if (totalParsed != null) {
        payload['amount'] = widget.txn.type == 'expense'
            ? -totalParsed.abs()
            : totalParsed.abs();
      }
      await ref
          .read(transactionsProvider.notifier)
          .updateTransaction(widget.txn.id!, payload);
      await _afterSave(ref, widget.roomId, widget.txn.id!);
      if (!mounted) return;
      setState(() {
        _editing = false;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.txFormSaveFailed(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(LoitSpacing.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: LoitRadius.brM,
        border: Border.all(color: c.borderSubtle),
      ),
      // No AnimatedSwitcher here: toggling edit mode disposes + recreates the
      // field controllers, and a retained outgoing subtree would rebuild
      // against disposed controllers (assert). AnimatedSize keeps a smooth
      // height transition without retaining a stale child.
      child: AnimatedSize(
        duration: LoitMotion.emphasized,
        curve: LoitMotion.easeOutQuart,
        alignment: Alignment.topCenter,
        child: _editing ? _buildEdit(context, c, l) : _buildView(context, c, l),
      ),
    );
  }

  Widget _buildView(BuildContext context, LoitColors c, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.parsed.merchant.isEmpty ? '—' : widget.parsed.merchant,
                style: LoitTypography.bodyL.copyWith(
                  color: c.contentPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (widget.canEdit)
              TextButton.icon(
                onPressed: () => _toggleEdit(true),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(l.txDetailEdit),
              ),
          ],
        ),
        const SizedBox(height: LoitSpacing.s3),
        for (var i = 0; i < widget.parsed.items.length; i++) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.parsed.items[i].name.isEmpty
                        ? '—'
                        : widget.parsed.items[i].name,
                    style: LoitTypography.bodyM.copyWith(
                      color: c.contentPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: LoitSpacing.s3),
                Text(
                  _itemRight(widget.parsed.items[i]),
                  style: LoitTypography.bodyS.copyWith(
                    color: c.contentSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (i != widget.parsed.items.length - 1)
            Divider(height: 1, color: c.borderSubtle),
        ],
        if (widget.parsed.total != null) ...[
          const SizedBox(height: LoitSpacing.s3),
          Divider(height: 1, color: c.borderSubtle),
          Padding(
            padding: const EdgeInsets.only(top: LoitSpacing.s3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.txDetailTotal,
                    style: LoitTypography.bodyM.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _money(widget.parsed.total!),
                  style: LoitTypography.bodyM.copyWith(
                    color: c.contentPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _money(double v) => formatMoney(v, widget.txn.currency);

  String _itemRight(NotesBreakdownItem it) {
    final parts = <String>[];
    if (it.qty != null && it.unitPrice != null) {
      parts.add('${_fmt(it.qty!)} × ${_money(it.unitPrice!)}');
    } else if (it.qty != null) {
      parts.add('${_fmt(it.qty!)} ×');
    } else if (it.unitPrice != null) {
      parts.add('× ${_money(it.unitPrice!)}');
    }
    if (it.totalPrice != null) {
      parts.add('= ${_money(it.totalPrice!)}');
    }
    return parts.join(' ');
  }

  Widget _buildEdit(BuildContext context, LoitColors c, AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _merchantCtl,
          decoration: InputDecoration(
            labelText: l.txFormMerchant,
            isDense: true,
          ),
        ),
        const SizedBox(height: LoitSpacing.s3),
        Text(
          l.txFormItemBreakdown,
          style: LoitTypography.labelL.copyWith(color: c.contentSecondary),
        ),
        const SizedBox(height: LoitSpacing.s2),
        for (var i = 0; i < _items.length; i++) ...[
          _itemEditor(i, c, l),
          if (i != _items.length - 1) const SizedBox(height: LoitSpacing.s3),
        ],
        const SizedBox(height: LoitSpacing.s3),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _addItem,
            icon: const Icon(Icons.add, size: 16),
            label: Text(l.txFormAddItem),
          ),
        ),
        const SizedBox(height: LoitSpacing.s3),
        TextField(
          controller: _totalCtl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [ThousandsInputFormatter()],
          decoration: InputDecoration(
            labelText: l.txFormTotal,
            prefixText: '${currencySymbol(widget.txn.currency)} ',
            isDense: true,
          ),
        ),
        const SizedBox(height: LoitSpacing.s4),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _saving ? null : () => _toggleEdit(false),
                child: Text(l.txDetailCancel),
              ),
            ),
            const SizedBox(width: LoitSpacing.s3),
            Expanded(
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l.txFormSave),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _itemEditor(int i, LoitColors c, AppLocalizations l) {
    final d = _items[i];
    final sym = currencySymbol(widget.txn.currency);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LoitSpacing.s4,
        vertical: LoitSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: c.canvas,
        borderRadius: LoitRadius.brS,
        border: Border.all(color: c.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: d.name,
                  decoration: InputDecoration(
                    labelText: l.txFormItemName,
                    isDense: true,
                  ),
                ),
                const SizedBox(height: LoitSpacing.s3),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: d.qty,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [ThousandsInputFormatter()],
                        decoration: InputDecoration(
                          labelText: l.txFormQty,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: LoitSpacing.s2),
                    Expanded(
                      child: TextField(
                        controller: d.unit,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [ThousandsInputFormatter()],
                        decoration: InputDecoration(
                          labelText: l.txFormUnitPrice,
                          prefixText: '$sym ',
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: LoitSpacing.s3),
                TextField(
                  controller: d.total,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [ThousandsInputFormatter()],
                  decoration: InputDecoration(
                    labelText: l.txFormTotal,
                    prefixText: '$sym ',
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: LoitSpacing.s2),
          IconButton(
            tooltip: l.txFormRemove,
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => _removeItem(i),
          ),
        ],
      ),
    );
  }
}

class _ItemDraft {
  _ItemDraft({
    required this.name,
    required this.qty,
    required this.unit,
    required this.total,
  });

  factory _ItemDraft.empty() => _ItemDraft(
    name: TextEditingController(),
    qty: TextEditingController(),
    unit: TextEditingController(),
    total: TextEditingController(),
  );

  final TextEditingController name;
  final TextEditingController qty;
  final TextEditingController unit;
  final TextEditingController total;

  void dispose() {
    name.dispose();
    qty.dispose();
    unit.dispose();
    total.dispose();
  }
}
