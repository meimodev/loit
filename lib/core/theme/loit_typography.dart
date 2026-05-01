import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// LOIT type scale. Inter, with tabular numerals for amounts.
///
/// Values mirror the spec:
/// ```
/// display.m       40/44   600
/// title.l         24/30   600
/// title.m         20/26   600
/// body.l          16/24   400
/// body.m          14/20   400
/// body.s          12/16   500
/// amount.hero     40      600 tnum
/// amount.default  16      600 tnum
/// ```
class LoitTypography {
  LoitTypography._();

  static const _tnum = [FontFeature.tabularFigures()];

  static TextStyle _base(double size, double height, FontWeight weight,
      {double letterSpacing = 0, List<FontFeature>? features}) {
    return GoogleFonts.inter(
      fontSize: size,
      height: height / size,
      fontWeight: weight,
      letterSpacing: letterSpacing,
      fontFeatures: features,
    );
  }

  // Display
  static TextStyle get displayM =>
      _base(40, 44, FontWeight.w600, letterSpacing: -0.5);

  // Titles
  static TextStyle get titleL =>
      _base(24, 30, FontWeight.w600, letterSpacing: -0.2);
  static TextStyle get titleM =>
      _base(20, 26, FontWeight.w600, letterSpacing: -0.1);

  // Body
  static TextStyle get bodyL => _base(16, 24, FontWeight.w400);
  static TextStyle get bodyM => _base(14, 20, FontWeight.w400);
  static TextStyle get bodyS =>
      _base(12, 16, FontWeight.w500, letterSpacing: 0.1);

  // Labels (uppercase eyebrows, chip text)
  static TextStyle get labelL =>
      _base(13, 18, FontWeight.w500, letterSpacing: 0.1);
  static TextStyle get labelM =>
      _base(12, 16, FontWeight.w600, letterSpacing: 0.2);
  static TextStyle get labelS =>
      _base(11, 14, FontWeight.w600, letterSpacing: 0.5);

  // Amount (tabular nums)
  static TextStyle get amountHero =>
      _base(40, 48, FontWeight.w600, letterSpacing: -0.4, features: _tnum);
  static TextStyle get amountDefault =>
      _base(16, 22, FontWeight.w600, features: _tnum);
  static TextStyle get amountLarge =>
      _base(28, 32, FontWeight.w600, letterSpacing: -0.2, features: _tnum);

  static TextTheme textTheme(Color primary) {
    return TextTheme(
      displayLarge: displayM.copyWith(color: primary),
      displayMedium: displayM.copyWith(color: primary),
      headlineLarge: titleL.copyWith(color: primary),
      headlineMedium: titleM.copyWith(color: primary),
      titleLarge: titleL.copyWith(color: primary),
      titleMedium: titleM.copyWith(color: primary),
      titleSmall: labelL.copyWith(color: primary),
      bodyLarge: bodyL.copyWith(color: primary),
      bodyMedium: bodyM.copyWith(color: primary),
      bodySmall: bodyS.copyWith(color: primary),
      labelLarge: labelL.copyWith(color: primary),
      labelMedium: labelM.copyWith(color: primary),
      labelSmall: labelS.copyWith(color: primary),
    );
  }
}
