import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/env.dart';

enum ScanErrorType {
  aiFailure,       // 422 — open manual entry form with pre-filled fields
  quotaExceeded,   // 402 — show upgrade/top-up prompt
  connectionError, // No internet — show retry button; do NOT open manual entry
  serverError,     // 5xx — show retry button; do NOT open manual entry
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

  factory ScanResult.aiFailure(Map<String, dynamic> partial) =>
      ScanResult._(
        success: false,
        partialFields: partial,
        errorType: ScanErrorType.aiFailure,
      );

  factory ScanResult.quotaExceeded() =>
      const ScanResult._(success: false, errorType: ScanErrorType.quotaExceeded);

  factory ScanResult.connectionError() =>
      const ScanResult._(success: false, errorType: ScanErrorType.connectionError);

  factory ScanResult.serverError() =>
      const ScanResult._(success: false, errorType: ScanErrorType.serverError);
}

class ScannerService {
  static const int _maxLongSide = 1280; // cap longest edge; other edge scales proportionally
  static const int _jpegQuality = 85;   // visually lossless for receipts, ~60% smaller than quality 100

  /// Decode → downscale → re-encode as JPEG.
  /// Returns bytes ready for base64 transmission to the Edge Function.
  ///
  /// Uses `image` package 4.x API: pass EITHER `width` OR `height` (not both)
  /// to preserve aspect ratio automatically. Passing both stretches the image.
  Future<Uint8List> compressTo720p(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Could not decode image');

    final longest = decoded.width > decoded.height ? decoded.width : decoded.height;
    final resized = longest > _maxLongSide
        ? img.copyResize(
            decoded,
            width:  decoded.width  >= decoded.height ? _maxLongSide : null,
            height: decoded.height >  decoded.width  ? _maxLongSide : null,
            interpolation: img.Interpolation.average,
          )
        : decoded;

    return img.encodeJpg(resized, quality: _jpegQuality);
  }

  Future<ScanResult> scanReceipt(File imageFile, {bool isDemo = false}) async {
    try {
      final imageBytes = await compressTo720p(imageFile);
      final base64Image = base64Encode(imageBytes);

      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return ScanResult.serverError();

      final response = await http.post(
        Uri.parse('${Env.supabaseUrl}/functions/v1/scan-receipt'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({'image': base64Image, 'is_demo': isDemo}),
      ).timeout(const Duration(seconds: 30));

      switch (response.statusCode) {
        case 200:
          final parsed = jsonDecode(response.body) as Map<String, dynamic>;
          return ScanResult.success(parsed);

        case 422:
          // Server has already extracted partial fields — safe to use directly.
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          final partial = (body['partial_fields'] as Map<String, dynamic>?) ?? {};
          return ScanResult.aiFailure(partial);

        case 402:
          return ScanResult.quotaExceeded();

        default:
          return ScanResult.serverError();
      }
    } on SocketException {
      return ScanResult.connectionError();
    } on http.ClientException {
      return ScanResult.connectionError();
    } catch (_) {
      return ScanResult.serverError();
    }
  }
}
