// lib/core/bridge/ime_bridge_facade.dart
//
// Ergonomic Dart-side API on top of the generated Pigeon stubs.
//
// Purpose:
//   Everything in `lib/keyboard/**` talks to the platform through THIS facade
//   only. The generated `ime_bridge.g.dart` file is an implementation detail.
//
// Responsibilities:
//   • Exposes typed methods for text mutations (commit, delete, replaceRange).
//   • Exposes typed event streams for word-committed, selection-changed,
//     action-tapped, and lifecycle callbacks.
//   • Batches high-frequency events where possible.
//   • Never per-keystroke: keypress-to-glyph never enters Dart.
//
// Contents (planned):
//   • class ImeBridge (singleton)
//       - Future<void> commit(String text);
//       - Future<void> replaceRange(int start, int end, String replacement);
//       - Future<void> setComposing(String text);
//       - Future<TextSnapshot> surrounding({int before, int after});
//       - Stream<WordEvent> get onWordCommitted;
//       - Stream<ActionKind> get onActionTapped;
//       - Stream<LifecycleEvent> get lifecycle;
//
// Depends on: core/bridge/ime_bridge.g.dart.
// Must NOT: contain business logic. Facade only.
//
// TODO: implement.
library;
