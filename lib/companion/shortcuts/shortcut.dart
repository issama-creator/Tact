// lib/companion/shortcuts/shortcut.dart
//
// UserShortcut — the entity for a user-defined shortcut.
//
// Contents (planned):
//   • class UserShortcut {
//       final String id;
//       final String trigger;
//       final String expansion;
//       final DateTime createdAt;
//       final DateTime updatedAt;
//       UserShortcut copyWith({...});
//       Map<String, dynamic> toJson();
//       factory UserShortcut.fromJson(Map<String, dynamic> json);
//     }
//
// Note:
//   Built-in shortcuts are loaded from assets/shortcuts/builtin.json and
//   are read-only. They share the same trigger/expansion shape but do not
//   need an id or timestamps.
//
// Depends on: nothing.
// Must NOT: import Flutter or plugins.
//
// TODO: implement.
library;
