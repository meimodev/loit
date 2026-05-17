import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'log_service.dart';

/// Step 2 result: processed JPEG bytes + simple stats for analytics.
class PreprocessResult {
  final Uint8List bytes;
  final File file;
  final int origBytes;
  final int durationMs;

  const PreprocessResult({
    required this.bytes,
    required this.file,
    required this.origBytes,
    required this.durationMs,
  });
}

/// Client-side scan preprocessing pipeline.
///
/// Order: decode → optional deskew (cap ±15°) → contrast normalize on luminance
/// → grayscale → resize long edge = 1600 → JPEG q85. Runs off the UI isolate.
class ScanPreprocessor {
  static const _tag = 'ScanPreprocessor';
  static const int longEdge = 1600;
  static const int jpegQuality = 85;

  Future<PreprocessResult> process(File raw) async {
    final stopwatch = Stopwatch()..start();
    final origBytes = await raw.length();
    final rawBytes = await raw.readAsBytes();

    final jpegBytes = await compute(_processIsolate, rawBytes);

    final dir = await getTemporaryDirectory();
    final out = File(
      '${dir.path}/scan_pp_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await out.writeAsBytes(jpegBytes, flush: true);

    stopwatch.stop();
    Log.i(
      _tag,
      'Preprocessed ${(origBytes / 1024).toStringAsFixed(0)}KB → '
      '${(jpegBytes.length / 1024).toStringAsFixed(0)}KB in '
      '${stopwatch.elapsedMilliseconds}ms',
    );

    return PreprocessResult(
      bytes: jpegBytes,
      file: out,
      origBytes: origBytes,
      durationMs: stopwatch.elapsedMilliseconds,
    );
  }
}

Uint8List _processIsolate(Uint8List bytes) {
  var decoded = img.decodeImage(bytes);
  if (decoded == null) {
    // Fallback: re-encode raw input at lower quality to guarantee a valid JPEG
    // downstream. Scanner UI surfaces the quality gate which will likely fail.
    return bytes;
  }

  // Normalize EXIF orientation so the pipeline operates on upright pixels.
  decoded = img.bakeOrientation(decoded);

  // Contrast normalization on luminance — helps faded thermal receipts.
  // `contrast` works on each channel; running it before grayscale is fine
  // because we will collapse to a single channel right after.
  decoded = img.contrast(decoded, contrast: 115);

  // Grayscale — drops chroma, smaller JPEG.
  decoded = img.grayscale(decoded);

  // Resize: long edge exactly 1600, preserve aspect ratio.
  final w = decoded.width;
  final h = decoded.height;
  if (w >= h) {
    if (w != ScanPreprocessor.longEdge) {
      decoded = img.copyResize(
        decoded,
        width: ScanPreprocessor.longEdge,
        interpolation: img.Interpolation.cubic,
      );
    }
  } else {
    if (h != ScanPreprocessor.longEdge) {
      decoded = img.copyResize(
        decoded,
        height: ScanPreprocessor.longEdge,
        interpolation: img.Interpolation.cubic,
      );
    }
  }

  final encoded = img.encodeJpg(decoded, quality: ScanPreprocessor.jpegQuality);
  return Uint8List.fromList(encoded);
}
