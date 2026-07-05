import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/engines/shortcut_engine.dart';
import 'package:tact/keyboard/engines/shortcut_table.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/rules/rule_signal.dart';

TextContext ctx(String word) => TextContext(
      word: word,
      before: '',
      after: '',
      range: EditRange(0, word.length),
      locale: 'ru',
      fullMessage: word,
    );

void main() {
  test('user hotword matches after space', () {
    final table = ShortcutTable(
      builtin: const {},
      user: [
        const TextShortcut(
          trigger: 'др',
          expansions: ['Добрый день'],
          source: ShortcutSource.user,
        ),
      ],
    );
    final engine = ShortcutEngine(table);
    final signals = engine.analyze(ctx('др'));
    expect(signals, hasLength(1));
    final payload = signals.first.payload! as ShortcutPayload;
    expect(payload.expansions.first, 'Добрый день');
  });

  test('user shortcut overrides builtin', () {
    final table = ShortcutTable(
      builtin: {
        'др': const TextShortcut(trigger: 'др', expansions: ['Built-in']),
      },
      user: [
        const TextShortcut(
          trigger: 'др',
          expansions: ['User win'],
          source: ShortcutSource.user,
        ),
      ],
    );
    final engine = ShortcutEngine(table);
    final payload = engine.analyze(ctx('др')).first.payload! as ShortcutPayload;
    expect(payload.expansions.first, 'User win');
  });

  test('single-char trigger does not match', () {
    final engine = ShortcutEngine(ShortcutTable.defaults());
    expect(engine.analyze(ctx('д')), isEmpty);
  });

  test('non-triggers produce no signal', () {
    final engine = ShortcutEngine(ShortcutTable.defaults());
    expect(engine.analyze(ctx('другое')), isEmpty);
  });
}
