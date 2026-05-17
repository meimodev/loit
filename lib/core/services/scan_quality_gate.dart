import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import 'log_service.dart';

enum QualityFailReason { blur, brightness, aspect }

class QualityResult {
  final bool ok;
  final QualityFailReason? reason;
  final double blurScore; // Laplacian variance — higher = sharper
  final double brightness; // mean luminance 0-255
  final double aspect; // w / h

  const QualityResult._({
    required this.ok,
    this.reason,
    required this.blurScore,
    required this.brightness,
    required this.aspect,
  });

  factory QualityResult.pass({
    required double blurScore,
    required double brightness,
    required double aspect,
  }) =>
      QualityResult._(
        ok: true,
        blurScore: blurScore,
        brightness: brightness,
        aspect: aspect,
      );

  factory QualityResult.fail({
    required QualityFailReason reason,
    required double blurScore,
    required double brightness,
    required double aspect,
  }) =>
      QualityResult._(
        ok: false,
        reason: reason,
        blurScore: blurScore,
        brightness: brightness,
        aspect: aspect,
      );

  String get reasonKey {
    switch (reason) {
      case QualityFailReason.blur:
        return 'blur';
      case QualityFailReason.brightness:
        return 'brightness';
      case QualityFailReason.aspect:
        return 'aspect';
      case null:
        return 'ok';
    }
  }
}

/// Step 3 — client-side quality gate. Runs after preprocessing, BEFORE quota
/// check. Rejects obviously bad images so users don't burn scans.
class ScanQualityGate {
  static const _tag = 'ScanQualityGate';

  // Thresholds tuned for the 1600px-long-edge grayscale JPEGs we produce.
  static const double _blurMin = 60.0; // Laplacian variance floor
  static const double _brightnessMin = 30.0;
  static const double _brightnessMax = 220.0;
  static const double _aspectMin = 0.3;
  static const double _aspectMax = 3.0;

  Future<QualityResult> check(Uint8List jpegBytes) async {
    final result = await compute(_checkIsolate, jpegBytes);
    Log.i(
      _tag,
      'Quality: ok=${result.ok} reason=${result.reasonKey} '
      'blur=${result.blurScore.toStringAsFixed(1)} '
      'bright=${result.brightness.toStringAsFixed(1)} '
      'aspect=${result.aspect.toStringAsFixed(2)}',
    );
    return result;
  }
}

QualityResult _checkIsolate(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    return QualityResult.fail(
      reason: QualityFailReason.blur,
      blurScore: 0,
      brightness: 0,
      aspect: 0,
    );
  }

  final w = decoded.width;
  final h = decoded.height;
  final aspect = w / h;

  if (aspect < ScanQualityGate._aspectMin ||
      aspect > ScanQualityGate._aspectMax) {
    return QualityResult.fail(
      reason: QualityFailReason.aspect,
      blurScore: 0,
      brightness: 0,
      aspect: aspect,
    );
  }

  // Downsample to a 256-wide thumbnail for the blur/brightness math —
  // cheap and stable across input sizes.
  final thumb = img.copyResize(decoded, width: 256);
  final tw = thumb.width;
  final th = thumb.height;

  final lum = Uint8List(tw * th);
  var bsum = 0;
  for (var y = 0; y < th; y++) {
    for (var x = 0; x < tw; x++) {
      final p = thumb.getPixel(x, y);
      // ITU-R BT.601 luma; image package gives 0..255 channels.
      final v = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
      final clamped = v < 0 ? 0 : (v > 255 ? 255 : v);
      lum[y * tw + x] = clamped;
      bsum += clamped;
    }
  }
  final brightness = bsum / (tw * th);

  if (brightness < ScanQualityGate._brightnessMin ||
      brightness > ScanQualityGate._brightnessMax) {
    return QualityResult.fail(
      reason: QualityFailReason.brightness,
      blurScore: 0,
      brightness: brightness,
      aspect: aspect,
    );
  }

  // Laplacian variance — classical blur metric.
  // Kernel: [0 1 0; 1 -4 1; 0 1 0]
  var sum = 0.0;
  var sumSq = 0.0;
  var n = 0;
  for (var y = 1; y < th - 1; y++) {
    for (var x = 1; x < tw - 1; x++) {
      final c = lum[y * tw + x];
      final u = lum[(y - 1) * tw + x];
      final d = lum[(y + 1) * tw + x];
      final l = lum[y * tw + x - 1];
      final r = lum[y * tw + x + 1];
      final lap = (u + d + l + r - 4 * c).toDouble();
      sum += lap;
      sumSq += lap * lap;
      n++;
    }
  }
  final mean = sum / n;
  final variance = (sumSq / n) - (mean * mean);

  if (variance < ScanQualityGate._blurMin) {
    return QualityResult.fail(
      reason: QualityFailReason.blur,
      blurScore: variance,
      brightness: brightness,
      aspect: aspect,
    );
  }

  return QualityResult.pass(
    blurScore: variance,
    brightness: brightness,
    aspect: aspect,
  );
}
