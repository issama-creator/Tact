/// Lazy per-language dictionary cache — delegates to [DictionaryManager].
library;

import 'dictionary.dart';
import 'dictionary_manager.dart';

/// Loads [Dictionary] objects once and caches them for the IME lifetime.
final class DictionaryLoader {
  DictionaryLoader([DictionaryManager? manager])
      : _manager = manager ?? DictionaryManager.shared;

  final DictionaryManager _manager;
  final Map<String, Dictionary> _cache = {};

  Dictionary forLocale(String locale) {
    final key = _normalizeLocale(locale);
    return _cache.putIfAbsent(key, () => _manager.spellFor(key));
  }

  void evictAllExcept(String locale) {
    final keep = _normalizeLocale(locale);
    _cache.removeWhere((k, _) => k != keep);
    _manager.evictAllExcept(keep);
  }

  void evictAll() => _cache.clear();

  static String _normalizeLocale(String locale) {
    final lower = locale.toLowerCase();
    if (lower.startsWith('ru')) return 'ru';
    return 'en';
  }
}
