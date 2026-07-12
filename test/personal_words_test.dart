import 'package:flutter_test/flutter_test.dart';
import 'package:tact/core/personal_words/personal_words_repository.dart';
import 'package:tact/core/kv_store.dart';
import 'package:tact/keyboard/dictionaries/mat_lexicon.dart';
import 'package:tact/keyboard/intelligence/local_intelligence_engine.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/panel/panel_state.dart';
import 'package:tact/keyboard/rules/rule_signal.dart';

final class _MemoryKvStore implements KvStore {
  final _data = <String, String>{};

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> setStringAtomic(String key, String value) async {
    await setString(key, value);
  }

  @override
  Future<bool> remove(String key) async => _data.remove(key) != null;

  @override
  Future<void> refreshFromDisk() async {}
}

TextContext ctx(String word, {String locale = 'en', String boundary = ' '}) =>
    TextContext(
      word: word,
      before: '',
      after: '',
      range: EditRange(0, word.length),
      locale: locale,
      boundary: boundary,
    );

void main() {
  test('personal words load into engine', () async {
    PersonalWordsRepository.bind(_MemoryKvStore());
    await PersonalWordsRepository.instance.add('tactbrand');

    final words = await PersonalWordsRepository.instance.loadAll();
    final engine = LocalIntelligenceEngine(personalWords: words);
    final result = engine.process(ctx('tactbrand'));
    expect(result.decision.state, isA<PanelIdle>());
  });

  test('personal word suppresses mat false positive', () {
    final engine = LocalIntelligenceEngine(
      personalWords: {'сука'},
    );
    // Without personal: would be PanelMat. With personal: skipped.
    final result = engine.process(ctx('сука', locale: 'ru'));
    expect(
      result.signals.where((s) => s.kind == SignalKind.mat),
      isEmpty,
    );
  });

  test('personal word boosted in autocomplete', () {
    final engine = LocalIntelligenceEngine(
      personalWords: {'добрячок'},
    );
    final result = engine.processPartial(ctx('доб', locale: 'ru'));
    final panel = result.decision.state;
    expect(panel, isA<PanelSuggestions>());
    expect(
      (panel as PanelSuggestions).words.first.toLowerCase(),
      'добрячок',
    );
  });
}
