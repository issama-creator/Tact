import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/dictionaries/mat_lexicon.dart';
import 'package:tact/keyboard/engines/mat_engine.dart';
import 'package:tact/keyboard/engines/normalizer.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/rules/rule_signal.dart';

TextContext ctx(String word, {String locale = 'ru'}) => TextContext(
      word: word,
      before: '',
      after: '',
      range: EditRange(0, word.length),
      locale: locale,
      fullMessage: word,
    );

void main() {
  final normalizer = Normalizer();
  final lexicon = MatLexicon.fromParts(
    tokens: {'хуй', 'блядь', 'shit'},
    stems: {'пизд'},
  );

  test('detects exact mat match case-insensitively', () {
    final engine = MatEngine(lexicon, normalizer);
    expect(engine.analyze(ctx('хуй')).first.kind, SignalKind.mat);
    expect(engine.analyze(ctx('хуЙ')).first.kind, SignalKind.mat);
  });

  test('detects leetspeak mat', () {
    final engine = MatEngine(lexicon, normalizer);
    expect(engine.analyze(ctx('sh1t', locale: 'en')).first.kind, SignalKind.mat);
  });

  test('ignores short words', () {
    final engine = MatEngine(lexicon, normalizer);
    expect(engine.analyze(ctx('xy')), isEmpty);
  });

  test('detects stem prefix match', () {
    final engine = MatEngine(lexicon, normalizer);
    expect(engine.analyze(ctx('пиздец')).first.kind, SignalKind.mat);
  });

  test('safe words produce no signal', () {
    final engine = MatEngine(lexicon, normalizer);
    expect(engine.analyze(ctx('привет')), isEmpty);
  });
}
