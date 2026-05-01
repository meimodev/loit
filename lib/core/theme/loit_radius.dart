import 'package:flutter/material.dart';

/// LOIT radius scale.
class LoitRadius {
  LoitRadius._();

  static const double none = 0;
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double full = 999;

  static BorderRadius all(double r) => BorderRadius.circular(r);

  // Common shapes
  static final brXs = BorderRadius.circular(xs);
  static final brS = BorderRadius.circular(s);
  static final brM = BorderRadius.circular(m);
  static final brL = BorderRadius.circular(l);
  static final brXl = BorderRadius.circular(xl);
  static final brFull = BorderRadius.circular(full);

  /// Top-only (used by bottom sheets per spec).
  static const brSheet = BorderRadius.only(
    topLeft: Radius.circular(xl),
    topRight: Radius.circular(xl),
  );
}
