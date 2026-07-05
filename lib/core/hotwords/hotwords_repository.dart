/// Local persistence for user hotwords — shared by companion app and IME.
library;

import 'dart:convert';

import '../kv_store.dart';
import 'user_hotword.dart';

final class HotwordsRepository {
  HotwordsRepository._(this._store);

  static const storageKey = 'tact.user_hotwords';
  static HotwordsRepository? _instance;

  final KvStore _store;

  static Future<HotwordsRepository> open() async {
    if (_instance != null) return _instance!;
    final store = await SharedPrefsKvStore.open();
    return bind(store);
  }

  /// Test hook — binds an in-memory [KvStore].
  static HotwordsRepository bind(KvStore store) {
    _instance = HotwordsRepository._(store);
    return _instance!;
  }

  /// Synchronous access after [open] was called once in this isolate.
  static HotwordsRepository get instance {
    final repo = _instance;
    if (repo == null) {
      throw StateError('Call HotwordsRepository.open() first');
    }
    return repo;
  }

  Future<List<UserHotword>> loadAll() async {
    final raw = await _store.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final list = decoded
          .whereType<Map>()
          .map((e) => UserHotword.fromJson(Map<String, dynamic>.from(e)))
          .where((h) => h.trigger.isNotEmpty && h.expansion.isNotEmpty)
          .toList();
      list.sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
      return List<UserHotword>.from(list);
    } catch (_) {
      return const [];
    }
  }

  Future<void> saveAll(List<UserHotword> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _store.setString(storageKey, encoded);
  }

  Future<UserHotword> upsert({
    String? id,
    required String trigger,
    required String expansion,
  }) async {
    final trimmedTrigger = trigger.trim();
    final trimmedExpansion = expansion.trim();
    if (trimmedTrigger.length < 2) {
      throw ArgumentError('trigger must be at least 2 characters');
    }
    if (trimmedExpansion.isEmpty) {
      throw ArgumentError('expansion cannot be empty');
    }

    final all = List<UserHotword>.from(await loadAll());
    final now = DateTime.now().millisecondsSinceEpoch;
    final newId = id ?? now.toString();
    final item = UserHotword(
      id: newId,
      trigger: trimmedTrigger,
      expansion: trimmedExpansion,
      updatedAtMs: now,
    );

    final idx = all.indexWhere((h) => h.id == newId);
    if (idx >= 0) {
      all[idx] = item;
    } else {
      all.add(item);
    }
    await saveAll(all);
    return item;
  }

  Future<void> delete(String id) async {
    final all = List<UserHotword>.from(await loadAll())
      ..removeWhere((h) => h.id == id);
    await saveAll(all);
  }
}
