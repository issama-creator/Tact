/// Shared keyboard surface colors — must match Android [Theme] palette.
library;

import 'package:flutter/material.dart';

abstract final class KeyboardTheme {
  /// Native `Theme.COLOR_KEYBOARD_BG`.
  static const Color keyboardBackground = Color(0xFF12141A);

  /// Native `Theme.COLOR_PANEL_BAR_BG`.
  static const Color panelBarBackground = Color(0xFF161920);

  /// Native `Theme.COLOR_KEY_ACCENT_BG` — enter / panel CTAs.
  static const Color accent = Color(0xFF2A9B8F);
}
