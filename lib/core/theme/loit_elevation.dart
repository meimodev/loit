import 'package:flutter/material.dart';

/// Soft, low shadows. Spec: border-first, shadows are auxiliary.
class LoitElevation {
  LoitElevation._();

  // elevation.0 — flat with subtle border (no shadow). Use border, not boxShadow.
  static const List<BoxShadow> e0 = [];

  // elevation.1 — raised cards, tab bar
  static const List<BoxShadow> e1 = [
    BoxShadow(color: Color(0x0A111613), offset: Offset(0, 1), blurRadius: 2),
  ];

  // elevation.2 — FAB, toast
  static const List<BoxShadow> e2 = [
    BoxShadow(color: Color(0x14111613), offset: Offset(0, 4), blurRadius: 12),
  ];

  // elevation.3 — bottom sheet, modal
  static const List<BoxShadow> e3 = [
    BoxShadow(color: Color(0x1F111613), offset: Offset(0, 12), blurRadius: 32),
  ];

  // elevation.4 — full-screen overlay
  static const List<BoxShadow> e4 = [
    BoxShadow(color: Color(0x29111613), offset: Offset(0, 24), blurRadius: 64),
  ];

}
