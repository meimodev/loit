import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';
import 'log_service.dart';

enum ScanErrorType {
  aiFailure,
  quotaExceeded,
  connectionError,
  serverError,
  notATransaction,
  rateLimited,
  qualityGate,
}

enum ConfidenceBucket { high, medium, low }

ConfidenceBucket bucketFor(double c) {
  if (c >= 0.80) return ConfidenceBucket.high;
  if (c >= 0.60) return ConfidenceBucket.medium;
  return ConfidenceBucket.low;
}

class ScanResult {
  final bool success;
  final Map<String, dynamic>? parsedData;
  final Map<String, dynamic>? partialFields;
  final ScanErrorType? errorType;
  final String? notATransactionReason;
  final bool reconciliationWarning;
  final bool totalComputed;
  final double confidence;

  const ScanResult._({
    required this.success,
    this.parsedData,
    this.partialFields,
    this.errorType,
    this.notATransactionReason,
    this.reconciliationWarning = false,
    this.totalComputed = false,
    this.confidence = 0.0,
  });

  ConfidenceBucket get confidenceBucket => bucketFor(confidence);

  factory ScanResult.success(
    Map<String, dynamic> data, {
    bool reconciliationWarning = false,
    bool totalComputed = false,
    double confidence = 0.0,
  }) =>
      ScanResult._(
        success: true,
        parsedData: data,
        reconciliationWarning: reconciliationWarning,
        totalComputed: totalComputed,
        confidence: confidence,
      );

  factory ScanResult.aiFailure(Map<String, dynamic> partial) => ScanResult._(
        success: false,
        partialFields: partial,
        errorType: ScanErrorType.aiFailure,
      );

  factory ScanResult.quotaExceeded() => const ScanResult._(
        success: false,
        errorType: ScanErrorType.quotaExceeded,
      );

  factory ScanResult.connectionError() => const ScanResult._(
        success: false,
        errorType: ScanErrorType.connectionError,
      );

  factory ScanResult.serverError() => const ScanResult._(
        success: false,
        errorType: ScanErrorType.serverError,
      );

  factory ScanResult.notATransaction({String? reason}) => ScanResult._(
        success: false,
        errorType: ScanErrorType.notATransaction,
        notATransactionReason: reason,
      );

  factory ScanResult.rateLimited() => const ScanResult._(
        success: false,
        errorType: ScanErrorType.rateLimited,
      );

  factory ScanResult.qualityGate(String reason) => ScanResult._(
        success: false,
        errorType: ScanErrorType.qualityGate,
        notATransactionReason: reason,
      );
}

class ScannerService {
  static const _tag = 'ScannerService';
  static const int _jpegQuality = 85;
  // Reconciliation tolerance per line item (rounding slop). Pure IDR.
  static const double _reconcileTolPerItem = 1.0;

  /// Legacy compressor — kept for callers that haven't migrated to
  /// [ScanPreprocessor]. The new pipeline does its own preprocessing
  /// (1600px long edge) and passes the resulting bytes directly.
  Future<Uint8List> compressImage(File imageFile) async {
    final original = await imageFile.length();
    final result = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: 1600,
      minHeight: 1600,
      quality: _jpegQuality,
      format: CompressFormat.jpeg,
    );
    if (result == null) throw Exception('Could not compress image');
    Log.i(
      _tag,
      'Compressed ${(original / 1024).toStringAsFixed(0)}KB → '
      '${(result.length / 1024).toStringAsFixed(0)}KB',
    );
    return result;
  }

  Future<File> compressToFile(File imageFile) async {
    final bytes = await compressImage(imageFile);
    final dir = await getTemporaryDirectory();
    final out = File(
      '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await out.writeAsBytes(bytes, flush: true);
    return out;
  }

  /// One server round-trip per call. The shared gated helper charges quota and
  /// does any strict-retry on malformed JSON server-side (see docs/adr/0004);
  /// the client only retries genuine network failures, which never reached the
  /// server and so never charged a scan.
  Future<ScanResult> scanReceipt(
    File imageFile, {
    List<Map<String, String>>? categories,
    List<String>? accountNames,
  }) async {
    Log.i(
      _tag,
      'Scanning (cats=${categories?.length ?? 0}, accts=${accountNames?.length ?? 0})',
    );

    final Uint8List imageBytes;
    try {
      imageBytes = await imageFile.readAsBytes();
    } catch (e, st) {
      Log.e(_tag, 'Image read failed', error: e, stack: st);
      return ScanResult.serverError();
    }
    final base64Image = base64Encode(imageBytes);

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      Log.w(_tag, 'No session, aborting scan');
      return ScanResult.serverError();
    }

    final accountsPayload =
        accountNames?.map((n) => {'name': n}).toList(growable: false) ?? [];

    var result = await _callApi(
      base64Image: base64Image,
      session: session,
      categories: categories,
      accounts: accountsPayload,
    );

    // Strict-retry on malformed AI JSON now happens server-side in the shared
    // gated helper, so one client call = at most one charged scan. Only retry
    // genuine network failures here — those never reached the server, so they
    // never consumed quota. notATransaction / aiFailure / quota / serverError
    // are terminal.
    if (result.errorType == ScanErrorType.connectionError) {
      Log.w(_tag, 'Retrying after 1s (network)');
      await Future<void>.delayed(const Duration(seconds: 1));
      result = await _callApi(
        base64Image: base64Image,
        session: session,
        categories: categories,
        accounts: accountsPayload,
      );
    }

    return result;
  }

  Future<ScanResult> _callApi({
    required String base64Image,
    required Session session,
    List<Map<String, String>>? categories,
    required List<Map<String, String>> accounts,
  }) async {
    try {
      final bodyMap = <String, dynamic>{
        'image': base64Image,
        if (categories != null) 'categories': categories,
        'accounts': accounts,
      };

      final response = await http
          .post(
            Uri.parse('${Env.supabaseUrl}/functions/v1/scan-receipt'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${session.accessToken}',
            },
            body: jsonEncode(bodyMap),
          )
          .timeout(const Duration(seconds: 30));

      Log.d(_tag, 'Response status=${response.statusCode}');

      switch (response.statusCode) {
        case 200:
          final parsed = jsonDecode(response.body) as Map<String, dynamic>;
          return _postProcess(parsed);

        case 422:
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          if (body['not_a_transaction'] == true) {
            final reason = body['reason'] as String?;
            Log.w(_tag, 'Not a transaction: $reason');
            return ScanResult.notATransaction(reason: reason);
          }
          final partial =
              (body['partial_fields'] as Map<String, dynamic>?) ?? {};
          Log.w(_tag, 'AI parse failure, partial: $partial');
          return ScanResult.aiFailure(partial);

        case 402:
          // Server-authoritative gate (scan-receipt → gatedScan, ADR 0004).
          Log.w(_tag, 'Quota exceeded (server-gated)');
          return ScanResult.quotaExceeded();

        default:
          Log.e(_tag, 'Server error: ${response.statusCode}');
          return ScanResult.serverError();
      }
    } on SocketException catch (e) {
      Log.w(_tag, 'Connection error', error: e);
      return ScanResult.connectionError();
    } on http.ClientException catch (e) {
      Log.w(_tag, 'Connection error', error: e);
      return ScanResult.connectionError();
    } on TimeoutException {
      Log.w(_tag, 'Request timed out');
      return ScanResult.connectionError();
    } catch (e, st) {
      Log.e(_tag, 'Unexpected scan error', error: e, stack: st);
      return ScanResult.serverError();
    }
  }

  /// Step 6 — arithmetic reconciliation. Mutates [parsed.total] if computed
  /// from line items. Returns wrapped ScanResult with warning flags.
  ScanResult _postProcess(Map<String, dynamic> parsed) {
    final items = (parsed['items'] as List?) ?? const [];
    final returnedTotal = (parsed['total'] as num?)?.toDouble() ?? 0;
    final confidence = (parsed['confidence'] as num?)?.toDouble() ?? 0.5;

    double itemSum = 0;
    for (final item in items) {
      if (item is Map) {
        final tp = (item['total_price'] as num?)?.toDouble() ?? 0;
        final unit = (item['unit_price'] as num?)?.toDouble() ?? 0;
        final qty = (item['qty'] as num?)?.toDouble() ?? 0;
        final eff = tp > 0 ? tp : qty * unit;
        itemSum += eff;
      }
    }

    var reconcileWarning = false;
    var totalComputed = false;

    if (returnedTotal <= 0 && itemSum > 0) {
      parsed['total'] = itemSum;
      totalComputed = true;
    } else if (returnedTotal > 0 && itemSum > 0) {
      final tol = _reconcileTolPerItem * items.length;
      if ((returnedTotal - itemSum).abs() > tol) {
        reconcileWarning = true;
        Log.w(
          _tag,
          'Reconciliation mismatch: total=$returnedTotal sum=$itemSum tol=$tol',
        );
        // Prefer printed total — leave parsed['total'] as returnedTotal.
      }
    }

    Log.i(
      _tag,
      'Scan ok: type=${parsed['type']} total=${parsed['total']} '
      'cat=${parsed['category']} acct=${parsed['account']} conf=$confidence '
      'reconcile=$reconcileWarning computed=$totalComputed',
    );

    return ScanResult.success(
      parsed,
      reconciliationWarning: reconcileWarning,
      totalComputed: totalComputed,
      confidence: confidence,
    );
  }
}
