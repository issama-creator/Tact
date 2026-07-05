import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/dictionaries/toxic_category.dart';
import 'package:tact/keyboard/engines/normalizer.dart';
import 'package:tact/keyboard/engines/toxic_engine.dart';
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
  final lexicon = ToxicLexicon.fromEntries({
    'идиот': const ToxicEntry(score: 75, category: ToxicCategory.insult),
    'дурак': const ToxicEntry(score: 55, category: ToxicCategory.insult),
    'тупой': const ToxicEntry(score: 58, category: ToxicCategory.insult),
  });

  test('high score yields conflict level', () {
    final engine = ToxicEngine(lexicon, normalizer);
    final payload = engine.analyze(ctx('идиот')).first.payload! as ToxicPayload;
    expect(payload.level, ToxicLevel.conflict);
  });

  test('medium score yields warning', () {
    final engine = ToxicEngine(lexicon, normalizer);
    final payload = engine.analyze(ctx('дурак')).first.payload! as ToxicPayload;
    expect(payload.level, ToxicLevel.warning);
  });

  test('safe words produce no signal', () {
    final engine = ToxicEngine(lexicon, normalizer);
    expect(engine.analyze(ctx('привет')), isEmpty);
  });
}
