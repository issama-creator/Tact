import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/dictionaries/data/embedded_en.dart';
import 'package:tact/keyboard/dictionaries/data/embedded_ru.dart';
import 'package:tact/keyboard/dictionaries/data/embedded_typo.dart';
import 'package:tact/keyboard/dictionaries/dictionary.dart';
import 'package:tact/keyboard/dictionaries/dictionary_format.dart';
import 'package:tact/keyboard/dictionaries/dictionary_loader.dart';
import 'package:tact/keyboard/dictionaries/dictionary_manager.dart';
import 'package:tact/keyboard/dictionaries/dictionary_profiler.dart';
import 'package:tact/keyboard/dictionaries/lexicon_loader.dart';
import 'package:tact/keyboard/dictionaries/toxic_category.dart';
import 'package:tact/keyboard/dictionaries/typo_dictionary.dart';
import 'package:tact/keyboard/engines/mat_engine.dart';
import 'package:tact/keyboard/engines/normalizer.dart';
import 'package:tact/keyboard/engines/shortcut_engine.dart';
import 'package:tact/keyboard/engines/shortcut_table.dart';
import 'package:tact/keyboard/engines/spell_engine.dart';
import 'package:tact/keyboard/engines/toxic_engine.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/intelligence/local_intelligence_engine.dart';
import 'package:tact/keyboard/panel/panel_state.dart';
import 'package:tact/keyboard/rules/rule_signal.dart';

TextContext ctx(String word, {String locale = 'en', String before = ''}) =>
    TextContext(
      word: word,
      before: before,
      after: '',
      range: EditRange(before.length, before.length + word.length),
      locale: locale,
      fullMessage: '$before$word',
    );

void main() {
  setUp(() => DictionaryManager.ensureEmbedded());

  group('DictionaryManager', () {
    test('embedded english dictionary has ~100 words', () {
      final en = DictionaryManager.shared.spellFor('en');
      expect(en.size, equals(100));
      expect(en.contains('hello'), isTrue);
    });

    test('embedded russian dictionary has ~100 words', () {
      final ru = DictionaryManager.shared.spellFor('ru');
      expect(ru.size, equals(100));
      expect(ru.contains('привет'), isTrue);
      expect(ru.contains('спасибо'), isTrue);
    });

    test('loads from assets when binding is initialized', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      DictionaryManager.resetForTests();
      final manager = await DictionaryManager.open();
      expect(manager.source, 'assets');
      expect(manager.spellFor('en').contains('hello'), isTrue);
      expect(manager.builtinShortcuts.containsKey('др'), isTrue);
      expect(DictionaryProfiler.lastReport, isNotNull);
      expect(DictionaryProfiler.lastReport!.totalWords, greaterThan(150));
    });

    test('memory reuse — same dictionary instance per locale', () {
      final loader = DictionaryLoader();
      final a = loader.forLocale('en_US');
      final b = loader.forLocale('en');
      expect(identical(a, b), isTrue);
    });

    test('lexicon loader caches mat and toxic per locale', () {
      final lex = LexiconLoader();
      expect(identical(lex.matForLocale('en'), lex.matForLocale('en_US')), isTrue);
      expect(lex.toxicForLocale('ru').size, greaterThan(10));
    });
  });

  group('Typo dictionary', () {
    test('english typo corrections are O(1)', () {
      final typo = embeddedEnTypos;
      expect(typo.lookup('helo'), 'hello');
      expect(typo.lookup('teh'), 'the');
      expect(typo.lookup('unknown'), isNull);
    });

    test('russian typo corrections', () {
      final typo = embeddedRuTypos;
      expect(typo.lookup('превед'), 'привет');
      expect(typo.lookup('спосибо'), 'спасибо');
    });

    test('spell engine prefers typo map over edit distance', () {
      final dict = Dictionary.fromWords(['hello']);
      final engine = SpellEngine(dict, typo: embeddedEnTypos);
      final signals = engine.analyze(ctx('helo'));
      final payload = signals.first.payload! as SpellPayload;
      expect(payload.candidates, ['hello']);
    });

    test('teh maps to the via typo dictionary', () {
      final dict = Dictionary.fromWords(['the', 'hello']);
      final engine = SpellEngine(dict, typo: embeddedEnTypos);
      final payload =
          engine.analyze(ctx('teh')).first.payload! as SpellPayload;
      expect(payload.candidates, ['the']);
    });
  });

  group('Profanity detection', () {
    final normalizer = Normalizer();

    test('mat lexicon is case insensitive via normalizer', () {
      final mat = DictionaryManager.shared.matFor('ru');
      final engine = MatEngine(mat, normalizer);
      expect(engine.analyze(ctx('хуЙ', locale: 'ru')), isNotEmpty);
    });

    test('leetspeak mat detection', () {
      final mat = DictionaryManager.shared.matFor('en');
      final engine = MatEngine(mat, normalizer);
      expect(engine.analyze(ctx('sh1t')).first.kind, SignalKind.mat);
    });

    test('safe words produce no mat signal', () {
      final mat = DictionaryManager.shared.matFor('ru');
      final engine = MatEngine(mat, normalizer);
      expect(engine.analyze(ctx('привет', locale: 'ru')), isEmpty);
    });
  });

  group('Toxicity lookup', () {
    final normalizer = Normalizer();

    test('categories and severity scores', () {
      final toxic = DictionaryManager.shared.toxicFor('ru');
      final entry = toxic.lookup('идиот');
      expect(entry, isNotNull);
      expect(entry!.score, 75);
      expect(entry.category, ToxicCategory.insult);
    });

    test('high score yields conflict level', () {
      final engine = ToxicEngine(
        DictionaryManager.shared.toxicFor('ru'),
        normalizer,
      );
      final payload =
          engine.analyze(ctx('идиот', locale: 'ru')).first.payload! as ToxicPayload;
      expect(payload.level, ToxicLevel.conflict);
      expect(payload.category, ToxicCategory.insult);
    });

    test('medium score yields warning', () {
      final engine = ToxicEngine(
        DictionaryManager.shared.toxicFor('ru'),
        normalizer,
      );
      final payload =
          engine.analyze(ctx('дурак', locale: 'ru')).first.payload! as ToxicPayload;
      expect(payload.level, ToxicLevel.warning);
    });
  });

  group('Shortcut expansion', () {
    test('builtin shortcuts load from manager', () {
      final builtins = DictionaryManager.shared.builtinShortcuts;
      expect(builtins['пж']!.expansions.first, 'пожалуйста');
      expect(builtins['thx']!.expansions.first, 'thanks');
    });

    test('user shortcut overrides builtin', () {
      final table = ShortcutTable(
        builtin: DictionaryManager.shared.builtinShortcuts,
        user: [
          const TextShortcut(
            trigger: 'др',
            expansions: ['User win'],
            source: ShortcutSource.user,
          ),
        ],
      );
      expect(table.lookup('др')!.expansions.first, 'User win');
    });

    test('builtin др expands in pipeline', () {
      final engine = LocalIntelligenceEngine();
      final result = engine.process(ctx('др', locale: 'ru'));
      expect(result.decision.state, isA<PanelShortcut>());
    });
  });

  group('Next-word suggestions', () {
    test('english good morning chain', () {
      final lookup = DictionaryManager.shared.spellFor('en').lookup('good');
      expect(lookup.nextWords, contains('morning'));
    });

    test('russian доброе утро chain', () {
      final lookup = DictionaryManager.shared.spellFor('ru').lookup('добрый');
      expect(lookup.nextWords, contains('день'));
    });

    test('hello world chain', () {
      final lookup = DictionaryManager.shared.spellFor('en').lookup('hello');
      expect(lookup.nextWords, contains('world'));
    });
  });

  group('Format validation', () {
    test('rejects invalid spell json', () {
      expect(
        () => DictionaryFormat.parseSpellBundle('{"v":1}'),
        throwsA(isA<DictionaryFormatException>()),
      );
    });

    test('parses toxic categories', () {
      final lex = DictionaryFormat.parseToxic('''
        {"v":1,"locale":"en","entries":{"foo":{"s":60,"c":"hostile"}}}
      ''');
      expect(lex.lookup('foo')!.category, ToxicCategory.hostile);
    });
  });

  group('Performance', () {
    test('lookup stays fast on large dictionary', () {
      final words = List.generate(5000, (i) => 'word$i');
      final dict = Dictionary.fromWords(words);
      final sw = Stopwatch()..start();
      for (var i = 0; i < 10000; i++) {
        dict.contains('word4999');
        dict.lookup('word1000');
      }
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(500));
    });

    test('typo lookup is constant time', () {
      final typo = TypoDictionary.fromMap({
        for (var i = 0; i < 1000; i++) 'typo$i': 'word$i',
      });
      final sw = Stopwatch()..start();
      for (var i = 0; i < 10000; i++) {
        typo.lookup('typo500');
      }
      sw.stop();
      expect(sw.elapsedMilliseconds, lessThan(100));
    });
  });

  group('Mixed languages and unicode', () {
    test('russian and english bundles are isolated', () {
      final manager = DictionaryManager.shared;
      expect(manager.spellFor('en').contains('привет'), isFalse);
      expect(manager.spellFor('ru').contains('hello'), isFalse);
    });

    test('unicode emoji skipped by spell engine', () {
      final dict = DictionaryManager.shared.spellFor('en');
      final engine = SpellEngine(dict);
      expect(engine.analyze(ctx('test😀')), isEmpty);
    });

    test('embedded word lists are non-empty', () {
      expect(embeddedEnWords.length, equals(100));
      expect(embeddedRuWords.length, equals(100));
    });
  });
}
