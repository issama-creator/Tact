import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/dictionaries/data/embedded_lexicons.dart';
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
    tokenLevels: const {
      'хуй': MatLevel.block,
      'блядь': MatLevel.block,
      'сука': MatLevel.warn,
      'shit': MatLevel.block,
    },
    stemLevels: const {
      'пизд': MatLevel.block,
      'бля': MatLevel.warn,
    },
  );

  test('detects exact mat match case-insensitively', () {
    final engine = MatEngine(lexicon, normalizer);
    final signal = engine.analyze(ctx('хуй')).first;
    expect(signal.kind, SignalKind.mat);
    expect((signal.payload as MatPayload).level, MatLevel.block);
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
    final signal = engine.analyze(ctx('пиздец')).first;
    expect(signal.kind, SignalKind.mat);
    expect((signal.payload as MatPayload).level, MatLevel.block);
  });

  test('warn stem does not override blocked exact token', () {
    final engine = MatEngine(lexicon, normalizer);
    final signal = engine.analyze(ctx('блядь')).first;
    expect((signal.payload as MatPayload).level, MatLevel.block);
  });

  test('warn level for mild stem match', () {
    final engine = MatEngine(lexicon, normalizer);
    final signal = engine.analyze(ctx('бляха')).first;
    expect((signal.payload as MatPayload).level, MatLevel.warn);
  });

  test('embedded ru хуй is block level', () {
    expect(embeddedMatRuLexicon.lookup('хуй'), MatLevel.block);
    expect(embeddedMatRuLexicon.lookup('сука'), MatLevel.warn);
  });

  test('safe words produce no signal', () {
    final engine = MatEngine(lexicon, normalizer);
    expect(engine.analyze(ctx('привет')), isEmpty);
  });
}
