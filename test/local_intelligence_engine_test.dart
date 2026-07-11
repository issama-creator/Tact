import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/dictionaries/mat_lexicon.dart';
import 'package:tact/keyboard/engines/shortcut_table.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/intelligence/local_intelligence_engine.dart';
import 'package:tact/keyboard/panel/panel_state.dart';
import 'package:tact/keyboard/rules/rule_signal.dart';

TextContext ctx(String word, {String locale = 'en', String before = ''}) =>
    TextContext(
      word: word,
      before: before,
      after: '',
      range: EditRange(before.length, before.length + word.length),
      locale: locale,
      fullMessage: '$before$word',
    );

void main() {
  test('unknown typo stays idle — no spell panel', () {
    final engine = LocalIntelligenceEngine();
    final result = engine.process(ctx('helo'));
    expect(result.decision.state, isA<PanelIdle>());
    expect(result.normalized, 'helo');
  });

  test('known word yields suggestions', () {
    final engine = LocalIntelligenceEngine();
    final result = engine.process(ctx('hello'));
    expect(result.dictionary.known, isTrue);
    expect(result.decision.state, isA<PanelSuggestions>());
  });

  test('mat detected in russian', () {
    final engine = LocalIntelligenceEngine();
    final result = engine.process(ctx('хуй', locale: 'ru'));
    expect(result.decision.state, isA<PanelMat>());
    final mat = result.signals.firstWhere((s) => s.kind == SignalKind.mat);
    expect((mat.payload as MatPayload).level, MatLevel.block);
  });

  test('warn mat detected for mild word', () {
    final engine = LocalIntelligenceEngine();
    final result = engine.process(ctx('сука', locale: 'ru'));
    expect(result.decision.state, isA<PanelMat>());
    final mat = result.signals.firstWhere((s) => s.kind == SignalKind.mat);
    expect((mat.payload as MatPayload).level, MatLevel.warn);
  });

  test('shortcut др works with user hotword', () {
    final engine = LocalIntelligenceEngine();
    engine.setUserShortcuts([
      const TextShortcut(
        trigger: 'др',
        expansions: ['Добрый день'],
        source: ShortcutSource.user,
      ),
    ]);
    final result = engine.process(ctx('др', locale: 'ru'));
    expect(result.decision.state, isA<PanelShortcut>());
    final panel = result.decision.state as PanelShortcut;
    expect(panel.expansions.first, 'Добрый день');
  });
}
