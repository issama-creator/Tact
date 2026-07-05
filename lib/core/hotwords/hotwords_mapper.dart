/// Maps stored hotwords into keyboard [TextShortcut] entries.
library;

import '../../keyboard/engines/shortcut_table.dart';
import 'user_hotword.dart';

abstract final class HotwordsMapper {
  /// Groups by trigger; newest user entries first; max [maxPerTrigger] each.
  static List<TextShortcut> toTextShortcuts(
    List<UserHotword> hotwords, {
    int maxPerTrigger = 3,
  }) {
    final grouped = <String, List<UserHotword>>{};
    for (final hw in hotwords) {
      final key = hw.trigger.toLowerCase();
      grouped.putIfAbsent(key, () => []).add(hw);
    }

    final result = <TextShortcut>[];
    for (final entry in grouped.entries) {
      final expansions = entry.value
          .map((h) => h.expansion)
          .take(maxPerTrigger)
          .toList();
      if (expansions.isEmpty) continue;
      result.add(
        TextShortcut(
          trigger: entry.value.first.trigger,
          expansions: expansions,
          source: ShortcutSource.user,
          id: entry.value.first.id,
        ),
      );
    }
    return result;
  }
}
