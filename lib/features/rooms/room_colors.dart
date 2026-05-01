import 'package:flutter/material.dart';

/// LOIT room color identity palette (per design `screens-rooms.jsx` RoomCreate).
class RoomColors {
  RoomColors._();

  static const palette = <Color>[
    Color(0xFF0F6E5C),
    Color(0xFFF2A85C),
    Color(0xFF7A4FBF),
    Color(0xFFC5443E),
    Color(0xFF3E7AC5),
    Color(0xFF2F8F5E),
    Color(0xFFD47A9B),
    Color(0xFF5A6160),
  ];

  /// Deterministic color from a room id / name (rooms table has no color column,
  /// so we hash for identity).
  static Color forId(String? key) {
    if (key == null || key.isEmpty) return palette.first;
    var h = 0;
    for (final code in key.codeUnits) {
      h = (h * 31 + code) & 0x7fffffff;
    }
    return palette[h % palette.length];
  }
}
