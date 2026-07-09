/// Personal dictionary — words the user never wants spell-checked.
library;

import 'dart:convert';

import '../kv_store.dart';

final class PersonalWordsRepository {
  PersonalWordsRepository._(this._store);

  static const storageKey = 'tact.personal_words';
  static PersonalWordsRepository? _instance;

  final KvStore _store;

  static Future<PersonalWordsRepository> open() async {
    if (_instance != null) return _instance!;
    final store = await SharedPrefsKvStore.open();
    return bind(store);
  }

  static PersonalWordsRepository bind(KvStore store) {
    _instance = PersonalWordsRepository._(store);
    return _instance!;
  }

  static PersonalWordsRepository get instance {
    final repo = _instance;
    if (repo == null) {
      throw StateError('Call PersonalWordsRepository.open() first');
    }
    return repo;
  }

  Future<String?> readRaw() async {
    await _store.refreshFromDisk();
    return _store.getString(storageKey);
  }

  Future<Set<String>> loadAll() async {
    final raw = await _store.getString(storageKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      return decoded
          .whereType<String>()
          .map((w) => w.trim().toLowerCase())
          .where((w) => w.length >= 2)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  /// Unions with stored words so concurrent adds from companion + IME are kept.
  Future<void> saveAll(
    Set<String> words, {
    Set<String> removed = const {},
  }) async {
    final existing = await loadAll();
    final merged = {...existing, ...words}..removeAll(removed);
    final list = merged.toList()..sort();
    await _store.setStringAtomic(storageKey, jsonEncode(list));
  }

  Future<void> add(String word) async {
    final trimmed = word.trim().toLowerCase();
    if (trimmed.length < 2) {
      throw ArgumentError('word must be at least 2 characters');
    }
    await saveAll({trimmed});
  }

  Future<void> remove(String word) async {
    await saveAll(const {}, removed: {word.trim().toLowerCase()});
  }
}
