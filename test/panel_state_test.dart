import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/panel/panel_state.dart';

void main() {
  test('hysteresis keeps previous state inside window', () {
    const prev = PanelSpell(
      word: 'helo',
      candidates: ['hello'],
      range: EditRange(0, 4),
    );
    const next = PanelDecision(
      state: PanelMat(word: 'bad', range: EditRange(0, 3)),
      producedAtMs: 150,
    );
    final reduced = reducePanel(
      previous: prev,
      next: next,
      settings: const PanelSettings(hysteresisMs: 200),
      nowMs: 150,
      lastChangeMs: 0,
    );
    expect(reduced, isA<PanelSpell>());
  });

  test('hysteresis allows change after window', () {
    const prev = PanelSpell(
      word: 'helo',
      candidates: ['hello'],
      range: EditRange(0, 4),
    );
    const next = PanelDecision(
      state: PanelMat(word: 'bad', range: EditRange(0, 3)),
      producedAtMs: 300,
    );
    final reduced = reducePanel(
      previous: prev,
      next: next,
      settings: const PanelSettings(hysteresisMs: 200),
      nowMs: 300,
      lastChangeMs: 0,
    );
    expect(reduced, isA<PanelMat>());
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
        const PanelSpell(word: 'a', candidates: ['b'], range: EditRange(0, 1)),
        const PanelMat(word: 'a', range: EditRange(0, 1)),
      ),
      isFalse,
    );
  });
}
