import 'package:flutter/material.dart';

import 'loit_colors.dart';

/// Convenience semantic aliases not modeled as ThemeExtension fields.
class LoitStatusAliases {
  LoitStatusAliases._();

  /// Income amounts on tx rows / stat triple. Maps to status `info` blue.
  static Color income(LoitColors c) => c.info;

  /// Expense amounts on tx rows / stat triple. Maps to status `danger` red.
  static Color expense(LoitColors c) => c.danger;
}
