import 'package:flutter/animation.dart';

/// Motion durations + curves.
class LoitMotion {
  LoitMotion._();

  static const Duration instant = Duration(milliseconds: 80);
  static const Duration short = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration emphasized = Duration(milliseconds: 320);
  static const Duration entrance = Duration(milliseconds: 520);
  static const Duration staggerStep = Duration(milliseconds: 70);

  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve emphasizedCurve = Cubic(0.2, 0, 0, 1);
  static const Curve easeOutQuart = Cubic(0.25, 1, 0.5, 1);
  static const Curve easeOutQuint = Cubic(0.22, 1, 0.36, 1);
  static const Curve easeOutExpo = Cubic(0.16, 1, 0.3, 1);
}
