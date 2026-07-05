import 'package:flutter_test/flutter_test.dart';
import 'package:tact/core/bridge/ime_bridge_facade.dart';
import 'package:tact/keyboard/input/input_pipeline.dart';
import 'package:tact/keyboard/intelligence/local_intelligence_engine.dart';
import 'package:tact/keyboard/panel/panel_state.dart';

/// End-to-end state chain: bridge event → pipeline → panel state.
void main() {
  late ImeBridge bridge;
  late LocalIntelligenceEngine engine;
  late InputPipeline pipeline;
  late List<PanelState> states;

  setUp(() {
    bridge = ImeBridge(fakeField: FakeTextField());
    engine = LocalIntelligenceEngine();
    states = [];
    pipeline = InputPipeline(
      bridge: bridge,
      engine: engine,
      onPanel: states.add,
      settings: const PanelSettings(hysteresisMs: 0),
    );
    pipeline.start();
  });

  tearDown(() {
    pipeline.dispose();
    bridge.dispose();
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  Future<void> commit(String word, String locale) async {
    bridge.emitWord(WordEvent(
      word: word,
      locale: locale,
      boundary: ' ',
      deleteBefore: word.length + 1,
    ));
    await flush();
  }

  test('mat word on ru locale produces PanelMat', () async {
    await commit('хуй', 'ru');
    expect(states.last, isA<PanelMat>());
    expect((states.last as PanelMat).word, 'хуй');
  });

  test('mat word on en locale stays idle', () async {
    await commit('хуй', 'en');
    expect(states.last, isA<PanelIdle>());
  });

  test('shortcut trigger produces PanelShortcut', () async {
    await commit('др', 'ru');
    expect(states.last, isA<PanelShortcut>());
    expect((states.last as PanelShortcut).trigger, 'др');
    expect((states.last as PanelShortcut).expansions, isNotEmpty);
  });

  test('known word produces PanelSuggestions', () async {
    await commit('привет', 'ru');
    expect(states.last, isA<PanelSuggestions>());
    expect((states.last as PanelSuggestions).words, isNotEmpty);
  });

  test('typo produces PanelSpell', () async {
    await commit('helo', 'en');
    expect(states.last, isA<PanelSpell>());
    expect((states.last as PanelSpell).candidates, isNotEmpty);
  });

  test('sequence of commits updates state each time', () async {
    await commit('хуй', 'ru');
    expect(states.last, isA<PanelMat>());

    await commit('привет', 'ru');
    expect(states.last, isA<PanelSuggestions>());

    await commit('др', 'ru');
    expect(states.last, isA<PanelShortcut>());

    expect(states.length, greaterThanOrEqualTo(3));
  });

  test('partial clear does not wipe committed shortcut', () async {
    bridge.dispose();
    pipeline.dispose();
    bridge = ImeBridge(
      fakeField: FakeTextField(text: 'др ', selectionStart: 3, selectionEnd: 3),
    );
    states = [];
    pipeline = InputPipeline(
      bridge: bridge,
      engine: engine,
      onPanel: states.add,
      settings: const PanelSettings(hysteresisMs: 0),
    );
    pipeline.start();

    await commit('др', 'ru');
    expect(states.last, isA<PanelShortcut>());

    bridge.emitPartialWordClear();
    await flush();

    expect(states.last, isA<PanelShortcut>());
  });

  test('field finished resets to PanelIdle', () async {
    await commit('хуй', 'ru');
    expect(states.last, isA<PanelMat>());

    pipeline.onFieldFinished();
    expect(states.last, isA<PanelIdle>());
  });

  test('clears mat panel when user deletes anchored word', () async {
    final field = FakeTextField(text: 'oh хуй ', selectionStart: 7, selectionEnd: 7);
    bridge.dispose();
    pipeline.dispose();
    bridge = ImeBridge(fakeField: field);
    states = [];
    pipeline = InputPipeline(
      bridge: bridge,
      engine: engine,
      onPanel: states.add,
      settings: const PanelSettings(hysteresisMs: 0),
    );
    pipeline.start();

    bridge.emitWord(const WordEvent(
      word: 'хуй',
      locale: 'ru',
      before: 'oh ',
      boundary: ' ',
      deleteBefore: 4,
    ));
    await flush();
    expect(states.last, isA<PanelMat>());

    field.deleteSurrounding(4, 0);
    bridge.emitTextEdited();
    await flush();

    expect(states.last, isA<PanelIdle>());
  });
}
