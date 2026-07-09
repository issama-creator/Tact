import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/dictionaries/dictionary.dart';
import 'package:tact/keyboard/dictionaries/phrase_spell.dart';
import 'package:tact/keyboard/dictionaries/sym_spell_index.dart';

void main() {
  group('SymSpellIndex', () {
    test('finds candidates at 5k scale', () {
      final words = List.generate(5000, (i) => 'word$i');
      words.addAll(['hello', 'help', 'held']);
      final index = SymSpellIndex(words: words, locale: 'en');
      final suggestions = index.suggest('helo');
      expect(suggestions, contains('hello'));
    });

    test('ranks by frequency when edit distance ties', () {
      final index = SymSpellIndex(
        words: ['there', 'their', 'theme'],
        frequency: {'there': 900, 'their': 500, 'theme': 100},
        locale: 'en',
      );
      final suggestions = index.suggest('thre');
      expect(suggestions.first, 'there');
    });
  });

  group('PhraseSpellLexicon', () {
    test('corrects trailing phrase', () {
      final lex = PhraseSpellLexicon.fromMap(
        corrections: {'как дла': 'как дела'},
        valid: ['как дела'],
      );
      expect(
        lex.lookupTrailing('привет как дла'),
        'как дела',
      );
    });

    test('skips already valid phrases', () {
      final lex = PhraseSpellLexicon.fromMap(
        corrections: {'thank you': 'thanks'},
        valid: ['thank you'],
      );
      expect(lex.lookup('thank you'), isNull);
    });
  });

  group('Dictionary with SymSpell', () {
    test('keyboard proximity prefers closer typo', () {
      final dict = Dictionary.fromWords(
        ['hello', 'help', 'jello'],
        frequency: {'hello': 800, 'help': 400, 'jello': 200},
        locale: 'en',
      );
      final c = dict.candidates('helo');
      expect(c, isNotEmpty);
      expect(c.first, 'hello');
    });
  });
}
