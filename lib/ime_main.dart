// lib/ime_main.dart
//
// IME Flutter entrypoint — separate from companion `main()`.

import 'package:flutter/material.dart';

import 'keyboard/dictionaries/dictionary_manager.dart';
import 'keyboard/keyboard_app.dart';

@pragma('vm:entry-point')
void imeMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: KeyboardApp(),
  ));
  // Upgrade embedded → asset dictionaries without blocking first frame.
  DictionaryManager.open();
}
