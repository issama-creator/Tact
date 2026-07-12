import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tact/core/companion_prefs/companion_prefs.dart';
import 'package:tact/core/companion_prefs/companion_prefs_repository.dart';
import 'package:tact/core/kv_store.dart';

final class _MemoryKvStore implements KvStore {
  final _data = <String, String>{};

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<void> setStringAtomic(String key, String value) async {
    await setString(key, value);
  }

  @override
  Future<bool> remove(String key) async => _data.remove(key) != null;

  @override
  Future<void> refreshFromDisk() async {}
}

void main() {
  test('companion prefs persist theme stats and limits', () async {
    final repo = CompanionPrefsRepository.bind(_MemoryKvStore());
    await repo.save(
      const CompanionPrefs(
        selectedThemeIndex: 1,
        communicationScore: 70,
        matBlockedCount: 9,
        orthographyUsed: 4,
        orthographyLimit: 10,
        keyboardLanguage: 'English',
        showTips: false,
      ),
    );
    final loaded = await repo.load();
    expect(loaded.selectedThemeIndex, 1);
    expect(loaded.communicationScore, 70);
    expect(loaded.matBlockedCount, 9);
    expect(loaded.orthographyUsed, 4);
    expect(loaded.orthographyLimit, 10);
    expect(loaded.keyboardLanguage, 'English');
    expect(loaded.showTips, isFalse);
  });

  test('empty storage yields defaults', () {
    final prefs = CompanionPrefsRepository.parseRaw(null);
    expect(prefs.selectedThemeIndex, CompanionPrefs.defaults.selectedThemeIndex);
    expect(prefs.orthographyLimit, 10);
    expect(CompanionPrefsRepository.parseRaw('not-json').matBlockedCount, 48);
  });

  test('round-trip json', () {
    const prefs = CompanionPrefs(
      cleanStreakDays: 5,
      cleanRecordDays: 40,
      aiAssistCount: 12,
    );
    final decoded = CompanionPrefs.fromJson(
      jsonDecode(jsonEncode(prefs.toJson())) as Map<String, dynamic>,
    );
    expect(decoded.cleanStreakDays, 5);
    expect(decoded.cleanRecordDays, 40);
    expect(decoded.aiAssistCount, 12);
  });
}
