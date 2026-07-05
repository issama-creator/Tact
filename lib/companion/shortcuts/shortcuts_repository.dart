// lib/companion/shortcuts/shortcuts_repository.dart
//
// ShortcutsRepository — local storage of user shortcuts.
//
// Contents (planned):
//   • abstract class ShortcutsRepository {
//       Future<List<UserShortcut>> all();
//       Future<UserShortcut?> byTrigger(String trigger);
//       Future<void> upsert(UserShortcut s);
//       Future<void> delete(String id);
//       Stream<List<UserShortcut>> watch();
//     }
//   • Concrete impl over sqflite or shared_preferences (small size expected).
//     Choice deferred until first implementation — the interface hides it.
//
// Read on both sides:
//   • Companion: CRUD in shortcuts_screen.dart.
//   • IME: ShortcutEngine merges these with built-in shortcuts.
//
// Depends on: companion/shortcuts/shortcut.dart, core/kv_store.dart (or DB).
// Must NOT: import Flutter widgets.
//
// TODO: implement.
library;
