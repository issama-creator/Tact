/// Persists keyboard mode toggles — companion writes, IME reads on field focus.
library;

import 'dart:convert';

import '../kv_store.dart';
import 'keyboard_settings.dart';

final class KeyboardSettingsRepository {
  KeyboardSettingsRepository._(this._store);

  static const storageKey = 'tact.keyboard_settings';
  static KeyboardSettingsRepository? _instance;

  final KvStore _store;

  static Future<KeyboardSettingsRepository> open() async {
    if (_instance != null) return _instance!;
    final store = await SharedPrefsKvStore.open();
    return bind(store);
  }

  static KeyboardSettingsRepository bind(KvStore store) {
    _instance = KeyboardSettingsRepository._(store);
    return _instance!;
  }

  static KeyboardSettingsRepository get instance {
    final repo = _instance;
    if (repo == null) {
      throw StateError('Call KeyboardSettingsRepository.open() first');
    }
    return repo;
  }

  Future<String?> readRaw() async {
    await _store.refreshFromDisk();
    return _store.getString(storageKey);
  }

  Future<KeyboardSettings> load() async {
    final raw = await readRaw();
    if (raw == null || raw.isEmpty) return KeyboardSettings.defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return KeyboardSettings.defaults;
      return KeyboardSettings.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return KeyboardSettings.defaults;
    }
  }

  Future<void> save(KeyboardSettings settings) async {
    await _store.setStringAtomic(storageKey, jsonEncode(settings.toJson()));
  }
}
