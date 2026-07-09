/// Shared keyboard surface colors — must match [Theme.COLOR_KEYBOARD_BG] on Android.
library;

import 'package:flutter/material.dart';

abstract final class KeyboardTheme {
  /// Native `Theme.COLOR_KEYBOARD_BG` / FlutterView + key grid background.
  static const Color keyboardBackground = Color(0xFF171719);

  /// Suggestion strip — soft lift from keys, easy on the eyes.
  static const Color panelBarBackground = Color(0xFF1A1921);
}
