import 'package:flutter_test/flutter_test.dart';
import 'package:tact/core/bridge/ime_bridge_facade.dart';
import 'package:tact/keyboard/dictionaries/dictionary.dart';
import 'package:tact/keyboard/dictionaries/data/embedded_ru.dart';
import 'package:tact/keyboard/input/input_pipeline.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/intelligence/local_intelligence_engine.dart';
import 'package:tact/keyboard/panel/panel_state.dart';

void main() {
  group('Dictionary.prefixCompletions', () {
    test('returns ranked completions for prefix', () {
      final dict = Dictionary.fromWords(
        ['добрый', 'доброе', 'доброго', 'дом', 'привет'],
        frequency: {
          'добрый': 100,
          'доброе': 80,
          'доброго': 60,
          'дом': 90,
        },
        locale: 'ru',
      );
      final hits = dict.prefixCompletions('доб', max: 3);
      expect(hits, ['добрый', 'доброе', 'доброго']);
      expect(hits, isNot(contains('дом')));
    });

    test('skips exact prefix match', () {
      final dict = Dictionary.fromWords(['hell', 'hello', 'help', 'helpful']);
      final hits = dict.prefixCompletions('hell');
      expect(hits, contains('hello'));
      expect(hits, isNot(contains('hell')));
    });

    test('empty for short or unknown prefix', () {
      final dict = Dictionary.fromWords(['hello']);
      expect(dict.prefixCompletions('h'), isEmpty);
      expect(dict.prefixCompletions('xyz'), isEmpty);
    });
  });

  group('partial autocomplete pipeline', () {
    test('engine returns PanelSuggestions for доб', () {
      final engine = LocalIntelligenceEngine();
      final result = engine.processPartial(
        TextContext(
          word: 'доб',
          before: '',
          after: '',
          range: const EditRange(0, 3),
          locale: 'ru',
          fullMessage: 'доб',
        ),
      );
      expect(result.decision.state, isA<PanelSuggestions>());
      final words = (result.decision.state as PanelSuggestions).words;
      expect(words, isNotEmpty);
      expect(words.every((w) => w.toLowerCase().startsWith('доб')), isTrue);
    });

    test('preserves leading capital', () {
      final engine = LocalIntelligenceEngine();
      final result = engine.processPartial(
        TextContext(
          word: 'Доб',
          before: '',
          after: '',
          range: const EditRange(0, 3),
          locale: 'ru',
          fullMessage: 'Доб',
        ),
      );
      final words = (result.decision.state as PanelSuggestions).words;
      expect(words.first[0], 'Д');
    });

    test('partial word shows autocomplete chips', () async {
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
        word: 'доб',
        locale: 'ru',
        partial: true,
        deleteBefore: 3,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(last, isA<PanelSuggestions>());
      pipeline.dispose();
    });
  });

  test('embedded ru includes добрый family', () {
    expect(embeddedRuWords, contains('добрый'));
    expect(embeddedRuWords, contains('доброго'));
    expect(embeddedRuWords, contains('добрая'));
  });
}
