/// Shortcut expansion detection on completed words.
library;

import '../input/word_length_policy.dart';
import '../input/text_context.dart';
import '../rules/rule_signal.dart';
import 'shortcut_table.dart';
import 'signal_provider.dart';

final class ShortcutEngine implements SignalProvider {
  ShortcutEngine(this._table);

  final ShortcutTable _table;

  @override
  List<RuleSignal> analyze(TextContext ctx) {
    final trigger = ctx.word;
    if (trigger.length < kMinShortcutTriggerLength) return const [];

    final match = _table.lookup(trigger.toLowerCase());
    if (match == null) return const [];

    return [
      RuleSignal(
        kind: SignalKind.shortcutMatch,
        severity: 70,
        confidence: 1.0,
        range: ctx.range,
        payload: ShortcutPayload(
          trigger: match.trigger,
          expansions: match.expansions,
        ),
      ),
    ];
  }
}
