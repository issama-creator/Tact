import 'package:flutter_test/flutter_test.dart';
import 'package:tact/core/hotwords/hotwords_mapper.dart';
import 'package:tact/core/hotwords/hotwords_repository.dart';
import 'package:tact/core/hotwords/user_hotword.dart';
import 'package:tact/core/kv_store.dart';
import 'package:tact/keyboard/engines/shortcut_table.dart';

final class _MemoryKvStore implements KvStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<bool> remove(String key) async => _data.remove(key) != null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('user hotword overrides builtin trigger', () {
    final table = ShortcutTable(
      builtin: {
        'др': const TextShortcut(trigger: 'др', expansions: ['Built-in']),
      },
      user: [
        const TextShortcut(
          trigger: 'др',
          expansions: ['Добрый день'],
          source: ShortcutSource.user,
        ),
      ],
    );
    expect(table.lookup('др')!.expansions.first, 'Добрый день');
  });

  test('mapper groups and limits to 3 expansions per trigger', () {
    final mapped = HotwordsMapper.toTextShortcuts([
      const UserHotword(
        id: '1',
        trigger: 'др',
        expansion: 'Добрый день',
        updatedAtMs: 3,
      ),
      const UserHotword(
        id: '2',
        trigger: 'др',
        expansion: 'Доброе утро',
        updatedAtMs: 2,
      ),
      const UserHotword(
        id: '3',
        trigger: 'др',
        expansion: 'Добрый вечер',
        updatedAtMs: 1,
      ),
      const UserHotword(
        id: '4',
        trigger: 'др',
        expansion: 'Extra',
        updatedAtMs: 0,
      ),
    ]);
    expect(mapped, hasLength(1));
    expect(mapped.first.expansions, hasLength(3));
    expect(mapped.first.expansions.first, 'Добрый день');
  });

  test('repository persists hotwords', () async {
    final repo = HotwordsRepository.bind(_MemoryKvStore());
    await repo.upsert(trigger: 'др', expansion: 'Добрый день');
    final all = await repo.loadAll();
    expect(all, hasLength(1));
    expect(all.first.trigger, 'др');
    expect(all.first.expansion, 'Добрый день');
  });
}
