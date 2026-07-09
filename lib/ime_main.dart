// lib/ime_main.dart — IME bootstrap (invoked from [main.dart] entrypoint).

import 'package:flutter/material.dart';

import 'keyboard/keyboard_app.dart';
import 'keyboard/theme/keyboard_theme.dart';

/// Starts the suggestion-bar Flutter tree inside the IME isolate.
void runImeKeyboard() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[TACT IME] imeMain started');
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: KeyboardTheme.keyboardBackground,
    ),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.noScaling,
        platformBrightness: Brightness.dark,
      ),
      child: child ?? const SizedBox.shrink(),
    ),
    home: const KeyboardApp(),
  ));
}
