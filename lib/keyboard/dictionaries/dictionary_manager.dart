/// Central dictionary lifecycle — load once, O(1) lookup, debug reload only.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../engines/shortcut_table.dart';
import 'data/embedded_en.dart';
import 'data/embedded_lexicons.dart';
import 'data/embedded_ru.dart';
import 'data/embedded_typo.dart';
import 'dictionary.dart';
import 'dictionary_format.dart';
import 'dictionary_profiler.dart';
import 'locale_bundle.dart';
import 'toxic_category.dart';
import 'typo_dictionary.dart';

/// Owns all locale bundles and built-in shortcuts for the IME lifetime.
final class DictionaryManager {
  DictionaryManager._({
    required Map<String, LocaleBundle> bundles,
    required Map<String, TextShortcut> builtinShortcuts,
    required this.source,
  })  : _bundles = Map<String, LocaleBundle>.unmodifiable(bundles),
        _builtinShortcuts = Map<String, TextShortcut>.unmodifiable(builtinShortcuts);

  static DictionaryManager? _instance;
  static Future<DictionaryManager>? _opening;

  /// Active manager — embedded fallback until [open] completes.
  static DictionaryManager get shared => _instance ??= _fromEmbedded();

  final Map<String, LocaleBundle> _bundles;
  final Map<String, TextShortcut> _builtinShortcuts;
  final String source;

  Map<String, TextShortcut> get builtinShortcuts => _builtinShortcuts;

  /// Loads all dictionary assets once at keyboard startup.
  static Future<DictionaryManager> open({bool force = false}) {
    if (_instance != null && !force) return Future.value(_instance!);
    if (!force && _opening != null) return _opening!;

    final future = _openInternal(force: force);
    _opening = future;
    return future.whenComplete(() {
      if (identical(_opening, future)) _opening = null;
    });
  }

  static Future<DictionaryManager> _openInternal({required bool force}) async {
    if (_instance != null && !force) return _instance!;
    final sw = Stopwatch()..start();
    try {
      final builtinJson =
          await rootBundle.loadString('assets/shortcuts/builtin.json');
      final builtin = DictionaryFormat.parseBuiltinShortcuts(builtinJson);

      final en = await _loadLocale('en');
      final ru = await _loadLocale('ru');

      var lookupNs = 0;
      lookupNs += _benchLookup(en);
      lookupNs += _benchLookup(ru);

      final manager = DictionaryManager._(
        bundles: {'en': en, 'ru': ru},
        builtinShortcuts: builtin,
        source: 'assets',
      );
      _instance = manager;

      DictionaryProfiler.record(
        DictionaryLoadReport(
          loadDuration: sw.elapsed,
          lookupDurationNs: lookupNs,
          bundles: manager._bundles,
          builtinShortcutCount: builtin.length,
          source: 'assets',
        ),
      );
      DictionaryProfiler.logSummary();
      return manager;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[TACT Dict] asset load failed: $e\n$st');
      }
      final embedded = _fromEmbedded();
      _instance = embedded;
      DictionaryProfiler.record(
        DictionaryLoadReport(
          loadDuration: sw.elapsed,
          lookupDurationNs: 0,
          bundles: embedded._bundles,
          builtinShortcutCount: embedded._builtinShortcuts.length,
          source: 'embedded-fallback',
        ),
      );
      return embedded;
    }
  }

  /// Debug-only hot reload — no-op in release builds.
  Future<void> reload() async {
    if (kReleaseMode) return;
    await open(force: true);
  }

  LocaleBundle bundleFor(String locale) {
    final key = _localeKey(locale);
    return _bundles[key] ?? _bundles['en']!;
  }

  Dictionary spellFor(String locale) => bundleFor(locale).spell;

  TypoDictionary typoFor(String locale) => bundleFor(locale).typo;

  Set<String> matFor(String locale) => bundleFor(locale).mat;

  ToxicLexicon toxicFor(String locale) => bundleFor(locale).toxic;

  void evictAllExcept(String locale) {
    if (kReleaseMode) return;
    final keep = _localeKey(locale);
    final bundle = _bundles[keep];
    if (bundle == null) return;
    _instance = DictionaryManager._(
      bundles: {keep: bundle},
      builtinShortcuts: _builtinShortcuts,
      source: source,
    );
  }

  static Future<LocaleBundle> _loadLocale(String locale) async {
    final spellJson =
        await rootBundle.loadString('assets/dictionaries/${locale}_spell.json');
    final base = DictionaryFormat.parseSpellBundle(spellJson);

    final typoJson =
        await rootBundle.loadString('assets/dictionaries/${locale}_typo.json');
    final typo = DictionaryFormat.parseTypo(typoJson);

    final matJson =
        await rootBundle.loadString('assets/lexicons/${locale}_mat.json');
    final mat = DictionaryFormat.parseMat(matJson);

    final toxicJson =
        await rootBundle.loadString('assets/lexicons/${locale}_toxic.json');
    final toxic = DictionaryFormat.parseToxic(toxicJson);

    return DictionaryFormat.mergeBundle(
      base: base,
      typo: typo,
      mat: mat,
      toxic: toxic,
    );
  }

  static DictionaryManager _fromEmbedded() {
    final en = _embeddedLocale('en');
    final ru = _embeddedLocale('ru');
    return DictionaryManager._(
      bundles: {'en': en, 'ru': ru},
      builtinShortcuts: embeddedBuiltinShortcuts,
      source: 'embedded',
    );
  }

  static LocaleBundle _embeddedLocale(String locale) {
    if (locale == 'ru') {
      final spell = Dictionary.fromWords(
        embeddedRuWords,
        nextWords: embeddedRuNext,
      );
      return LocaleBundle(
        locale: 'ru',
        version: 1,
        spell: spell,
        typo: embeddedRuTypos,
        mat: Set<String>.unmodifiable(embeddedMatRu),
        toxic: embeddedToxicRuLexicon,
        stats: BundleStats(
          spellWords: spell.size,
          typoEntries: embeddedRuTypos.size,
          matTokens: embeddedMatRu.length,
          toxicEntries: embeddedToxicRuLexicon.size,
          nextWordKeys: spell.nextWordKeyCount,
          estimatedBytes: spell.size * 6,
        ),
      );
    }

    final spell = Dictionary.fromWords(
      embeddedEnWords,
      nextWords: embeddedEnNext,
    );
    return LocaleBundle(
      locale: 'en',
      version: 1,
      spell: spell,
      typo: embeddedEnTypos,
      mat: Set<String>.unmodifiable(embeddedMatEn),
      toxic: embeddedToxicEnLexicon,
      stats: BundleStats(
        spellWords: spell.size,
        typoEntries: embeddedEnTypos.size,
        matTokens: embeddedMatEn.length,
        toxicEntries: embeddedToxicEnLexicon.size,
        nextWordKeys: spell.nextWordKeyCount,
        estimatedBytes: spell.size * 6,
      ),
    );
  }

  static int _benchLookup(LocaleBundle bundle) {
    final sw = Stopwatch()..start();
    bundle.spell.contains('hello');
    bundle.spell.contains('привет');
    bundle.typo.lookup('helo');
    bundle.mat.contains('shit');
    bundle.toxic.lookup('idiot');
    sw.stop();
    return sw.elapsedMicroseconds * 1000;
  }

  static String _localeKey(String locale) {
    final lower = locale.toLowerCase();
    if (lower.startsWith('ru')) return 'ru';
    return 'en';
  }

  @visibleForTesting
  static DictionaryManager ensureEmbedded() {
    _instance = _fromEmbedded();
    return _instance!;
  }

  @visibleForTesting
  static void resetForTests() {
    _instance = null;
    _opening = null;
  }
}
