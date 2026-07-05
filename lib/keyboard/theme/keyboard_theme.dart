// lib/keyboard/theme/keyboard_theme.dart
//
// KeyboardTheme — Material 3 tokens for the keyboard surface.
//
// A compact struct that is applied to BOTH the Flutter suggestion bar and
// the native key grid (via ImeBridge.applyTheme). Keeping this small ensures
// keys and bar always agree visually.
//
// Contents (planned):
//   • class KeyboardTheme {
//       final Color background;
//       final Color keyBackground;
//       final Color keyText;
//       final Color accent;
//       final double keyRadius;
//       final Brightness brightness;      // dark first (see PRODUCT.md)
//     }
//   • Two built-in themes: `KeyboardTheme.darkDefault` and `KeyboardTheme.lightDefault`.
//
// Depends on: package:flutter/painting (for Color, Brightness) — this file
//   is a UI-adjacent value type, so Flutter import is allowed here.
// Must NOT: reference widgets.
//
// TODO: implement.
library;
