/// Thin key-value store — hides shared_preferences behind a small API.
library;

import 'package:shared_preferences/shared_preferences.dart';

abstract interface class KvStore {
  Future<String?> getString(String key);
  Future<void> setString(String key, String value);
  Future<void> setStringAtomic(String key, String value);
  Future<bool> remove(String key);
}

final class SharedPrefsKvStore implements KvStore {
  SharedPrefsKvStore(this._prefs);

  final SharedPreferences _prefs;

  static Future<SharedPrefsKvStore> open() async {
    return SharedPrefsKvStore(await SharedPreferences.getInstance());
  }

  @override
  Future<String?> getString(String key) async => _prefs.getString(key);

  @override
  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  /// Writes to a staging key first so readers never see a partial JSON payload.
  Future<void> setStringAtomic(String key, String value) async {
    final staging = '$key.__staging';
    await _prefs.setString(staging, value);
    await _prefs.setString(key, value);
    await _prefs.remove(staging);
  }

  @override
  Future<bool> remove(String key) async => _prefs.remove(key);
}
