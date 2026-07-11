import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/panel/panel_state.dart';
import 'package:tact/keyboard/rules/rule_signal.dart';

void main() {
  test('hysteresis keeps previous state inside window', () {
    const prev = PanelMat(word: 'bad', range: EditRange(0, 3));
    const next = PanelDecision(
      state: PanelToxic(
        word: 'idiot',
        level: ToxicLevel.warning,
        score: 70,
        range: EditRange(0, 5),
      ),
      producedAtMs: 150,
    );
    final reduced = reducePanel(
      previous: prev,
      next: next,
      settings: const PanelSettings(hysteresisMs: 200),
      nowMs: 150,
      lastChangeMs: 0,
    );
    expect(reduced, isA<PanelMat>());
  });

  test('hysteresis allows change after window', () {
    const prev = PanelMat(word: 'bad', range: EditRange(0, 3));
    const next = PanelDecision(
      state: PanelSuggestions(words: ['hello']),
      producedAtMs: 300,
    );
    final reduced = reducePanel(
      previous: prev,
      next: next,
      settings: const PanelSettings(hysteresisMs: 200),
      nowMs: 300,
      lastChangeMs: 0,
    );
    expect(reduced, isA<PanelSuggestions>());
  });

  test('idle always accepts next state', () {
    const next = PanelDecision(
      state: PanelSuggestions(words: ['hello']),
      producedAtMs: 1,
    );
    final reduced = reducePanel(
      previous: const PanelIdle(),
      next: next,
      settings: const PanelSettings(),
      nowMs: 1,
      lastChangeMs: null,
    );
    expect(reduced, isA<PanelSuggestions>());
  });

  test('panelModesEqual distinguishes kinds', () {
    expect(
      panelModesEqual(const PanelIdle(), const PanelIdle()),
      isTrue,
    );
    expect(
      panelModesEqual(
        const PanelMat(word: 'a', range: EditRange(0, 1)),
        const PanelSuggestions(words: ['a']),
      ),
      isFalse,
    );
  });
}
