import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/dictionaries/dictionary.dart';
import 'package:tact/keyboard/dictionaries/dictionary_loader.dart';

void main() {
  test('contains is O(1) membership', () {
    final dict = Dictionary.fromWords(['hello', 'world']);
    expect(dict.contains('hello'), isTrue);
    // Hot-path API expects already-normalized keys.
    expect(dict.contains('HELLO'), isFalse);
    expect(dict.contains('hello'.toLowerCase()), isTrue);
    expect(dict.contains('helo'), isFalse);
  });

  test('lookup returns next words for known tokens', () {
    final dict = Dictionary.fromWords(
      ['hello'],
      nextWords: {'hello': ['world', 'there']},
    );
    final result = dict.lookup('hello');
    expect(result.known, isTrue);
    expect(result.nextWords, ['world', 'there']);
  });

  test('candidates finds bounded edit-distance matches', () {
    final dict = Dictionary.fromWords(['hello', 'help', 'held']);
    final c = dict.candidates('helo');
    expect(c, contains('hello'));
    expect(c.length, lessThanOrEqualTo(5));
  });

  test('loader caches per locale', () {
    final loader = DictionaryLoader();
    final en1 = loader.forLocale('en_US');
    final en2 = loader.forLocale('en');
    final ru = loader.forLocale('ru_RU');
    expect(identical(en1, en2), isTrue);
    expect(ru.contains('привет'), isTrue);
  });

  test('large dictionary loads once', () {
    final words = List.generate(5000, (i) => 'word$i');
    final dict = Dictionary.fromWords(words);
    expect(dict.size, 5000);
    expect(dict.contains('word4999'), isTrue);
  });
}
