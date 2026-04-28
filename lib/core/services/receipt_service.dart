import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'log_service.dart';

/// Pro/Team only: stores receipt images under `receipts/{user_id}/{txn}.jpg`
/// in Supabase Storage. Free-tier callers should never reach this service.
///
/// Tier enforcement is client-side (`FeatureFlags.receiptStorage`). Storage
/// RLS additionally blocks cross-user reads/writes.
class ReceiptService {
  static const _tag = 'ReceiptService';
  static const _bucket = 'receipts';

  ReceiptService({SupabaseClient? supabase})
    : _supabase = supabase ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Returns the storage path (not a signed URL — re-sign on each view).
  Future<String> uploadReceipt({
    required String userId,
    required String transactionId,
    required Uint8List imageBytes,
  }) async {
    final path = '$userId/$transactionId.jpg';

    await _supabase.storage
        .from(_bucket)
        .uploadBinary(
          path,
          imageBytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final expiresAt = DateTime.now().toUtc().add(const Duration(days: 365));
    await _supabase
        .from('transactions')
        .update({
          'receipt_url': path,
          'receipt_expires_at': expiresAt.toIso8601String(),
        })
        .eq('id', transactionId);

    Log.i(_tag, 'Uploaded receipt path=$path');
    return path;
  }

  /// Fresh signed URL valid for 1 hour. Always regenerate on view.
  Future<String> getSignedUrl(String storagePath) {
    return _supabase.storage.from(_bucket).createSignedUrl(storagePath, 3600);
  }
}
