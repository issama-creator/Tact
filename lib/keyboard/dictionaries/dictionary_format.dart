/// JSON dictionary parsers with validation — compact mobile format.
library;

import 'dart:convert';

import '../engines/shortcut_table.dart';
import 'dictionary.dart';
import 'locale_bundle.dart';
import 'mat_lexicon.dart';
import 'toxic_category.dart';
import 'phrase_spell.dart';
import 'typo_dictionary.dart';

/// Thrown when a dictionary asset fails validation.
final class DictionaryFormatException implements Exception {
  DictionaryFormatException(this.message);

  final String message;

  @override
  String toString() => 'DictionaryFormatException: $message';
}

/// Parses bundled JSON dictionary files into immutable runtime structures.
final class DictionaryFormat {
  const DictionaryFormat._();

  static const supportedVersion = 1;

  static Map<String, dynamic> decodeObject(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw DictionaryFormatException('root must be an object');
    }
    return decoded;
  }

  static int readVersion(Map<String, dynamic> root) {
    final v = root['v'] ?? root['version'];
    if (v is! int || v < 1) {
      throw DictionaryFormatException('invalid version: $v');
    }
    return v;
  }

  static String readLocale(Map<String, dynamic> root) {
    final locale = root['locale'];
    if (locale is! String || locale.isEmpty) {
      throw DictionaryFormatException('missing locale');
    }
    return _normalizeLocale(locale);
  }

  static LocaleBundle parseSpellBundle(String json) {
    final root = decodeObject(json);
    final version = readVersion(root);
    final locale = readLocale(root);

    final wordsRaw = root['words'];
    if (wordsRaw is! List) {
      throw DictionaryFormatException('spell.words must be a list');
    }
    final words = <String>[];
    for (final w in wordsRaw) {
      if (w is! String || w.trim().isEmpty) continue;
      words.add(w.trim());
    }
    if (words.isEmpty) {
      throw DictionaryFormatException('spell.words is empty');
    }

    final nextRaw = root['next'];
    final next = <String, List<String>>{};
    if (nextRaw is Map) {
      for (final e in nextRaw.entries) {
        if (e.key is! String) continue;
        final list = _readStringList(e.value);
        if (list.isNotEmpty) next[e.key as String] = list;
      }
    }

    final freqRaw = root['freq'] ?? root['frequency'];
    final frequency = <String, int>{};
    if (freqRaw is Map) {
      for (final e in freqRaw.entries) {
        if (e.key is! String) continue;
        final v = e.value;
        if (v is int && v > 0) {
          frequency[(e.key as String).toLowerCase()] = v;
        }
      }
    }

    final spell = Dictionary.fromWords(
      words,
      nextWords: next,
      frequency: frequency,
      locale: locale,
    );
    final typo = TypoDictionary.empty();
    final mat = MatLexicon.fromTokens(const []);
    final toxic = ToxicLexicon.fromEntries(const {});
    final phraseSpell = PhraseSpellLexicon.empty();

    return LocaleBundle(
      locale: locale,
      version: version,
      spell: spell,
      typo: typo,
      mat: mat,
      toxic: toxic,
      phraseSpell: phraseSpell,
      stats: _stats(
        spell: spell,
        typo: typo,
        mat: mat,
        toxic: toxic,
        phraseSpell: phraseSpell,
      ),
    );
  }

  static PhraseSpellLexicon parsePhraseSpell(String json) {
    final root = decodeObject(json);
    readVersion(root);
    readLocale(root);

    final corrections = <String, String>{};
    final corrRaw = root['corrections'] ?? root['phrases'];
    if (corrRaw is Map) {
      for (final e in corrRaw.entries) {
        if (e.key is! String || e.value is! String) continue;
        corrections[e.key as String] = e.value as String;
      }
    }

    final valid = <String>[];
    final validRaw = root['valid'];
    if (validRaw is List) {
      valid.addAll(_readStringList(validRaw));
    }

    return PhraseSpellLexicon.fromMap(corrections: corrections, valid: valid);
  }

  static TypoDictionary parseTypo(String json) {
    final root = decodeObject(json);
    readVersion(root);
    readLocale(root);

    final mapRaw = root['corrections'] ?? root['typos'];
    if (mapRaw is! Map) {
      throw DictionaryFormatException('typo.corrections must be a map');
    }
    final corrections = <String, String>{};
    for (final e in mapRaw.entries) {
      if (e.key is! String || e.value is! String) continue;
      corrections[e.key as String] = e.value as String;
    }
    return TypoDictionary.fromMap(corrections);
  }

  static MatLexicon parseMat(String json) {
    final root = decodeObject(json);
    readVersion(root);
    readLocale(root);

    final tokensRaw = root['tokens'] ?? root['entries'];
    if (tokensRaw is! List) {
      throw DictionaryFormatException('mat.tokens must be a list');
    }
    final tokens = <String>[];
    for (final t in tokensRaw) {
      if (t is! String) continue;
      final key = t.toLowerCase().trim();
      if (key.length >= 2) tokens.add(key);
    }

    final stemsRaw = root['stems'];
    final stems = <String>[];
    if (stemsRaw is List) {
      for (final s in stemsRaw) {
        if (s is! String) continue;
        final key = s.toLowerCase().trim();
        if (key.length >= 3) stems.add(key);
      }
    }

    return MatLexicon.fromParts(tokens: tokens, stems: stems);
  }

  static ToxicLexicon parseToxic(String json) {
    final root = decodeObject(json);
    readVersion(root);
    readLocale(root);

    final warning = root['warning'] as int? ?? 50;
    final conflict = root['conflict'] as int? ?? 75;

    final entriesRaw = root['entries'];
    if (entriesRaw is! Map) {
      throw DictionaryFormatException('toxic.entries must be a map');
    }

    final entries = <String, ToxicEntry>{};
    for (final e in entriesRaw.entries) {
      if (e.key is! String) continue;
      final token = (e.key as String).toLowerCase().trim();
      if (token.isEmpty) continue;

      final entry = _parseToxicEntry(e.value);
      if (entry != null) entries[token] = entry;
    }

    final phrases = <String, ToxicEntry>{};
    final phrasesRaw = root['phrases'];
    if (phrasesRaw is Map) {
      for (final e in phrasesRaw.entries) {
        if (e.key is! String) continue;
        final phrase = (e.key as String).toLowerCase().trim();
        if (phrase.length < 4) continue;
        final entry = _parseToxicEntry(e.value);
        if (entry != null) phrases[phrase] = entry;
      }
    }

    return ToxicLexicon.fromEntries(
      entries,
      phrases: phrases,
      warningThreshold: warning,
      conflictThreshold: conflict,
    );
  }

  static ToxicEntry? _parseToxicEntry(Object? raw) {
    if (raw is int) return ToxicEntry(score: raw);
    if (raw is! Map) return null;
    final obj = Map<String, dynamic>.from(raw);
    final score = obj['s'] ?? obj['score'];
    if (score is! int) return null;
    return ToxicEntry(
      score: score,
      category: ToxicCategory.parse(
        obj['c'] as String? ?? obj['category'] as String?,
      ),
    );
  }

  static Map<String, TextShortcut> parseBuiltinShortcuts(String json) {
    final root = decodeObject(json);
    readVersion(root);

    final list = root['shortcuts'];
    if (list is! List) return const {};

    final map = <String, TextShortcut>{};
    for (final item in list) {
      if (item is! Map) continue;
      final trigger = item['trigger'];
      if (trigger is! String || trigger.trim().length < 2) continue;

      final expansions = _readStringList(item['expansions']);
      if (expansions.isEmpty) continue;

      final key = trigger.toLowerCase().trim();
      map[key] = TextShortcut(
        trigger: key,
        expansions: List<String>.unmodifiable(expansions),
        source: ShortcutSource.builtin,
      );
    }
    return Map<String, TextShortcut>.unmodifiable(map);
  }

  static LocaleBundle mergeBundle({
    required LocaleBundle base,
    TypoDictionary? typo,
    MatLexicon? mat,
    ToxicLexicon? toxic,
    PhraseSpellLexicon? phraseSpell,
  }) {
    final t = typo ?? base.typo;
    final m = mat ?? base.mat;
    final x = toxic ?? base.toxic;
    final p = phraseSpell ?? base.phraseSpell;
    return LocaleBundle(
      locale: base.locale,
      version: base.version,
      spell: base.spell,
      typo: t,
      mat: m,
      toxic: x,
      phraseSpell: p,
      stats: _stats(
        spell: base.spell,
        typo: t,
        mat: m,
        toxic: x,
        phraseSpell: p,
      ),
    );
  }

  static BundleStats _stats({
    required Dictionary spell,
    required TypoDictionary typo,
    required MatLexicon mat,
    required ToxicLexicon toxic,
    required PhraseSpellLexicon phraseSpell,
  }) {
    var bytes = 0;
    bytes += spell.size * 6;
    bytes += typo.size * 10;
    bytes += mat.size * 6;
    bytes += toxic.size * 12;
    bytes += phraseSpell.size * 16;
    return BundleStats(
      spellWords: spell.size,
      typoEntries: typo.size,
      matTokens: mat.size,
      toxicEntries: toxic.size,
      phraseSpellEntries: phraseSpell.size,
      nextWordKeys: spell.nextWordKeyCount,
      estimatedBytes: bytes,
    );
  }

  static List<String> _readStringList(Object? raw) {
    if (raw is! List) return const [];
    final out = <String>[];
    for (final v in raw) {
      if (v is! String) continue;
      final s = v.trim();
      if (s.isNotEmpty) out.add(s);
    }
    return out;
  }

  static String _normalizeLocale(String locale) {
    final lower = locale.toLowerCase();
    if (lower.startsWith('ru')) return 'ru';
    return 'en';
  }
}
