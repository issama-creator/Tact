// lib/keyboard/engines/shortcut_engine.dart
//
// ShortcutEngine — implements SignalProvider.
//
// Emits SignalKind.shortcutMatch when the just-completed word exactly matches
// a shortcut trigger. Two sources merged:
//   • Built-in shortcuts (assets/shortcuts/builtin.json), read-only.
//   • User shortcuts (companion/shortcuts/shortcuts_repository).
//
// The panel offers the expansion. If the user has "auto-expand" enabled in
// settings, the action is applied as a single UndoStack entry — never
// silently.
//
// Contents (planned):
//   • class Shortcut { final String trigger; final String expansion; final ShortcutSource source; }
//   • class ShortcutEngine implements SignalProvider {
//       ShortcutEngine(this._builtin, this._user);
//       final Map<String, Shortcut> _byTrigger;
//       @override List<RuleSignal> analyze(TextContext ctx);
//     }
//
// Depends on: engines/signal_provider.dart, companion/shortcuts/shortcuts_repository.dart.
// Must NOT: import Flutter or plugins.
//
// TODO: implement.
library;
