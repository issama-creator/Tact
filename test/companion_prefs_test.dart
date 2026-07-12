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
    expect(CompanionPrefsRepository.parseRaw('not-json').matBlockedCount, 0);
  });

  test('legacy demo seed auto-migrates to cleared stats', () {
    final raw = jsonEncode(CompanionPrefs.legacyDemoSeed.toJson());
    final migrated = CompanionPrefsRepository.parseRaw(raw);
    expect(migrated.matBlockedCount, 0);
    expect(migrated.toxicSoftenedCount, 0);
    expect(migrated.aiAssistCount, 0);
    expect(migrated.cleanStreakDays, 0);
    expect(migrated.communicationScore, 100);
    expect(migrated.orthographyUsed, 0);
  });

  test('withClearedStats zeros counters but keeps limits', () {
    const prefs = CompanionPrefs(
      communicationScore: 42,
      matBlockedCount: 9,
      toxicSoftenedCount: 4,
      aiAssistCount: 7,
      cleanStreakDays: 3,
      cleanRecordDays: 11,
      orthographyUsed: 2,
      punctuationUsed: 5,
      improveTextUsed: 1,
      orthographyLimit: 15,
    );
    final cleared = prefs.withClearedStats();
    expect(cleared.communicationScore, 100);
    expect(cleared.matBlockedCount, 0);
    expect(cleared.toxicSoftenedCount, 0);
    expect(cleared.aiAssistCount, 0);
    expect(cleared.cleanStreakDays, 0);
    expect(cleared.cleanRecordDays, 0);
    expect(cleared.orthographyUsed, 0);
    expect(cleared.punctuationUsed, 0);
    expect(cleared.improveTextUsed, 0);
    expect(cleared.orthographyLimit, 15);
    expect(cleared.selectedThemeIndex, prefs.selectedThemeIndex);
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
