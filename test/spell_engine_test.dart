import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/dictionaries/dictionary.dart';
import 'package:tact/keyboard/dictionaries/typo_dictionary.dart';
import 'package:tact/keyboard/engines/spell_engine.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/rules/rule_signal.dart';

TextContext ctx(String word) => TextContext(
      word: word,
      before: '',
      after: '',
      range: EditRange(0, word.length),
      locale: 'en',
      fullMessage: word,
    );

void main() {
  final dict = Dictionary.fromWords(['hello', 'world', 'thanks']);

  test('words shorter than 3 produce no signal', () {
    final engine = SpellEngine(dict);
    expect(engine.analyze(ctx('hi')), isEmpty);
  });

  test('in-dictionary words produce no signal', () {
    final engine = SpellEngine(dict);
    expect(engine.analyze(ctx('hello')), isEmpty);
  });

  test('personal dictionary words produce no signal', () {
    final engine = SpellEngine(dict, personalWords: {'customword'});
    expect(engine.analyze(ctx('customword')), isEmpty);
  });

  test('typo with candidates emits spellError', () {
    final engine = SpellEngine(dict);
    final signals = engine.analyze(ctx('helo'));
    expect(signals, hasLength(1));
    expect(signals.first.kind, SignalKind.spellError);
    final payload = signals.first.payload! as SpellPayload;
    expect(payload.candidates, contains('hello'));
  });

  test('dedicated typo map takes priority', () {
    final typo = TypoDictionary.fromMap({'helo': 'hello'});
    final engine = SpellEngine(dict, typo: typo);
    final payload =
        engine.analyze(ctx('helo')).first.payload! as SpellPayload;
    expect(payload.candidates, ['hello']);
  });

  test('skips numbers urls emails emoji', () {
    final engine = SpellEngine(dict);
    expect(engine.analyze(ctx('12345')), isEmpty);
    expect(engine.analyze(ctx('https://example.com')), isEmpty);
    expect(engine.analyze(ctx('a@b.com')), isEmpty);
    expect(engine.analyze(ctx('test😀')), isEmpty);
  });

  test('no candidates means no signal', () {
    final engine = SpellEngine(dict);
    expect(engine.analyze(ctx('zzzzzzzz')), isEmpty);
  });
}
