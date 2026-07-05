// lib/keyboard/theme/key_layout.dart
//
// KeyboardLayoutSpec — the shared, declarative description of a key layout.
//
// One layout spec drives BOTH the Flutter-side layout debug preview (in the
// companion) AND the native KeyGridView renderer (via ImeBridge.applyLayout).
// This is how TACT achieves >80% shared code while keeping key rendering
// native for latency.
//
// Data comes from `assets/layouts/*.json`. Adding a new layout = adding a
// new JSON file + declaring it in settings. No code change.
//
// Contents (planned):
//   • class KeyDef { String label; String? shifted; int? code; double weight; List<String> longPress; }
//   • class KeyRow { List<KeyDef> keys; double height; }
//   • class KeyboardLayoutSpec {
//       final String id;
//       final String locale;
//       final List<KeyRow> rows;
//       static KeyboardLayoutSpec fromJson(Map<String, dynamic> json);
//     }
//
// Depends on: nothing (pure data).
// Must NOT: import Flutter widgets. Colors/rendering are in keyboard_theme.dart.
//
// TODO: implement.
library;
