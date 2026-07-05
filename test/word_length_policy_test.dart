import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/input/word_length_policy.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/intelligence/local_intelligence_engine.dart';
import 'package:tact/keyboard/panel/panel_state.dart';

TextContext ctx(String word, {String locale = 'ru'}) => TextContext(
      word: word,
      before: '',
      after: '',
      range: EditRange(0, word.length),
      locale: locale,
      fullMessage: word,
    );

void main() {
  test('lexicon analysis requires 3+ graphemes', () {
    expect(shouldRunLexiconAnalysis('я'), isFalse);
    expect(shouldRunLexiconAnalysis('ты'), isFalse);
    expect(shouldRunLexiconAnalysis('мы'), isFalse);
    expect(shouldRunLexiconAnalysis('как'), isTrue);
    expect(shouldRunLexiconAnalysis('привет'), isTrue);
  });

  test('short words skip spell and suggestions', () {
    final engine = LocalIntelligenceEngine();
    final result = engine.process(ctx('ты'));
    expect(result.decision.state, isA<PanelIdle>());
    expect(result.signals, isEmpty);
  });

  test('two-letter shortcuts still work', () {
    final engine = LocalIntelligenceEngine();
    final result = engine.process(ctx('др'));
    expect(result.decision.state, isA<PanelShortcut>());
  });
}
