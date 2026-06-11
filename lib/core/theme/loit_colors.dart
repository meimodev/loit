import 'package:flutter/material.dart';

/// Raw color primitives mirrored from the LOIT design system (`tokens.jsx`).
///
/// Names match the design tokens 1:1. Do NOT use raw hex outside this file.
/// Semantic tokens live in [LoitColors].
class LoitPalette {
  LoitPalette._();

  // Neutrals
  static const n50 = Color(0xFFFAFAF7);
  static const n100 = Color(0xFFF3F2ED);
  static const n200 = Color(0xFFEAEAE4);
  static const n300 = Color(0xFFD4D4CE);
  static const n400 = Color(0xFFB0B2AC);
  static const n500 = Color(0xFF9AA09E);
  static const n600 = Color(0xFF74787A);
  static const n700 = Color(0xFF5A6160);
  static const n800 = Color(0xFF2E3230);
  static const n900 = Color(0xFF111613);

  // Mint (logo brand) — vivid spring green from the LOIT wordmark
  static const mint200 = Color(0xFF5CF2B4); // highlight
  static const mint300 = Color(0xFF34E89E); // logo green — dark brand
  static const mint400 = Color(0xFF2BC487); // pressed/hover
  static const mintDark = Color(0xFF1FA871); // light-mode brand, AA on white

  // Teal (brand)
  static const teal50 = Color(0xFFE6F4F0);
  static const teal100 = Color(0xFFC4E4DB);
  static const teal200 = Color(0xFF96CDBE);
  static const teal300 = Color(0xFF67B5A0);
  static const teal400 = Color(0xFF3E9C82);
  static const teal500 = Color(0xFF188268);
  static const teal600 = Color(0xFF0F6E5C);
  static const teal700 = Color(0xFF0A5A4B);
  static const teal800 = Color(0xFF06463B);
  static const teal900 = Color(0xFF033229);

  // Ochre (accent)
  static const ochre50 = Color(0xFFFDF5EA);
  static const ochre100 = Color(0xFFFBE7C9);
  static const ochre200 = Color(0xFFF8D29A);
  static const ochre300 = Color(0xFFF5BC6D);
  static const ochre400 = Color(0xFFF2A85C);
  static const ochre500 = Color(0xFFE8922F);
  static const ochre600 = Color(0xFFC77A1E);
  static const ochre700 = Color(0xFF9E5F14);
  static const ochre800 = Color(0xFF76460D);
  static const ochre900 = Color(0xFF4E2D06);

  // Status — Success (green)
  static const green50 = Color(0xFFE8F5EC);
  static const green400 = Color(0xFF4FA678);
  static const green500 = Color(0xFF2F8F5E);
  static const green600 = Color(0xFF227549);
  static const green700 = Color(0xFF195B38);

  // Status — Warning (amber)
  static const amber50 = Color(0xFFFDF4E0);
  static const amber400 = Color(0xFFE0A93A);
  static const amber500 = Color(0xFFD49A2B);
  static const amber600 = Color(0xFFA87820);
  static const amber700 = Color(0xFF7D5916);

  // Status — Danger (red)
  static const red50 = Color(0xFFFBEAE9);
  static const red400 = Color(0xFFD15C55);
  static const red500 = Color(0xFFC5443E);
  static const red600 = Color(0xFF9D332E);
  static const red700 = Color(0xFF762622);

  // Status — Info (blue)
  static const blue50 = Color(0xFFE6EEF8);
  static const blue400 = Color(0xFF5A8FCE);
  static const blue500 = Color(0xFF3E7AC5);
  static const blue600 = Color(0xFF2F5E99);
  static const blue700 = Color(0xFF22456F);

  // Room palette (8)
  static const room1 = Color(0xFF0F6E5C);
  static const room2 = Color(0xFFF2A85C);
  static const room3 = Color(0xFF7A4FBF);
  static const room4 = Color(0xFFC5443E);
  static const room5 = Color(0xFF3E7AC5);
  static const room6 = Color(0xFF2F8F5E);
  static const room7 = Color(0xFFD47A9B);
  static const room8 = Color(0xFF5A6160);

  static const List<Color> rooms = [
    room1, room2, room3, room4, room5, room6, room7, room8,
  ];
}

/// Semantic color tokens. Resolve via `Theme.of(context).extension<LoitColors>()`.
@immutable
class LoitColors extends ThemeExtension<LoitColors> {
  const LoitColors({
    required this.canvas,
    required this.surface,
    required this.raised,
    required this.overlay,
    required this.muted,
    required this.inverse,
    required this.contentPrimary,
    required this.contentSecondary,
    required this.contentTertiary,
    required this.contentDisabled,
    required this.contentInverse,
    required this.brand,
    required this.accent,
    required this.borderSubtle,
    required this.borderDefault,
    required this.borderStrong,
    required this.borderFocus,
    required this.borderDanger,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.successSurface,
    required this.warningSurface,
    required this.dangerSurface,
    required this.infoSurface,
  });

  final Color canvas;
  final Color surface;
  final Color raised;
  final Color overlay;
  final Color muted;
  final Color inverse;

  final Color contentPrimary;
  final Color contentSecondary;
  final Color contentTertiary;
  final Color contentDisabled;
  final Color contentInverse;

  final Color brand;
  final Color accent;

  final Color borderSubtle;
  final Color borderDefault;
  final Color borderStrong;
  final Color borderFocus;
  final Color borderDanger;

  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color successSurface;
  final Color warningSurface;
  final Color dangerSurface;
  final Color infoSurface;

  static const light = LoitColors(
    canvas: LoitPalette.n50,
    surface: Color(0xFFFFFFFF),
    raised: Color(0xFFFFFFFF),
    overlay: Color(0xFFFFFFFF),
    muted: LoitPalette.n100,
    inverse: LoitPalette.n900,
    contentPrimary: LoitPalette.n900,
    contentSecondary: LoitPalette.n700,
    contentTertiary: LoitPalette.n500,
    contentDisabled: LoitPalette.n400,
    contentInverse: Color(0xFFFFFFFF),
    brand: LoitPalette.mintDark,
    accent: LoitPalette.ochre500,
    borderSubtle: LoitPalette.n200,
    borderDefault: LoitPalette.n300,
    borderStrong: LoitPalette.n400,
    borderFocus: LoitPalette.mintDark,
    borderDanger: LoitPalette.red500,
    success: LoitPalette.green500,
    warning: LoitPalette.amber500,
    danger: LoitPalette.red500,
    info: LoitPalette.blue500,
    successSurface: LoitPalette.green50,
    warningSurface: LoitPalette.amber50,
    dangerSurface: LoitPalette.red50,
    infoSurface: LoitPalette.blue50,
  );

  // Dark mode retoned to the logo palette — mint brand on desaturated petrol.
  // See docs/adr/0006-dark-mode-brand-retone.md.
  static const dark = LoitColors(
    canvas: Color(0xFF0D2E33), // desaturated petrol (logo bg #0B3A42 = splash)
    surface: Color(0xFF123A40),
    raised: Color(0xFF16454C),
    overlay: Color(0xFF1B5159),
    muted: Color(0x82173D44),
    inverse: LoitPalette.n50,
    contentPrimary: Color(0xFFEAF5F1),
    contentSecondary: Color(0xFFA9C4BD),
    contentTertiary: Color(0xFF7B9893),
    contentDisabled: Color(0xFF4F6A66),
    contentInverse: LoitPalette.n900,
    brand: LoitPalette.mint300,
    accent: LoitPalette.ochre300,
    borderSubtle: Color(0xFF163D44),
    borderDefault: Color(0xFF1E4952),
    borderStrong: Color(0xFF2C5A64),
    borderFocus: LoitPalette.mint300,
    borderDanger: LoitPalette.red400,
    success: LoitPalette.green400,
    warning: LoitPalette.amber400,
    danger: LoitPalette.red400,
    info: Color(0xFF5CC8E8), // cyan-shifted income/info — pops on petrol
    successSurface: Color(0xFF173D30),
    warningSurface: Color(0xFF2E2414),
    dangerSurface: Color(0xFF2E1A18),
    infoSurface: Color(0xFF16323A),
  );

  @override
  LoitColors copyWith({
    Color? canvas,
    Color? surface,
    Color? raised,
    Color? overlay,
    Color? muted,
    Color? inverse,
    Color? contentPrimary,
    Color? contentSecondary,
    Color? contentTertiary,
    Color? contentDisabled,
    Color? contentInverse,
    Color? brand,
    Color? accent,
    Color? borderSubtle,
    Color? borderDefault,
    Color? borderStrong,
    Color? borderFocus,
    Color? borderDanger,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? successSurface,
    Color? warningSurface,
    Color? dangerSurface,
    Color? infoSurface,
  }) {
    return LoitColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      overlay: overlay ?? this.overlay,
      muted: muted ?? this.muted,
      inverse: inverse ?? this.inverse,
      contentPrimary: contentPrimary ?? this.contentPrimary,
      contentSecondary: contentSecondary ?? this.contentSecondary,
      contentTertiary: contentTertiary ?? this.contentTertiary,
      contentDisabled: contentDisabled ?? this.contentDisabled,
      contentInverse: contentInverse ?? this.contentInverse,
      brand: brand ?? this.brand,
      accent: accent ?? this.accent,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderDefault: borderDefault ?? this.borderDefault,
      borderStrong: borderStrong ?? this.borderStrong,
      borderFocus: borderFocus ?? this.borderFocus,
      borderDanger: borderDanger ?? this.borderDanger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      successSurface: successSurface ?? this.successSurface,
      warningSurface: warningSurface ?? this.warningSurface,
      dangerSurface: dangerSurface ?? this.dangerSurface,
      infoSurface: infoSurface ?? this.infoSurface,
    );
  }

  @override
  LoitColors lerp(ThemeExtension<LoitColors>? other, double t) {
    if (other is! LoitColors) return this;
    return LoitColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      overlay: Color.lerp(overlay, other.overlay, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      inverse: Color.lerp(inverse, other.inverse, t)!,
      contentPrimary: Color.lerp(contentPrimary, other.contentPrimary, t)!,
      contentSecondary: Color.lerp(contentSecondary, other.contentSecondary, t)!,
      contentTertiary: Color.lerp(contentTertiary, other.contentTertiary, t)!,
      contentDisabled: Color.lerp(contentDisabled, other.contentDisabled, t)!,
      contentInverse: Color.lerp(contentInverse, other.contentInverse, t)!,
      brand: Color.lerp(brand, other.brand, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      borderDefault: Color.lerp(borderDefault, other.borderDefault, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      borderFocus: Color.lerp(borderFocus, other.borderFocus, t)!,
      borderDanger: Color.lerp(borderDanger, other.borderDanger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      dangerSurface: Color.lerp(dangerSurface, other.dangerSurface, t)!,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t)!,
    );
  }
}

extension LoitColorsX on BuildContext {
  LoitColors get loitColors =>
      Theme.of(this).extension<LoitColors>() ?? LoitColors.light;
}
