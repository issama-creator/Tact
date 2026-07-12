import 'package:flutter/material.dart';

/// Visual tokens for companion keyboard theme previews.
class KeyboardThemeStyle {
  const KeyboardThemeStyle({
    required this.name,
    required this.background,
    required this.letterKey,
    required this.functionKey,
    required this.keyText,
    required this.keyTextMuted,
    required this.accent,
    required this.panel,
    required this.stroke,
  });

  final String name;
  final Color background;
  final Color letterKey;
  final Color functionKey;
  final Color keyText;
  final Color keyTextMuted;
  final Color accent;
  final Color panel;
  final Color stroke;

  static const dark = KeyboardThemeStyle(
    name: 'Тёмная',
    background: Color(0xFF12141A),
    letterKey: Color(0xFF2A2E36),
    functionKey: Color(0xFF1C2028),
    keyText: Color(0xFFF2F3F5),
    keyTextMuted: Color(0xFF8B929C),
    accent: Color(0xFF2A9B8F),
    panel: Color(0xFF12141A),
    stroke: Color(0x28FFFFFF),
  );

  static const light = KeyboardThemeStyle(
    name: 'Светлая',
    background: Color(0xFFF3F4F6),
    letterKey: Color(0xFFFFFFFF),
    functionKey: Color(0xFFE5E7EB),
    keyText: Color(0xFF1F2937),
    keyTextMuted: Color(0xFF6B7280),
    accent: Color(0xFF2A9B8F),
    panel: Color(0xFFF3F4F6),
    stroke: Color(0x22000000),
  );

  static const midnight = KeyboardThemeStyle(
    name: 'Midnight',
    background: Color(0xFF1E1B4B),
    letterKey: Color(0xFF3730A3),
    functionKey: Color(0xFF15132F),
    keyText: Color(0xFFF5F3FF),
    keyTextMuted: Color(0xFFA5B4FC),
    accent: Color(0xFF8B5CF6),
    panel: Color(0xFF1E1B4B),
    stroke: Color(0x30FFFFFF),
  );

  static const graphite = KeyboardThemeStyle(
    name: 'Graphite',
    background: Color(0xFF27272A),
    letterKey: Color(0xFF3F3F46),
    functionKey: Color(0xFF1F1F23),
    keyText: Color(0xFFF4F4F5),
    keyTextMuted: Color(0xFFA1A1AA),
    accent: Color(0xFF2A9B8F),
    panel: Color(0xFF27272A),
    stroke: Color(0x28FFFFFF),
  );

  static const List<KeyboardThemeStyle> all = [
    dark,
    light,
    midnight,
    graphite,
  ];
}
