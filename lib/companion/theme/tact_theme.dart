import 'package:flutter/material.dart';

/// Spacing and touch-target constants (Material / HIG: 48dp minimum).
abstract final class TactLayout {
  static const minTouchTarget = 48.0;
  static const screenPadding = 16.0;
  static const sectionGap = 24.0;
  static const itemGap = 12.0;
  static const cardRadius = 16.0;
}

/// Design tokens matching the TACT companion mockups.
abstract final class TactColors {
  static const background = Color(0xFF07070A);
  static const surface = Color(0xFF14141A);
  static const surfaceElevated = Color(0xFF1C1C24);
  static const surfaceBorder = Color(0xFF2A2A34);

  static const textPrimary = Color(0xFFF4F4F5);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF6B7280);

  static const purple = Color(0xFF8B5CF6);
  static const purpleDim = Color(0xFF6D28D9);
  static const purpleGlow = Color(0x338B5CF6);

  static const orange = Color(0xFFF97316);
  static const blue = Color(0xFF3B82F6);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const yellow = Color(0xFFFACC15);
  static const gold = Color(0xFFEAB308);

  static const scoreRing = Color(0xFF4ADE80);
  static const chatOutgoing = Color(0xFF3B82F6);
  static const chatIncoming = Color(0xFF2A2A34);
}

ThemeData buildTactTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: TactColors.background,
    colorScheme: const ColorScheme.dark(
      surface: TactColors.surface,
      onSurface: TactColors.textPrimary,
      primary: TactColors.purple,
      onPrimary: Colors.white,
      secondary: TactColors.purpleDim,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: TactColors.background,
      foregroundColor: TactColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: TactColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: TactColors.surfaceBorder, width: 0.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return const Color(0xFF9CA3AF);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return TactColors.purple;
        return const Color(0xFF3F3F46);
      }),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: TactColors.purple,
      inactiveTrackColor: Color(0xFF3F3F46),
      thumbColor: TactColors.purple,
      overlayColor: TactColors.purpleGlow,
    ),
    dividerColor: TactColors.surfaceBorder,
    fontFamily: 'Roboto',
    splashFactory: InkSparkle.splashFactory,
    highlightColor: TactColors.purple.withValues(alpha: 0.08),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(TactLayout.minTouchTarget, TactLayout.minTouchTarget),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, TactLayout.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, TactLayout.minTouchTarget),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: TactColors.surfaceElevated,
      labelStyle: const TextStyle(color: TactColors.textSecondary),
      hintStyle: const TextStyle(color: TactColors.textMuted),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TactColors.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TactColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: TactColors.purple, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: TactColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      showDragHandle: true,
      dragHandleColor: TactColors.textMuted,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
