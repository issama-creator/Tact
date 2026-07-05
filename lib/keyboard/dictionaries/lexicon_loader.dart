/// Toxic / mat lexicon loader — immutable sets loaded once via [DictionaryManager].
library;

import 'dictionary_manager.dart';
import 'toxic_category.dart';

enum LexiconKind { mat, toxic }

/// Cached lexicons for mat and toxic engines.
final class LexiconLoader {
  LexiconLoader([DictionaryManager? manager])
      : _manager = manager ?? DictionaryManager.shared;

  final DictionaryManager _manager;
  final Map<String, Set<String>> _mat = {};
  final Map<String, ToxicLexicon> _toxic = {};

  Set<String> matForLocale(String locale) {
    final key = _localeKey(locale);
    return _mat.putIfAbsent(key, () => _manager.matFor(key));
  }

  ToxicLexicon toxicForLocale(String locale) {
    final key = _localeKey(locale);
    return _toxic.putIfAbsent(key, () => _manager.toxicFor(key));
  }

  void evictAll() {
    _mat.clear();
    _toxic.clear();
  }

  static String _localeKey(String locale) {
    final lower = locale.toLowerCase();
    if (lower.startsWith('ru')) return 'ru';
    return 'en';
  }
}
