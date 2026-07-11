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

  /// Shared store used by IME sync to refresh prefs once per cycle.
  KvStore get store => _store;

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

  /// Drops SharedPreferences cache — call once before a batch of peeks.
  Future<void> refresh() => _store.refreshFromDisk();

  /// Cheap read — assumes [refresh] already ran (or same-engine write).
  Future<String?> peekRaw() => _store.getString(storageKey);

  /// Refresh + peek — for one-off companion reads.
  Future<String?> readRaw() async {
    await refresh();
    return peekRaw();
  }

  Future<KeyboardSettings> load({bool refreshFromDisk = true}) async {
    final raw = refreshFromDisk ? await readRaw() : await peekRaw();
    return parseRaw(raw);
  }

  static KeyboardSettings parseRaw(String? raw) {
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
