/// Built-in and user text shortcuts.
library;

import '../dictionaries/dictionary_manager.dart';

enum ShortcutSource { builtin, user }

final class TextShortcut {
  const TextShortcut({
    required this.trigger,
    required this.expansions,
    this.source = ShortcutSource.builtin,
    this.id,
  });

  final String trigger;
  final List<String> expansions;
  final ShortcutSource source;
  final String? id;
}

/// Loads shortcuts once from in-memory tables (builtin) plus optional user list.
final class ShortcutTable {
  ShortcutTable({
    required Map<String, TextShortcut> builtin,
    Iterable<TextShortcut> user = const [],
  }) : _byTrigger = _merge(builtin, user);

  final Map<String, TextShortcut> _byTrigger;

  TextShortcut? lookup(String trigger) => _byTrigger[trigger.toLowerCase()];

  static Map<String, TextShortcut> _merge(
    Map<String, TextShortcut> builtin,
    Iterable<TextShortcut> user,
  ) {
    final map = Map<String, TextShortcut>.from(builtin);
    for (final s in user) {
      map[s.trigger.toLowerCase()] = s;
    }
    return Map.unmodifiable(map);
  }

  factory ShortcutTable.defaults() {
    return ShortcutTable(builtin: DictionaryManager.shared.builtinShortcuts);
  }
}

/// Optional built-in examples — user hotwords always override these.
Map<String, TextShortcut> get defaultBuiltinShortcuts =>
    DictionaryManager.shared.builtinShortcuts;
