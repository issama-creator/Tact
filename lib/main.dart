// lib/main.dart — TACT companion app + IME entrypoint.

import 'package:flutter/material.dart';

import 'companion/companion_app.dart';
import 'ime_main.dart' show runImeKeyboard;

void main() {
  runApp(const CompanionApp());
}

/// Native IME isolate entry — must live in [main.dart] so the kernel
/// always resolves `lib/main.dart` (see [FlutterEngineHost] on Android).
@pragma('vm:entry-point')
void imeMain() {
  runImeKeyboard();
}
