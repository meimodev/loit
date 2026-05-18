import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/analytics_service.dart';
import '../../core/services/log_service.dart';
import '../../core/services/scanner_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_motion.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../l10n/l10n_x.dart';
import '../../shared/providers/accounts_provider.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/providers/services_providers.dart';
import '../../shared/providers/transactions_provider.dart';
import '../../shared/providers/user_categories_provider.dart';
import '../paywall/feature_gate.dart';
import '../transactions/notes_breakdown.dart';
import '../../shared/widgets/loit_amount_text.dart';
import '../../shared/widgets/loit_animations.dart';
import '../../shared/widgets/loit_button.dart';
import '../../shared/widgets/loit_confidence_banner.dart';
import '../../shared/widgets/loit_countdown_button.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/utils/locale_date_format.dart';

/// Step 7+8 — confidence-driven review of a scanner output.
///
/// Receives pre-parsed scan data + confidence + reconciliation flags via
/// the `extra` map of GoRouter. Lays out merchant/total/account/category/
/// items, banners reconciliation warnings inline, and on high confidence
/// drives a 3-second auto-confirm countdown (respecting the user's
/// auto-confirm preference in Settings).
class ScanReviewScreen extends ConsumerStatefulWidget {
  const ScanReviewScreen({super.key, required this.scan});

  final ScanReviewData scan;

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class ScanReviewData {
  final Map<String, dynamic> parsed;
  final String imagePath;
  final String? roomId;
  final double confidence;
  final bool reconciliationWarning;
  final bool totalComputed;
  final bool autoConfirmEnabled;

  const ScanReviewData({
    required this.parsed,
    required this.imagePath,
    required this.confidence,
    this.roomId,
    this.reconciliationWarning = false,
    this.totalComputed = false,
    this.autoConfirmEnabled = true,
  });
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  bool _itemsExpanded = false;
  bool _saving = false;

  ConfidenceBucket get _bucket => bucketFor(widget.scan.confidence);

  String? _accountIdFromName(String? name, List<Account> accounts) {
    if (name == null) return null;
    for (final a in accounts) {
      if (a.archivedAt != null) continue;
      if (a.name.toLowerCase() == name.toLowerCase()) return a.id;
    }
    return null;
  }

  String? _firstActiveAccountId(List<Account> accounts) {
    for (final a in accounts) {
      if (a.archivedAt == null) return a.id;
    }
    return null;
  }

  String _categoryName(List<UserCategory> userCats, String key) {
    for (final c in userCats) {
      if (c.key == key) return c.name;
    }
    return key;
  }

  Future<void> _save({required bool auto}) async {
    if (_saving) return;
    setState(() => _saving = true);

    final p = widget.scan.parsed;
    final accounts = ref.read(accountsProvider).value ?? const [];
    final accountId = _accountIdFromName(p['account'] as String?, accounts) ??
        _firstActiveAccountId(accounts);
    if (accountId == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.scanNoAccount)),
      );
      _editManually();
      return;
    }

    try {
      // `merchant` column was dropped (migration 20260501000002). Scanner
      // output is mapped into `notes` via `formatBreakdown` so the detail
      // screen can round-trip merchant + items the same way as the manual
      // form's items-mode notes.
      final merchant = (p['merchant'] as String?)?.trim() ?? '';
      final itemsRaw = (p['items'] as List?) ?? const [];
      final breakdownItems = <NotesBreakdownItem>[
        for (final it in itemsRaw.whereType<Map>())
          NotesBreakdownItem(
            name: (it['name'] as String?) ?? '',
            qty: (it['qty'] as num?)?.toDouble(),
            unitPrice: (it['unit_price'] as num?)?.toDouble(),
            totalPrice: (it['total_price'] as num?)?.toDouble(),
          ),
      ];
      final currency = (p['currency'] as String?) ?? 'IDR';
      final notesText = (merchant.isEmpty && breakdownItems.isEmpty)
          ? null
          : formatBreakdown(NotesBreakdown(
              merchant: merchant,
              items: breakdownItems,
              total: (p['total'] as num?)?.toDouble(),
              currency: currency,
            )).trim();
      final insertedId =
          await ref.read(transactionsProvider.notifier).addTransaction({
        'type': p['type'] ?? 'expense',
        'amount': p['total'],
        'currency': p['currency'] ?? 'IDR',
        if (notesText != null && notesText.isNotEmpty) 'notes': notesText,
        'category': p['category'] ?? 'other',
        'account_id': accountId,
        'ai_parsed': true,
        // `transactions` table has no `date` column — use `created_at` to
        // match the manual entry path. Sending `date` 400s the insert and
        // traps the row in the offline queue forever.
        'created_at': DateTime.now().toUtc().toIso8601String(),
        if (widget.scan.roomId != null) 'room_id': widget.scan.roomId,
        if (p['items'] != null) 'items': p['items'],
      });

      // Receipt upload: mirror manual form path (transaction_form_screen).
      // `addTransaction` strips `_*` keys, so the image has to be uploaded
      // explicitly here after the parent insert resolves. Offline path
      // returns null id — skip upload, user retains image on device.
      if (insertedId != null) {
        final tier = ref.read(userProfileProvider).value?.tier;
        final canStore = FeatureFlags.forTier(tier ?? 'free').receiptStorage;
        if (canStore) {
          try {
            final bytes = await File(widget.scan.imagePath).readAsBytes();
            final uid = Supabase.instance.client.auth.currentUser?.id;
            if (uid != null) {
              await ref.read(receiptServiceProvider).uploadReceipt(
                    userId: uid,
                    transactionId: insertedId,
                    imageBytes: bytes,
                  );
            }
          } catch (e) {
            Log.w('ScanReview', 'Receipt upload failed', error: e);
          }
        }
      }

      // Step 9 — atomic quota increment. Skip when offline; rate limiter +
      // monthly limit catch abuse. Realtime channel on `users` picks up the
      // new count and invalidates `userProfileProvider`. Use reachability
      // gate (interface + probe) so we don't waste an RPC on captive-portal
      // networks the transaction itself just queued for.
      final reachable =
          await ref.read(reachabilityServiceProvider).isReachable();
      if (reachable) {
        try {
          final supabase = Supabase.instance.client;
          final userId = supabase.auth.currentUser?.id;
          if (userId != null) {
            await supabase.rpc('reset_scan_quota_if_new_month', params: {
              'p_user_id': userId,
            });
            // 1<<30 = "no enforcement here, just increment". Client already
            // gated against `scanQuota` before calling Claude — RPC records
            // use so analytics + realtime tier-flip stay in sync.
            await supabase.rpc('increment_scan_quota', params: {
              'p_user_id': userId,
              'p_limit': 1 << 30,
            });
          }
        } catch (e) {
          Log.w('ScanReview', 'Quota RPC failed (will retry on sync): $e');
        }
      } else {
        Log.i('ScanReview', 'Offline — skipping quota RPC');
      }

      await Analytics.scanCompleted(aiSuccess: true);
      await Analytics.scanSaved();
      if (auto) {
        Log.i('ScanReview', 'Auto-confirmed (high confidence)');
      }
      if (!mounted) return;
      context.go('/transactions');
    } catch (e, st) {
      Log.e('ScanReview', 'Save failed', error: e, stack: st);
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.scanSaveFailed)),
      );
    }
  }

  void _editManually() {
    final p = Map<String, dynamic>.from(widget.scan.parsed);
    p['_ai_parsed'] = true;
    p['_image_path'] = widget.scan.imagePath;
    if (widget.scan.roomId != null) p['_room_id'] = widget.scan.roomId;
    context.pushReplacement('/transactions/new', extra: p);
  }

  void _cancel() {
    Analytics.scanCancelled();
    // Skip the scanner screen on back — it'd otherwise re-mount in its
    // "Reading document" / capture phase, which is jarring after the user
    // explicitly dismissed the review. Land on the transactions list, same
    // destination as a successful save.
    context.go('/transactions');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final p = widget.scan.parsed;

    final total = (p['total'] as num?)?.toDouble() ?? 0;
    final currency = (p['currency'] as String?) ?? 'IDR';
    final merchant = (p['merchant'] as String?) ?? l.scanUnknownMerchant;
    final category = (p['category'] as String?) ?? 'other';
    final account = (p['account'] as String?) ?? '—';
    final items = (p['items'] as List?) ?? const [];

    final userCats = ref.watch(userCategoriesProvider).value ?? const [];
    final catName = _categoryName(userCats, category);

    final showCountdown = _bucket == ConfidenceBucket.high &&
        widget.scan.autoConfirmEnabled &&
        !widget.scan.reconciliationWarning &&
        !widget.scan.totalComputed;

    return PopScope(
      // Android system back / swipe gesture would Navigator.pop() back to
      // the scanner screen mid-processing. Intercept and route to the same
      // destination as the AppBar close button.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _cancel();
      },
      child: Scaffold(
        backgroundColor: c.canvas,
        appBar: AppBar(
          backgroundColor: c.canvas,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancel,
          ),
          title: Text(l.scanReviewTitle),
        ),
      body: SafeArea(
        child: Column(
          children: [
            LoitFadeSlideIn(
              offset: -8,
              child: LoitConfidenceBanner(
                bucket: _bucket,
                highLabel: l.scanConfidenceHigh,
                lowLabel: l.scanConfidenceLow,
              ),
            ),
            if (widget.scan.reconciliationWarning ||
                widget.scan.totalComputed)
              LoitFadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(
                    LoitSpacing.s4,
                    LoitSpacing.s2,
                    LoitSpacing.s4,
                    LoitSpacing.s2,
                  ),
                  padding: const EdgeInsets.all(LoitSpacing.s3),
                  decoration: BoxDecoration(
                    color: c.warningSurface,
                    borderRadius: BorderRadius.circular(LoitRadius.s),
                  ),
                  child: Text(
                    widget.scan.totalComputed
                        ? l.scanTotalComputed
                        : l.scanReconcileMismatch,
                    style: LoitTypography.bodyM.copyWith(color: c.warning),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: LoitSpacing.s4,
                  vertical: LoitSpacing.s3,
                ),
                children: [
                  LoitFadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: Text(
                      merchant,
                      style: LoitTypography.titleL,
                    ),
                  ),
                  const SizedBox(height: LoitSpacing.s2),
                  LoitFadeSlideIn(
                    delay: const Duration(milliseconds: 170),
                    child: Text(
                      yMMMd(context).format(DateTime.now()),
                      style: LoitTypography.bodyM.copyWith(
                        color: c.contentSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: LoitSpacing.s5),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: LoitScaleIn(
                      from: 0.88,
                      duration: LoitMotion.emphasized,
                      delay: const Duration(milliseconds: 220),
                      child: LoitAmountText.money(
                        amount: total,
                        currency: currency,
                        variant: LoitAmountVariant.hero,
                      ),
                    ),
                  ),
                  const SizedBox(height: LoitSpacing.s6),
                  LoitFadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: _row(l.scanFieldAccount, account, c),
                  ),
                  const SizedBox(height: LoitSpacing.s3),
                  LoitFadeSlideIn(
                    delay: const Duration(milliseconds: 360),
                    child: _row(l.scanFieldCategory, catName, c),
                  ),
                  if (items.isNotEmpty) ...[
                    const SizedBox(height: LoitSpacing.s4),
                    LoitFadeSlideIn(
                      delay: const Duration(milliseconds: 420),
                      child: InkWell(
                        onTap: () =>
                            setState(() => _itemsExpanded = !_itemsExpanded),
                        child: Row(
                          children: [
                            AnimatedRotation(
                              turns: _itemsExpanded ? 0.5 : 0,
                              duration: LoitMotion.short,
                              curve: LoitMotion.easeOutQuart,
                              child: Icon(
                                Icons.expand_more,
                                color: c.contentSecondary,
                              ),
                            ),
                            const SizedBox(width: LoitSpacing.s2),
                            Text(
                              l.scanItemsCount(items.length),
                              style: LoitTypography.labelL,
                            ),
                          ],
                        ),
                      ),
                    ),
                    LoitAnimatedReveal(
                      visible: _itemsExpanded,
                      child: Column(
                        children: [
                          for (final it in items.whereType<Map>())
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: LoitSpacing.s2,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      (it['name'] as String?) ?? '—',
                                      style: LoitTypography.bodyM,
                                    ),
                                  ),
                                  Text(
                                    _formatItemRight(it, currency),
                                    style: LoitTypography.bodyM,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(LoitSpacing.s4),
              child: LoitFadeSlideIn(
                delay: const Duration(milliseconds: 460),
                offset: 16,
                child: Column(
                  children: [
                    if (showCountdown)
                      LoitCountdownButton(
                        confirmLabel: l.scanSaveNow,
                        cancelLabel: l.scanCancelAutoSave,
                        labelFor: (s) => l.scanAutoConfirmIn(s),
                        onConfirm: () => _save(auto: true),
                      )
                    else
                      LoitButton.primary(
                        label: l.scanSaveNow,
                        onPressed: _saving ? null : () => _save(auto: false),
                      ),
                    const SizedBox(height: LoitSpacing.s2),
                    LoitButton.ghost(
                      label: l.scanEditDetails,
                      onPressed: _saving ? null : _editManually,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _row(String label, String value, LoitColors c) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: LoitSpacing.s4,
        vertical: LoitSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(LoitRadius.m),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: LoitTypography.bodyM.copyWith(color: c.contentSecondary),
          ),
          const Spacer(),
          Text(value, style: LoitTypography.labelL),
        ],
      ),
    );
  }
}

String _formatItemRight(Map it, String currency) {
  final qty = (it['qty'] as num?)?.toDouble();
  final unit = (it['unit_price'] as num?)?.toDouble();
  final total = (it['total_price'] as num?)?.toDouble();
  final hasQty = qty != null && qty > 0;
  final hasUnit = unit != null && unit > 0;
  final hasTotal = total != null && total > 0;
  final parts = <String>[];
  if (hasQty && hasUnit) {
    parts.add('${formatAmountInput(qty)} × ${formatMoney(unit, currency)}');
  } else if (hasUnit) {
    parts.add('× ${formatMoney(unit, currency)}');
  } else if (hasQty) {
    parts.add('${formatAmountInput(qty)} ×');
  }
  if (hasTotal) parts.add('= ${formatMoney(total, currency)}');
  if (parts.isEmpty) return '—';
  return parts.join(' ');
}

/// Wraps a scan image preview shown above the review form. Kept separate so
/// callers can choose whether to render it (room scans hide it to save space).
class ScanReviewImagePreview extends StatelessWidget {
  const ScanReviewImagePreview({super.key, required this.path});
  final String path;

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(LoitRadius.m),
      child: Image.file(file, fit: BoxFit.cover, height: 120),
    );
  }
}
