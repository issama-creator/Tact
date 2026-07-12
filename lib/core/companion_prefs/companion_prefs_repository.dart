/// Persists companion dashboard prefs — theme, stats, limits.
library;

import 'dart:convert';

import '../kv_store.dart';
import 'companion_prefs.dart';

final class CompanionPrefsRepository {
  CompanionPrefsRepository._(this._store);

  static const storageKey = 'tact.companion_prefs';
  static CompanionPrefsRepository? _instance;

  final KvStore _store;

  static Future<CompanionPrefsRepository> open() async {
    if (_instance != null) return _instance!;
    final store = await SharedPrefsKvStore.open();
    return bind(store);
  }

  static CompanionPrefsRepository bind(KvStore store) {
    _instance = CompanionPrefsRepository._(store);
    return _instance!;
  }

  static CompanionPrefsRepository get instance {
    final repo = _instance;
    if (repo == null) {
      throw StateError('Call CompanionPrefsRepository.open() first');
    }
    return repo;
  }

  Future<void> refresh() => _store.refreshFromDisk();

  Future<String?> peekRaw() => _store.getString(storageKey);

  Future<CompanionPrefs> load({bool refreshFromDisk = true}) async {
    if (refreshFromDisk) await refresh();
    final raw = await peekRaw();
    return parseRaw(raw);
  }

  static CompanionPrefs parseRaw(String? raw) =>
      parseRawUnmigrated(raw).withoutLegacyDemoSeed();

  /// Parses disk JSON without stripping the legacy demo dashboard.
  static CompanionPrefs parseRawUnmigrated(String? raw) {
    if (raw == null || raw.isEmpty) return CompanionPrefs.defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return CompanionPrefs.defaults;
      return CompanionPrefs.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return CompanionPrefs.defaults;
    }
  }

  Future<void> save(CompanionPrefs prefs) async {
    await _store.setStringAtomic(storageKey, jsonEncode(prefs.toJson()));
  }
}
