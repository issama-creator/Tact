/// JSON dictionary parsers with validation — compact mobile format.
library;

import 'dart:convert';

import '../engines/shortcut_table.dart';
import 'dictionary.dart';
import 'locale_bundle.dart';
import 'toxic_category.dart';
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

    final spell = Dictionary.fromWords(words, nextWords: next);
    final typo = TypoDictionary.empty();
    final mat = const <String>{};
    final toxic = ToxicLexicon.fromEntries(const {});

    return LocaleBundle(
      locale: locale,
      version: version,
      spell: spell,
      typo: typo,
      mat: mat,
      toxic: toxic,
      stats: _stats(spell: spell, typo: typo, mat: mat, toxic: toxic),
    );
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

  static Set<String> parseMat(String json) {
    final root = decodeObject(json);
    readVersion(root);
    readLocale(root);

    final tokensRaw = root['tokens'] ?? root['entries'];
    if (tokensRaw is! List) {
      throw DictionaryFormatException('mat.tokens must be a list');
    }
    final tokens = <String>{};
    for (final t in tokensRaw) {
      if (t is! String) continue;
      final key = t.toLowerCase().trim();
      if (key.length >= 2) tokens.add(key);
    }
    return Set<String>.unmodifiable(tokens);
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

      if (e.value is int) {
        entries[token] = ToxicEntry(score: e.value as int);
        continue;
      }
      if (e.value is! Map) continue;
      final obj = Map<String, dynamic>.from(e.value as Map);
      final score = obj['s'] ?? obj['score'];
      if (score is! int) continue;
      entries[token] = ToxicEntry(
        score: score,
        category: ToxicCategory.parse(
          obj['c'] as String? ?? obj['category'] as String?,
        ),
      );
    }

    return ToxicLexicon.fromEntries(
      entries,
      warningThreshold: warning,
      conflictThreshold: conflict,
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
    Set<String>? mat,
    ToxicLexicon? toxic,
  }) {
    final t = typo ?? base.typo;
    final m = mat ?? base.mat;
    final x = toxic ?? base.toxic;
    return LocaleBundle(
      locale: base.locale,
      version: base.version,
      spell: base.spell,
      typo: t,
      mat: m,
      toxic: x,
      stats: _stats(spell: base.spell, typo: t, mat: m, toxic: x),
    );
  }

  static BundleStats _stats({
    required Dictionary spell,
    required TypoDictionary typo,
    required Set<String> mat,
    required ToxicLexicon toxic,
  }) {
    var bytes = 0;
    bytes += spell.size * 6;
    bytes += typo.size * 10;
    bytes += mat.length * 6;
    bytes += toxic.size * 12;
    return BundleStats(
      spellWords: spell.size,
      typoEntries: typo.size,
      matTokens: mat.length,
      toxicEntries: toxic.size,
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
