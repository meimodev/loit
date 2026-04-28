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
  aiFailure, // 422 — open manual entry form with pre-filled fields
  quotaExceeded, // 402 — show upgrade/top-up prompt
  connectionError, // No internet / timeout — show retry button; do NOT open manual entry
  serverError, // 5xx — show retry button; do NOT open manual entry
}

class ScanResult {
  final bool success;
  final Map<String, dynamic>? parsedData;
  final Map<String, dynamic>? partialFields;
  final ScanErrorType? errorType;

  const ScanResult._({
    required this.success,
    this.parsedData,
    this.partialFields,
    this.errorType,
  });

  factory ScanResult.success(Map<String, dynamic> data) =>
      ScanResult._(success: true, parsedData: data);

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

  factory ScanResult.serverError() =>
      const ScanResult._(success: false, errorType: ScanErrorType.serverError);
}

class ScannerService {
  static const _tag = 'ScannerService';
  // Receipt OCR works fine well below 1024px on a long side; smaller =
  // smaller upload + smaller AI payload + smaller storage cost.
  static const int _maxLongSide = 1024;
  static const int _jpegQuality = 85;

  /// Compress image using native platform codecs (libjpeg-turbo / ImageIO).
  /// Resizes longest edge to [_maxLongSide], preserves aspect ratio.
  Future<Uint8List> compressImage(File imageFile) async {
    final original = await imageFile.length();
    final result = await FlutterImageCompress.compressWithFile(
      imageFile.absolute.path,
      minWidth: _maxLongSide,
      minHeight: _maxLongSide,
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

  /// Compress [imageFile] and write result to a temp `.jpg` file.
  /// Caller passes the returned file to both the AI scan and the upload step
  /// so they share one compressed payload.
  Future<File> compressToFile(File imageFile) async {
    final bytes = await compressImage(imageFile);
    final dir = await getTemporaryDirectory();
    final out = File(
      '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await out.writeAsBytes(bytes, flush: true);
    return out;
  }

  Future<ScanResult> scanReceipt(File imageFile, {bool isDemo = false}) async {
    Log.i(_tag, 'Scanning receipt (demo=$isDemo)');
    try {
      final imageBytes = await compressImage(imageFile);
      Log.d(_tag, 'Compressed to ${imageBytes.length} bytes');
      final base64Image = base64Encode(imageBytes);

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        Log.w(_tag, 'No session, aborting scan');
        return ScanResult.serverError();
      }

      final response = await http
          .post(
            Uri.parse('${Env.supabaseUrl}/functions/v1/scan-receipt'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${session.accessToken}',
            },
            body: jsonEncode({'image': base64Image, 'is_demo': isDemo}),
          )
          .timeout(const Duration(seconds: 30));

      Log.d(_tag, 'Response status=${response.statusCode}');

      switch (response.statusCode) {
        case 200:
          final parsed = jsonDecode(response.body) as Map<String, dynamic>;
          Log.i(_tag, 'Scan success: merchant=${parsed['merchant']}');
          return ScanResult.success(parsed);

        case 422:
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final partial =
              (body['partial_fields'] as Map<String, dynamic>?) ?? {};
          Log.w(_tag, 'AI parse failure, partial fields: ${partial.keys}');
          return ScanResult.aiFailure(partial);

        case 402:
          Log.w(_tag, 'Quota exceeded');
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
}
