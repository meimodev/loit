import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/room_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/room_accounts_provider.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/widgets/loit_button.dart';
import '../../shared/widgets/loit_input.dart';
import '../../shared/widgets/loit_sheet.dart';

/// Room balance-sheet tab: the room's shared accounts, their balances, and the
/// net total (ADR 0007). Account CRUD is admin-only via the tab FAB; members add
/// transactions from the Feed tab (pool-only, room-scoped form).
class RoomBalanceTab extends ConsumerWidget {
  const RoomBalanceTab({
    super.key,
    required this.roomId,
    required this.currency,
    required this.isAdmin,
    required this.isArchived,
  });

  final String roomId;
  final String currency;
  final bool isAdmin;
  final bool isArchived;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.loitColors;
    final l = context.l10n;
    final accountsAsync = ref.watch(roomAccountsProvider(roomId));
    final balances = ref.watch(roomAccountBalancesProvider(roomId)).value ?? const {};

    return accountsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l.commonErrorWithDetail('$e'))),
      data: (all) {
        final active = all.where((a) => a.archivedAt == null).toList();
        var assets = 0.0;
        var liabilities = 0.0;
        for (final a in active) {
          final b = balances[a.id] ?? a.initialBalance;
          if (b >= 0) {
            assets += b;
          } else {
            liabilities += b;
          }
        }
        final net = assets + liabilities;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
              LoitSpacing.s4, LoitSpacing.s2, LoitSpacing.s4, 96),
          children: [
            _SummaryCard(
              net: net,
              assets: assets,
              liabilities: liabilities,
              currency: currency,
            ),
            const SizedBox(height: LoitSpacing.s4),
            Text(l.roomBalanceAccountsLabel,
                style:
                    LoitTypography.bodyS.copyWith(color: c.contentSecondary)),
            const SizedBox(height: LoitSpacing.s2),
            if (active.isEmpty)
              _Empty(
                  title: l.roomAccountsEmptyTitle,
                  body: l.roomAccountsEmptyBody)
            else
              for (final a in active)
                _AccountRow(
                  account: a,
                  balance: balances[a.id] ?? a.initialBalance,
                  currency: currency,
                  onTap: isAdmin && !isArchived
                      ? () => showRoomAccountForm(context, ref,
                          roomId: roomId, currency: currency, existing: a)
                      : null,
                ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.net,
    required this.assets,
    required this.liabilities,
    required this.currency,
  });

  final double net;
  final double assets;
  final double liabilities;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(LoitSpacing.s4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.roomBalanceNet,
              style: LoitTypography.bodyS.copyWith(color: c.contentSecondary)),
          const SizedBox(height: 4),
          Text(formatMoney(net, currency),
              style: LoitTypography.displayM.copyWith(
                  color: net < 0 ? c.danger : c.contentPrimary,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: LoitSpacing.s3),
          Row(
            children: [
              Expanded(
                  child: _Stat(
                      label: l.roomBalanceAssets,
                      value: formatMoney(assets, currency),
                      color: c.contentPrimary)),
              Expanded(
                  child: _Stat(
                      label: l.roomBalanceLiabilities,
                      value: formatMoney(liabilities, currency),
                      color: liabilities < 0 ? c.danger : c.contentPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: LoitTypography.labelS.copyWith(color: c.contentSecondary)),
        const SizedBox(height: 2),
        Text(value,
            style: LoitTypography.bodyM
                .copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.balance,
    required this.currency,
    required this.onTap,
  });

  final Account account;
  final double balance;
  final String currency;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final isLiability = account.kind == AccountKind.liability;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            vertical: LoitSpacing.s3, horizontal: LoitSpacing.s1),
        child: Row(
          children: [
            Icon(isLiability ? Icons.trending_down : Icons.account_balance_wallet,
                size: 20, color: c.contentSecondary),
            const SizedBox(width: LoitSpacing.s3),
            Expanded(
              child: Text(account.name,
                  style: LoitTypography.bodyM
                      .copyWith(color: c.contentPrimary, fontWeight: FontWeight.w600)),
            ),
            Text(formatMoney(balance, currency),
                style: LoitTypography.bodyM.copyWith(
                    color: balance < 0 ? c.danger : c.contentPrimary,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: LoitSpacing.s6),
      child: Column(
        children: [
          Text(title,
              style: LoitTypography.bodyL.copyWith(
                  color: c.contentPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(body,
              textAlign: TextAlign.center,
              style: LoitTypography.bodyS.copyWith(color: c.contentSecondary)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Room-account create / edit / archive form (admin only).
// ---------------------------------------------------------------------------

Future<void> showRoomAccountForm(
  BuildContext context,
  WidgetRef ref, {
  required String roomId,
  required String currency,
  Account? existing,
}) {
  return showLoitSheet<void>(
    context,
    useRootNavigator: true,
    builder: (_) => _RoomAccountForm(
      roomId: roomId,
      currency: currency,
      existing: existing,
    ),
  );
}

class _RoomAccountForm extends ConsumerStatefulWidget {
  const _RoomAccountForm({
    required this.roomId,
    required this.currency,
    this.existing,
  });

  final String roomId;
  final String currency;
  final Account? existing;

  @override
  ConsumerState<_RoomAccountForm> createState() => _RoomAccountFormState();
}

class _RoomAccountFormState extends ConsumerState<_RoomAccountForm> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _balance = TextEditingController(
      text: (widget.existing != null && widget.existing!.initialBalance != 0)
          ? formatAmountInput(widget.existing!.initialBalance.abs())
          : '');
  late AccountKind _kind = widget.existing?.kind ?? AccountKind.asset;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final l = context.l10n;
    if (name.isEmpty) {
      setState(() => _error = l.roomAccountNameRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final raw = parseAmountInput(_balance.text) ?? 0;
    final initial = _kind == AccountKind.liability ? -raw.abs() : raw;
    final kindStr = _kind == AccountKind.asset ? 'asset' : 'liability';
    try {
      final svc = RoomService();
      if (widget.existing == null) {
        await svc.createRoomAccount(
          roomId: widget.roomId,
          name: name,
          kind: kindStr,
          currency: widget.currency,
          initialBalance: initial,
        );
      } else {
        await svc.updateRoomAccount(widget.existing!.id, {
          'name': name,
          'kind': kindStr,
          'initial_balance': initial,
        });
      }
      ref.invalidate(roomAccountsProvider(widget.roomId));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '$e'.contains('23505') ? l.roomAccountNameTaken : '$e';
      });
    }
  }

  Future<void> _archive() async {
    setState(() => _busy = true);
    try {
      await RoomService().archiveRoomAccount(widget.existing!.id);
      ref.invalidate(roomAccountsProvider(widget.roomId));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = context.loitColors;
    final editing = widget.existing != null;
    return LoitSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(editing ? l.roomAccountEdit : l.roomAccountAdd,
              style: LoitTypography.titleM
                  .copyWith(color: c.contentPrimary, fontWeight: FontWeight.w700)),
          const SizedBox(height: LoitSpacing.s4),
          LoitInput(
              controller: _name,
              label: l.roomAccountName,
              error: _error == l.roomAccountNameRequired ? _error : null),
          const SizedBox(height: LoitSpacing.s3),
          Row(
            children: [
              Expanded(
                  child: _KindChip(
                      label: l.roomAccountKindAsset,
                      selected: _kind == AccountKind.asset,
                      onTap: () => setState(() => _kind = AccountKind.asset))),
              const SizedBox(width: LoitSpacing.s2),
              Expanded(
                  child: _KindChip(
                      label: l.roomAccountKindLiability,
                      selected: _kind == AccountKind.liability,
                      onTap: () =>
                          setState(() => _kind = AccountKind.liability))),
            ],
          ),
          const SizedBox(height: LoitSpacing.s3),
          LoitInput(
            controller: _balance,
            label: l.roomAccountInitialBalance,
            placeholder: '0',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
            ],
            trailing: Text(widget.currency,
                style: LoitTypography.bodyS.copyWith(color: c.contentSecondary)),
          ),
          if (_error != null && _error != l.roomAccountNameRequired) ...[
            const SizedBox(height: LoitSpacing.s2),
            Text(_error!,
                style: LoitTypography.bodyS.copyWith(color: c.danger)),
          ],
          const SizedBox(height: LoitSpacing.s4),
          LoitButton.primary(
              label: l.commonSave, onPressed: _save, loading: _busy, fullWidth: true),
          if (editing) ...[
            const SizedBox(height: LoitSpacing.s2),
            LoitButton.destructive(
                label: l.roomAccountArchive,
                onPressed: _busy ? null : _archive,
                fullWidth: true),
          ],
          const SizedBox(height: LoitSpacing.s2),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip(
      {required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.contentPrimary : c.muted,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: LoitTypography.bodyS.copyWith(
                color: selected ? c.surface : c.contentSecondary,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
