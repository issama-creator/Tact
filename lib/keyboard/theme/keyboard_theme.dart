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
    required this.chipBg,
    required this.stroke,
  });

  final Color background;
  final Color accent;
  final Color keyText;
  final Color keyTextMuted;
  /// Native letter-key fill — used for suggestion / AI chips.
  final Color chipBg;
  /// Native key stroke (ARGB, may include alpha).
  final Color stroke;

  bool get isLight =>
      ThemeData.estimateBrightnessForColor(background) == Brightness.light;

  Color get border => stroke;

  Color get divider => isLight
      ? const Color(0xFFD1D5DB)
      : Color.lerp(stroke, keyTextMuted, 0.45) ?? stroke;

  static const defaults = KeyboardSurfaceTheme(
    background: Color(0xFF12141A),
    accent: Color(0xFF2A9B8F),
    keyText: Color(0xFFF2F3F5),
    keyTextMuted: Color(0xFF8B929C),
    chipBg: Color(0xFF2A2E36),
    stroke: Color(0x28FFFFFF),
  );

  /// Companion [KeyboardThemeStyle.light] — for tests and previews.
  static const light = KeyboardSurfaceTheme(
    background: Color(0xFFF3F4F6),
    accent: Color(0xFF2A9B8F),
    keyText: Color(0xFF1F2937),
    keyTextMuted: Color(0xFF6B7280),
    chipBg: Color(0xFFFFFFFF),
    stroke: Color(0x22000000),
  );

  /// Companion [KeyboardThemeStyle.midnight] — for tests and previews.
  static const midnight = KeyboardSurfaceTheme(
    background: Color(0xFF1E1B4B),
    accent: Color(0xFF8B5CF6),
    keyText: Color(0xFFF5F3FF),
    keyTextMuted: Color(0xFFA5B4FC),
    chipBg: Color(0xFF3730A3),
    stroke: Color(0x30FFFFFF),
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
      chipBg: c('chipBg', defaults.chipBg),
      stroke: c('stroke', defaults.stroke),
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
