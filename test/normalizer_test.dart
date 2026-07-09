import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/engines/normalizer.dart';

void main() {
  final normalizer = Normalizer();

  test('lowercases and trims', () {
    expect(normalizer.normalize('  HELLO  '), 'hello');
  });

  test('collapses repeated letters and strips punctuation', () {
    expect(normalizer.normalize('ПРИВЕЕЕЕТ!!!!!'), 'привееет');
  });

  test('folds yo to e when configured', () {
    expect(normalizer.normalize('ёлка'), 'елка');
    final noFold = Normalizer(const NormalizerConfig(foldYo: false));
    expect(noFold.normalize('ёлка'), 'ёлка');
  });

  test('removes invisible characters', () {
    expect(normalizer.normalize('a\u200Bb'), 'ab');
  });

  test('lexicon path folds leetspeak', () {
    expect(normalizer.normalizeForLexicon('sh1t'), 'shit');
    expect(normalizer.normalizeForLexicon('a55'), 'ass');
    expect(normalizer.normalizeForLexicon('x*y'), 'xy');
  });

  test('mixed languages stay stable', () {
    expect(normalizer.normalize('HelloМИР'), 'helloмир');
  });
}
