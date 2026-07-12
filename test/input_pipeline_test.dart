import 'package:flutter_test/flutter_test.dart';
import 'package:tact/core/bridge/ime_bridge_facade.dart';
import 'package:tact/keyboard/input/input_pipeline.dart';
import 'package:tact/keyboard/intelligence/local_intelligence_engine.dart';
import 'package:tact/keyboard/panel/panel_state.dart';

void main() {
  test('drops words shorter than 2 characters', () async {
    final field = FakeTextField();
    final bridge = ImeBridge(fakeField: field);
    final engine = LocalIntelligenceEngine();
    PanelState? last;
    final pipeline = InputPipeline(
      bridge: bridge,
      engine: engine,
      onPanel: (s) => last = s,
      settings: const PanelSettings(hysteresisMs: 0),
    );
    pipeline.start();
    bridge.emitWord(const WordEvent(word: 'h', locale: 'en'));
    await Future<void>.delayed(Duration.zero);
    expect(last, isNull);
    pipeline.dispose();
  });

  test('processes known word into suggestion panel', () async {
    final field = FakeTextField(text: 'say hello ');
    final bridge = ImeBridge(fakeField: field);
    final engine = LocalIntelligenceEngine();
    PanelState? last;
    final pipeline = InputPipeline(
      bridge: bridge,
      engine: engine,
      onPanel: (s) => last = s,
      settings: const PanelSettings(hysteresisMs: 0),
    );
    pipeline.start();
    bridge.emitWord(const WordEvent(
      word: 'hello',
      locale: 'en',
      deleteBefore: 6,
      boundary: ' ',
    ));
    await Future<void>.delayed(Duration.zero);
    expect(last, isA<PanelSuggestions>());
    pipeline.dispose();
  });

  test('uses native before buffer without waiting on host IC', () async {
    final bridge = ImeBridge(fakeField: FakeTextField());
    final engine = LocalIntelligenceEngine();
    PanelState? last;
    final pipeline = InputPipeline(
      bridge: bridge,
      engine: engine,
      onPanel: (s) => last = s,
      settings: const PanelSettings(hysteresisMs: 0),
    );
    pipeline.start();
    bridge.emitWord(const WordEvent(
      word: 'hello',
      locale: 'en',
      before: 'say ',
      boundary: ' ',
      deleteBefore: 6,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(last, isA<PanelSuggestions>());
    pipeline.dispose();
  });

  test('shows shortcut chip while typing partial trigger', () async {
    final bridge = ImeBridge(fakeField: FakeTextField());
    final engine = LocalIntelligenceEngine();
    PanelState? last;
    final pipeline = InputPipeline(
      bridge: bridge,
      engine: engine,
      onPanel: (s) => last = s,
      settings: const PanelSettings(hysteresisMs: 0),
    );
    pipeline.start();
    bridge.emitWord(const WordEvent(
      word: 'др',
      locale: 'ru',
      partial: true,
      deleteBefore: 2,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(last, isA<PanelShortcut>());
    pipeline.dispose();
  });

  test('partial shortcut does not replace committed mat panel', () async {
    final bridge = ImeBridge(fakeField: FakeTextField());
    final engine = LocalIntelligenceEngine();
    PanelState? last;
    final pipeline = InputPipeline(
      bridge: bridge,
      engine: engine,
      onPanel: (s) => last = s,
      settings: const PanelSettings(hysteresisMs: 0),
    );
    pipeline.start();
    bridge.emitWord(const WordEvent(
      word: 'сука',
      locale: 'ru',
      boundary: ' ',
      deleteBefore: 5,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(last, isA<PanelMat>());
    bridge.emitWord(const WordEvent(
      word: 'др',
      locale: 'ru',
      partial: true,
      deleteBefore: 2,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(last, isA<PanelMat>());
    pipeline.dispose();
  });

  test('empty field clear drops next-word suggestions', () async {
    final bridge = ImeBridge(fakeField: FakeTextField());
    final engine = LocalIntelligenceEngine();
    PanelState? last;
    final pipeline = InputPipeline(
      bridge: bridge,
      engine: engine,
      onPanel: (s) => last = s,
      settings: const PanelSettings(hysteresisMs: 0),
    );
    pipeline.start();
    bridge.emitWord(const WordEvent(
      word: 'hello',
      locale: 'en',
      boundary: ' ',
      deleteBefore: 6,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(last, isA<PanelSuggestions>());

    // Native only emits clear when commit buffer is empty.
    bridge.emitPartialWordClear();
    await Future<void>.delayed(Duration.zero);
    expect(last, isA<PanelIdle>());
    pipeline.dispose();
  });

  test('empty field clear drops dictionary chips including shortcuts', () async {
    final bridge = ImeBridge(fakeField: FakeTextField());
    final engine = LocalIntelligenceEngine();
    PanelState? last;
    final pipeline = InputPipeline(
      bridge: bridge,
      engine: engine,
      onPanel: (s) => last = s,
      settings: const PanelSettings(hysteresisMs: 0),
    );
    pipeline.start();
    bridge.emitWord(const WordEvent(
      word: 'др',
      locale: 'ru',
      boundary: ' ',
      deleteBefore: 3,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(last, isA<PanelShortcut>());
    bridge.emitPartialWordClear();
    await Future<void>.delayed(Duration.zero);
    expect(last, isA<PanelIdle>());
    pipeline.dispose();
  });

  test('empty field clear drops improve panel', () async {
    final bridge = ImeBridge(fakeField: FakeTextField());
    final engine = LocalIntelligenceEngine();
    PanelState? last;
    final pipeline = InputPipeline(
      bridge: bridge,
      engine: engine,
      onPanel: (s) => last = s,
      settings: const PanelSettings(hysteresisMs: 0),
    );
    pipeline.start();
    last = const PanelImprove(messageLength: 80);
    pipeline.adoptPanel(last!);
    expect(pipeline.panel, isA<PanelImprove>());

    bridge.emitPartialWordClear();
    await Future<void>.delayed(Duration.zero);
    expect(last, isA<PanelIdle>());
    expect(pipeline.panel, isA<PanelIdle>());
    pipeline.dispose();
  });

  test('keystroke bumps generation without clearing panel', () {
    final bridge = ImeBridge(fakeField: FakeTextField());
    final engine = LocalIntelligenceEngine();
    PanelState? last;
    final pipeline = InputPipeline(
      bridge: bridge,
      engine: engine,
      onPanel: (s) => last = s,
    );
    pipeline.adoptPanel(const PanelImprove(messageLength: 40));
    pipeline.onKeystroke();
    // Generation bump only — anchored/improve panels stay until validated.
    expect(pipeline.panel, isA<PanelImprove>());
    expect(last, isNull);
    pipeline.dispose();
  });
}
