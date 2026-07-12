/// Shared keyboard surface colors — synced from native [Theme] via setTheme.
library;

import 'package:flutter/material.dart';

/// Live palette for the suggestion bar (updated when companion picks a theme).
final class KeyboardSurfaceTheme {
  const KeyboardSurfaceTheme({
    required this.background,
    required this.accent,
    required this.keyText,
    required this.keyTextMuted,
  });

  final Color background;
  final Color accent;
  final Color keyText;
  final Color keyTextMuted;

  bool get isLight =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.light;

  Color get chipBg =>
      isLight ? const Color(0xFFFFFFFF) : const Color(0xFF2A2E36);

  Color get border =>
      isLight ? const Color(0x22000000) : const Color(0xFF252A32);

  Color get divider =>
      isLight ? const Color(0xFFD1D5DB) : const Color(0xFF3A4048);

  static const defaults = KeyboardSurfaceTheme(
    background: Color(0xFF12141A),
    accent: Color(0xFF2A9B8F),
    keyText: Color(0xFFE8EAED),
    keyTextMuted: Color(0xFF8B929C),
  );

  factory KeyboardSurfaceTheme.fromArgbMap(Map<String, dynamic> map) {
    Color c(String key, Color fallback) {
      final v = map[key];
      final int? argb = switch (v) {
        final int i => i,
        final double d => d.toInt(),
        _ => null,
      };
      if (argb == null) return fallback;
      return Color(argb & 0xFFFFFFFF);
    }

    return KeyboardSurfaceTheme(
      background: c('background', defaults.background),
      accent: c('accent', defaults.accent),
      keyText: c('keyText', defaults.keyText),
      keyTextMuted: c('keyTextMuted', defaults.keyTextMuted),
    );
  }
}

abstract final class KeyboardTheme {
  /// Native `Theme.COLOR_KEYBOARD_BG` (dark default).
  static const Color keyboardBackground = Color(0xFF12141A);

  /// Native `Theme.COLOR_PANEL_BAR_BG` (dark default).
  static const Color panelBarBackground = Color(0xFF12141A);

  /// Native `Theme.COLOR_KEY_ACCENT_BG` — enter / panel CTAs.
  static const Color accent = Color(0xFF2A9B8F);
}
