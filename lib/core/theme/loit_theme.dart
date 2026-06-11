import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'loit_colors.dart';
import 'loit_radius.dart';
import 'loit_typography.dart';

/// Builds [ThemeData] for light and dark modes from LOIT design tokens.
class LoitTheme {
  LoitTheme._();

  static ThemeData light() => _build(LoitColors.light, Brightness.light);
  static ThemeData dark() => _build(LoitColors.dark, Brightness.dark);

  static ThemeData _build(LoitColors c, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.brand,
      onPrimary: c.contentInverse,
      primaryContainer: isDark ? c.surface : c.muted,
      onPrimaryContainer: c.contentPrimary,
      secondary: c.accent,
      onSecondary: c.contentInverse,
      secondaryContainer: isDark ? c.surface : c.muted,
      onSecondaryContainer: c.contentPrimary,
      tertiary: c.info,
      onTertiary: c.contentInverse,
      error: c.danger,
      onError: c.contentInverse,
      errorContainer: c.dangerSurface,
      onErrorContainer: c.danger,
      surface: c.surface,
      onSurface: c.contentPrimary,
      surfaceContainerHighest: c.muted,
      surfaceContainerHigh: c.raised,
      surfaceContainer: c.surface,
      surfaceContainerLow: c.canvas,
      surfaceContainerLowest: c.canvas,
      onSurfaceVariant: c.contentSecondary,
      outline: c.borderDefault,
      outlineVariant: c.borderSubtle,
      shadow: const Color(0xFF111613),
      scrim: const Color(0x80000000),
      inverseSurface: c.inverse,
      onInverseSurface: c.contentInverse,
      inversePrimary: isDark ? c.brand : LoitColors.dark.brand,
    );

    final textTheme = LoitTypography.textTheme(c.contentPrimary);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.canvas,
      canvasColor: c.canvas,
      dividerColor: c.borderSubtle,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.canvas,
        foregroundColor: c.contentPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: LoitTypography.titleM.copyWith(color: c.contentPrimary),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: c.contentPrimary),
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: c.borderSubtle),
          borderRadius: LoitRadius.brL,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: c.contentInverse,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: LoitRadius.brM),
          textStyle: LoitTypography.labelL,
          minimumSize: const Size(0, 44),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: c.contentInverse,
          shape: RoundedRectangleBorder(borderRadius: LoitRadius.brM),
          textStyle: LoitTypography.labelL,
          minimumSize: const Size(0, 44),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.contentPrimary,
          side: BorderSide(color: c.borderDefault),
          shape: RoundedRectangleBorder(borderRadius: LoitRadius.brM),
          textStyle: LoitTypography.labelL,
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.brand,
          textStyle: LoitTypography.labelL,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      iconTheme: IconThemeData(color: c.contentPrimary, size: 20),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: c.contentPrimary,
          minimumSize: const Size(44, 44),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hintStyle: LoitTypography.bodyM.copyWith(color: c.contentTertiary),
        labelStyle: LoitTypography.labelL.copyWith(color: c.contentSecondary),
        border: OutlineInputBorder(
          borderRadius: LoitRadius.brM,
          borderSide: BorderSide(color: c.borderDefault),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: LoitRadius.brM,
          borderSide: BorderSide(color: c.borderDefault),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: LoitRadius.brM,
          borderSide: BorderSide(color: c.borderFocus, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: LoitRadius.brM,
          borderSide: BorderSide(color: c.borderDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: LoitRadius.brM,
          borderSide: BorderSide(color: c.borderDanger, width: 1.5),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: c.muted,
        side: BorderSide(color: c.borderSubtle),
        shape: RoundedRectangleBorder(borderRadius: LoitRadius.brFull),
        labelStyle: LoitTypography.labelM.copyWith(color: c.contentPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.overlay,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: LoitRadius.brSheet),
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: c.borderDefault,
      ),
      dividerTheme: DividerThemeData(
        color: c.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.muted,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 64,
        labelTextStyle: WidgetStatePropertyAll(
          LoitTypography.labelS.copyWith(color: c.contentPrimary),
        ),
        iconTheme: WidgetStatePropertyAll(
          IconThemeData(color: c.contentPrimary, size: 22),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: c.accent,
        foregroundColor: Colors.white,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        shape: const CircleBorder(),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.inverse,
        contentTextStyle:
            LoitTypography.bodyM.copyWith(color: c.contentInverse),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: LoitRadius.brM),
        elevation: 4,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.brand,
        linearTrackColor: c.muted,
        circularTrackColor: c.muted,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          // Mint track is a light fill → dark thumb (see ADR 0006 invariant).
          (s) => s.contains(WidgetState.selected) ? c.contentInverse : c.surface,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.brand : c.borderDefault,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: LoitRadius.brXs),
        side: BorderSide(color: c.borderStrong, width: 1.5),
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? c.brand
              : Colors.transparent,
        ),
        // Mint fill is light → dark check glyph (see ADR 0006 invariant).
        checkColor: WidgetStatePropertyAll(c.contentInverse),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.brand : c.borderStrong,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: c.contentPrimary,
        unselectedLabelColor: c.contentTertiary,
        indicatorColor: c.brand,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: LoitTypography.labelL,
        unselectedLabelStyle: LoitTypography.labelL,
        dividerColor: c.borderSubtle,
      ),
      splashFactory: InkRipple.splashFactory,
      visualDensity: VisualDensity.standard,
    );
  }
}
