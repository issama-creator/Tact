// lib/ime_main.dart
//
// IME Flutter entrypoint.
//
// This top-level function is invoked by the native Kotlin side
// (FlutterEngineHost) when the pre-warmed FlutterEngine boots for the
// keyboard. It is a SEPARATE entrypoint from `main()` — the companion
// app boots `main()`, the keyboard boots `imeMain()`.
//
// The keyboard side hosts ONLY the suggestion bar. The key grid itself
// is rendered natively (Canvas) and is not part of this Flutter tree.
//
// Kept intentionally small: any allocation here happens on every keyboard
// open, so anything not required for the suggestion bar must not live in
// this file's imports.

import 'package:flutter/material.dart';

import 'keyboard/ui/suggestion_bar.dart';

@pragma('vm:entry-point')
void imeMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _ImeApp());
}

class _ImeApp extends StatelessWidget {
  const _ImeApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _fallbackKeyboardBg,
        splashFactory: NoSplash.splashFactory,
      ),
      home: const _ImeShell(),
    );
  }
}

/// Fallback color used before the native side pushes the current theme
/// via the bridge (which happens on `onAttachedToWindow`). Matches
/// [Theme.COLOR_KEYBOARD_BG] on the Kotlin side.
const Color _fallbackKeyboardBg = Color(0xFF171719);

class _ImeShell extends StatelessWidget {
  const _ImeShell();

  @override
  Widget build(BuildContext context) {
    // The IME window on Android already provides the visible surface —
    // we intentionally do NOT wrap in a Scaffold (which would add an
    // AppBar background and safe-area handling irrelevant to an IME).
    return const Material(
      color: _fallbackKeyboardBg,
      child: SuggestionBar(),
    );
  }
}
