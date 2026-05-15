import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/services/log_service.dart';
import '../../core/theme/loit_colors.dart';
import '../../core/theme/loit_radius.dart';
import '../../core/theme/loit_spacing.dart';
import '../../core/theme/loit_typography.dart';
import '../../shared/providers/auth_providers.dart';
import '../../shared/utils/amount_input.dart';
import '../../shared/utils/locale_date_format.dart';
import '../../shared/widgets/loit_receipt_image.dart';
import '../../l10n/l10n_x.dart';

class ReceiptItem {
  final String transactionId;
  final String receiptPath;
  final DateTime? expiresAt;
  final double amount;
  final String currency;
  final String? category;
  final String? notes;
  final String type;
  final DateTime createdAt;

  const ReceiptItem({
    required this.transactionId,
    required this.receiptPath,
    required this.expiresAt,
    required this.amount,
    required this.currency,
    required this.category,
    required this.notes,
    required this.type,
    required this.createdAt,
  });

  factory ReceiptItem.fromRow(Map<String, dynamic> r) => ReceiptItem(
        transactionId: r['id'] as String,
        receiptPath: r['receipt_url'] as String,
        expiresAt: r['receipt_expires_at'] == null
            ? null
            : DateTime.parse(r['receipt_expires_at'] as String),
        amount: ((r['amount'] as num?) ?? 0).toDouble(),
        currency: (r['currency'] as String?) ?? 'IDR',
        category: r['category'] as String?,
        notes: r['notes'] as String?,
        type: (r['type'] as String?) ?? 'expense',
        createdAt: DateTime.parse(
          (r['created_at'] as String?) ??
              DateTime.now().toUtc().toIso8601String(),
        ),
      );
}

enum _ReceiptStatus { active, expiring, expired }

_ReceiptStatus _statusOf(DateTime? expiresAt) {
  if (expiresAt == null) return _ReceiptStatus.active;
  final now = DateTime.now().toUtc();
  if (expiresAt.isBefore(now)) return _ReceiptStatus.expired;
  if (expiresAt.difference(now).inDays <= 14) return _ReceiptStatus.expiring;
  return _ReceiptStatus.active;
}

final receiptsProvider = FutureProvider<List<ReceiptItem>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final rows = await Supabase.instance.client
      .from('transactions')
      .select(
          'id, receipt_url, receipt_expires_at, amount, currency, category, notes, type, created_at')
      .eq('user_id', user.id)
      .not('receipt_url', 'is', null)
      .order('created_at', ascending: false)
      .limit(200);
  return (rows as List)
      .map((r) => ReceiptItem.fromRow(r as Map<String, dynamic>))
      .toList();
});

class ReceiptsScreen extends ConsumerStatefulWidget {
  const ReceiptsScreen({super.key});

  @override
  ConsumerState<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends ConsumerState<ReceiptsScreen> {
  static const _tag = 'ReceiptsScreen';

  /// Per-receipt download progress. Value `null` means indeterminate
  /// (server didn't return Content-Length). Absent key = idle.
  final Map<String, double?> _progress = <String, double?>{};

  Future<void> _downloadOne(ReceiptItem item) async {
    final id = item.transactionId;
    if (_progress.containsKey(id)) return;
    setState(() => _progress[id] = 0.0);
    final l = context.l10n;
    final shareSubject = l.receiptsShareSubject(
      yMMMd(context).format(item.createdAt.toLocal()),
    );
    try {
      final file = await _fetchToTemp(item, onProgress: (received, total) {
        if (!mounted) return;
        setState(() {
          _progress[id] = total == null || total == 0
              ? null
              : (received / total).clamp(0.0, 1.0);
        });
      });
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/jpeg')],
        subject: shareSubject,
      );
    } catch (e, st) {
      Log.e(_tag, 'download failed', error: e, stack: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.receiptsDownloadFailed(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _progress.remove(id));
    }
  }

  Future<File> _fetchToTemp(
    ReceiptItem item, {
    required void Function(int received, int? total) onProgress,
  }) async {
    final signed = await Supabase.instance.client.storage
        .from('receipts')
        .createSignedUrl(item.receiptPath, 3600);
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(signed));
      final res = await client.send(req);
      if (res.statusCode != 200) {
        throw HttpException('HTTP ${res.statusCode}');
      }
      final total = res.contentLength;
      final bytes = <int>[];
      var received = 0;
      onProgress(0, total);
      await for (final chunk in res.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        onProgress(received, total);
      }
      final dir = await getTemporaryDirectory();
      final base = p.basenameWithoutExtension(item.receiptPath);
      final stamp = DateFormat('yyyyMMdd').format(item.createdAt.toLocal());
      final file = File(p.join(dir.path, 'receipt-$stamp-$base.jpg'));
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final async = ref.watch(receiptsProvider);

    return Scaffold(
      backgroundColor: c.canvas,
      appBar: AppBar(
        backgroundColor: c.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l.receiptsTitle),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(LoitSpacing.s5),
            child: Text(
              l.receiptsFailed(e.toString()),
              style:
                  LoitTypography.bodyM.copyWith(color: c.contentSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (items) {
          if (items.isEmpty) return const _EmptyState();
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(receiptsProvider),
            child: GridView.builder(
              padding: const EdgeInsets.all(LoitSpacing.s4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: LoitSpacing.s4,
                crossAxisSpacing: LoitSpacing.s4,
                childAspectRatio: 0.62,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                final id = item.transactionId;
                final isDownloading = _progress.containsKey(id);
                return _ReceiptCard(
                  item: item,
                  downloading: isDownloading,
                  progress: _progress[id],
                  onTap: () => context.push('/transactions/$id'),
                  onDownload: isDownloading ? null : () => _downloadOne(item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({
    required this.item,
    required this.downloading,
    required this.progress,
    required this.onTap,
    required this.onDownload,
  });

  final ReceiptItem item;
  final bool downloading;
  final double? progress;
  final VoidCallback onTap;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final status = _statusOf(item.expiresAt);
    final dateLabel = yMMMd(context).format(item.createdAt.toLocal());
    final title = (item.notes != null && item.notes!.trim().isNotEmpty)
        ? item.notes!.trim()
        : (item.category ?? l.receiptsFallback);
    final amountStr = formatMoney(item.amount.abs(), item.currency);

    return InkWell(
      borderRadius: LoitRadius.brM,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: LoitRadius.brM,
          border: Border.all(color: c.borderSubtle),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: LoitReceiptImage(
                    path: item.receiptPath,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: _StatusChip(status: status),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: _DownloadButton(
                    downloading: downloading,
                    progress: progress,
                    onTap: onDownload,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(LoitSpacing.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: LoitTypography.bodyM.copyWith(
                      color: c.contentPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    amountStr,
                    style: LoitTypography.bodyS.copyWith(
                      color:
                          item.type == 'income' ? c.success : c.contentPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateLabel,
                    style:
                        LoitTypography.bodyS.copyWith(color: c.contentTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  const _DownloadButton({
    required this.downloading,
    required this.progress,
    required this.onTap,
  });

  final bool downloading;
  final double? progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: downloading
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        value: progress,
                        color: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    if (progress != null)
                      Text(
                        '${(progress! * 100).round()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                )
              : const Icon(Icons.download_rounded,
                  size: 18, color: Colors.white),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final _ReceiptStatus status;

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    final (label, bg, fg) = switch (status) {
      _ReceiptStatus.active =>
        (l.receiptsActive, c.success.withValues(alpha: 0.15), c.success),
      _ReceiptStatus.expiring =>
        (l.receiptsExpiring, c.warning.withValues(alpha: 0.18), c.warning),
      _ReceiptStatus.expired =>
        (l.receiptsExpired, c.danger.withValues(alpha: 0.15), c.danger),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: LoitTypography.labelS.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final c = context.loitColors;
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(LoitSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 56, color: c.contentTertiary),
            const SizedBox(height: LoitSpacing.s3),
            Text(
              l.receiptsNoReceipts,
              style: LoitTypography.titleM.copyWith(color: c.contentPrimary),
            ),
            const SizedBox(height: LoitSpacing.s2),
            Text(
              l.receiptsEmptyBody,
              textAlign: TextAlign.center,
              style:
                  LoitTypography.bodyS.copyWith(color: c.contentSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
