import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tact/core/keyboard_settings/keyboard_settings.dart';
import 'package:tact/core/keyboard_settings/keyboard_settings_repository.dart';
import 'package:tact/core/kv_store.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/intelligence/local_intelligence_engine.dart';
import 'package:tact/keyboard/panel/panel_state.dart';
import 'package:tact/keyboard/rules/rule_signal.dart';

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

/// Simulates a second Flutter engine: local cache stale until [refreshFromDisk].
final class _SplitMemoryKvStore implements KvStore {
  _SplitMemoryKvStore(this._source);

  final _MemoryKvStore _source;
  final _cache = <String, String>{};
  var _hydrated = false;

  void _ensureHydrated() {
    if (_hydrated) return;
    _cache.addAll(_source._data);
    _hydrated = true;
  }

  @override
  Future<String?> getString(String key) async {
    _ensureHydrated();
    return _cache[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    _ensureHydrated();
    _cache[key] = value;
    await _source.setString(key, value);
  }

  @override
  Future<void> setStringAtomic(String key, String value) async {
    await setString(key, value);
  }

  @override
  Future<bool> remove(String key) async {
    _ensureHydrated();
    final removed = _cache.remove(key) != null;
    await _source.remove(key);
    return removed;
  }

  @override
  Future<void> refreshFromDisk() async {
    _cache
      ..clear()
      ..addAll(_source._data);
    _hydrated = true;
  }
}

TextContext ctx(String word, {String locale = 'ru', String before = ''}) =>
    TextContext(
      word: word,
      before: before,
      after: '',
      range: EditRange(before.length, before.length + word.length),
      locale: locale,
      fullMessage: '$before$word',
    );

void main() {
  test('repository persists keyboard toggles', () async {
    final repo = KeyboardSettingsRepository.bind(_MemoryKvStore());
    await repo.save(
      const KeyboardSettings(
        antiMat: false,
        antiToxic: true,
        fillerWords: false,
        textImprovement: false,
        aiAssistant: true,
        aiIntensity: 0.8,
        vibration: false,
        matVibration: false,
        sound: true,
      ),
    );
    final loaded = await repo.load();
    expect(loaded.antiMat, isFalse);
    expect(loaded.fillerWords, isFalse);
    expect(loaded.textImprovement, isFalse);
    expect(loaded.aiAssistant, isTrue);
    expect(loaded.aiIntensity, 0.8);
    expect(loaded.antiToxic, isTrue);
    expect(loaded.vibration, isFalse);
    expect(loaded.matVibration, isFalse);
    expect(loaded.sound, isTrue);
  });

  test('ai assistant chips after sentence end with enough text', () {
    final engine = LocalIntelligenceEngine();
    engine.applySettings(
      const KeyboardSettings(aiAssistant: true, aiIntensity: 1.0),
    );
    final before = 'Это достаточно длинное сообщение для теста';
    final result = engine.process(
      TextContext(
        word: 'тест',
        before: before,
        after: '',
        range: EditRange(before.length, before.length + 4),
        locale: 'ru',
        fullMessage: '$before${'тест'}',
        boundary: '.',
      ),
    );
    expect(
      result.signals.where((s) => s.kind == SignalKind.aiAssist),
      isNotEmpty,
    );
    expect(result.decision.state, isA<PanelAiAssist>());
  });

  test('ai assistant off skips sentence chips', () {
    final engine = LocalIntelligenceEngine();
    engine.applySettings(const KeyboardSettings(aiAssistant: false));
    final before = 'Это достаточно длинное сообщение для теста';
    final result = engine.process(
      TextContext(
        word: 'тест',
        before: before,
        after: '',
        range: EditRange(before.length, before.length + 4),
        locale: 'ru',
        fullMessage: '$before${'тест'}',
        boundary: '!',
      ),
    );
    expect(
      result.signals.where((s) => s.kind == SignalKind.aiAssist),
      isEmpty,
    );
  });

  test('peekRaw skips refresh when caller already refreshed', () async {
    final backing = _MemoryKvStore();
    final split = _SplitMemoryKvStore(backing);
    final repo = KeyboardSettingsRepository.bind(split);
    // Hydrate empty cache first.
    expect(await repo.peekRaw(), isNull);
    await backing.setStringAtomic(
      KeyboardSettingsRepository.storageKey,
      jsonEncode(const KeyboardSettings(antiMat: false).toJson()),
    );
    // Stale until refresh.
    expect(await repo.peekRaw(), isNull);
    await repo.refresh();
    expect(await repo.peekRaw(), isNotNull);
    expect(
      KeyboardSettingsRepository.parseRaw(await repo.peekRaw()).antiMat,
      isFalse,
    );
  });

  test('disabled antiMat skips mat detection', () {
    final engine = LocalIntelligenceEngine();
    engine.applySettings(const KeyboardSettings(antiMat: false));
    final result = engine.process(ctx('хуй', locale: 'ru'));
    expect(
      result.signals.where((s) => s.kind == SignalKind.mat),
      isEmpty,
    );
  });

  test('disabled antiToxic skips toxic detection', () {
    final engine = LocalIntelligenceEngine();
    engine.applySettings(const KeyboardSettings(antiToxic: false));
    final result = engine.process(ctx('идиот', locale: 'ru'));
    expect(
      result.signals.where((s) => s.kind == SignalKind.toxic),
      isEmpty,
    );
  });

  test('unknown word stays idle without spell panel', () {
    final engine = LocalIntelligenceEngine();
    final result = engine.process(ctx('helo', locale: 'en'));
    expect(result.decision.state, isA<PanelIdle>());
  });

  test('disabled improve skips improve signal', () {
    final engine = LocalIntelligenceEngine();
    engine.applySettings(const KeyboardSettings(textImprovement: false));
    final before = 'word ' * 12;
    final result = engine.process(ctx('fine', locale: 'en', before: before));
    expect(
      result.signals.where((s) => s.kind == SignalKind.improve),
      isEmpty,
    );
  });

  test('readRaw picks up writes from another engine after refresh', () async {
    final backing = _MemoryKvStore();
    await backing.setStringAtomic(
      KeyboardSettingsRepository.storageKey,
      jsonEncode(const KeyboardSettings(antiMat: false).toJson()),
    );
    final imeRepo = KeyboardSettingsRepository.bind(_SplitMemoryKvStore(backing));

    final loaded = await imeRepo.load();
    expect(loaded.antiMat, isFalse);
  });
}
