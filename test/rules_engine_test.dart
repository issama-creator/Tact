import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/dictionaries/mat_lexicon.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/panel/panel_state.dart';
import 'package:tact/keyboard/rules/rule_signal.dart';
import 'package:tact/keyboard/rules/rules_engine.dart';

void main() {
  const engine = RulesEngine();
  const range = EditRange(0, 4);

  List<RuleSignal> allSignals() => [
        RuleSignal(
          kind: SignalKind.spellError,
          severity: 80,
          confidence: 0.9,
          range: range,
          payload: const SpellPayload(word: 'helo', candidates: ['hello']),
        ),
        const RuleSignal(
          kind: SignalKind.mat,
          severity: 90,
          confidence: 0.9,
          range: range,
          payload: MatPayload(word: 'bad', level: MatLevel.warn),
        ),
        RuleSignal(
          kind: SignalKind.toxic,
          severity: 70,
          confidence: 0.7,
          range: range,
          payload: const ToxicPayload(
            word: 'idiot',
            level: ToxicLevel.warning,
            score: 70,
          ),
        ),
        const RuleSignal(
          kind: SignalKind.improve,
          severity: 40,
          confidence: 0.5,
          range: range,
        ),
        RuleSignal(
          kind: SignalKind.shortcutMatch,
          severity: 60,
          confidence: 1,
          range: range,
          payload: const ShortcutPayload(trigger: 'др', expansions: ['Доброе утро']),
        ),
      ];

  test('undo wins over everything', () {
    final d = engine.evaluate(
      signals: allSignals(),
      undoAvailable: true,
      defaultSuggestions: ['next'],
      nowMs: 0,
    );
    expect(d.state, isA<PanelUndo>());
  });

  test('priority spell > mat > toxic > improve > shortcut > suggestions', () {
    final signals = allSignals();
    expect(
      engine.evaluate(signals: signals, undoAvailable: false, defaultSuggestions: [], nowMs: 0).state,
      isA<PanelSpell>(),
    );
    expect(
      engine.evaluate(
        signals: signals.where((s) => s.kind != SignalKind.spellError).toList(),
        undoAvailable: false,
        defaultSuggestions: [],
        nowMs: 0,
      ).state,
      isA<PanelMat>(),
    );
    expect(
      engine.evaluate(
        signals: signals
            .where((s) => s.kind != SignalKind.spellError && s.kind != SignalKind.mat)
            .toList(),
        undoAvailable: false,
        defaultSuggestions: [],
        nowMs: 0,
      ).state,
      isA<PanelToxic>(),
    );
    expect(
      engine.evaluate(
        signals: signals
            .where((s) =>
                s.kind != SignalKind.spellError &&
                s.kind != SignalKind.mat &&
                s.kind != SignalKind.toxic)
            .toList(),
        undoAvailable: false,
        defaultSuggestions: [],
        nowMs: 0,
        messageLength: 40,
      ).state,
      isA<PanelImprove>(),
    );
    expect(
      engine.evaluate(
        signals: signals
            .where((s) =>
                s.kind != SignalKind.spellError &&
                s.kind != SignalKind.mat &&
                s.kind != SignalKind.toxic &&
                s.kind != SignalKind.improve)
            .toList(),
        undoAvailable: false,
        defaultSuggestions: [],
        nowMs: 0,
      ).state,
      isA<PanelShortcut>(),
    );
    expect(
      engine.evaluate(
        signals: const [],
        undoAvailable: false,
        defaultSuggestions: ['hello'],
        nowMs: 0,
      ).state,
      isA<PanelSuggestions>(),
    );
  });

  test('exactly one panel state is returned', () {
    final d = engine.evaluate(
      signals: allSignals(),
      undoAvailable: false,
      defaultSuggestions: ['a', 'b'],
      nowMs: 0,
    );
    expect(d.state, isA<PanelSpell>());
    expect(d.state, isNot(isA<PanelMat>()));
  });
}
