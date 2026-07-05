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

  test('processes valid word into panel state', () async {
    final field = FakeTextField(text: 'say helo ');
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
      word: 'helo',
      locale: 'en',
      deleteBefore: 5,
      boundary: ' ',
    ));
    await Future<void>.delayed(Duration.zero);
    expect(last, isA<PanelSpell>());
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
      word: 'helo',
      locale: 'en',
      before: 'say ',
      boundary: ' ',
      deleteBefore: 5,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(last, isA<PanelSpell>());
    pipeline.dispose();
  });

  test('keystroke clears panel', () {
    final bridge = ImeBridge(fakeField: FakeTextField());
    final engine = LocalIntelligenceEngine();
    PanelState? last;
    final pipeline = InputPipeline(
      bridge: bridge,
      engine: engine,
      onPanel: (s) => last = s,
    );
    pipeline.onKeystroke();
    expect(last, isA<PanelIdle>());
    pipeline.dispose();
  });
}
