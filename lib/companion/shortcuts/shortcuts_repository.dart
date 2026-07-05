/// Companion-facing facade over [HotwordsRepository].
library;

import '../../core/hotwords/hotwords_repository.dart';
import '../../core/hotwords/user_hotword.dart';

export '../../core/hotwords/user_hotword.dart';

final class ShortcutsRepository {
  ShortcutsRepository._();

  static Future<ShortcutsRepository> open() async {
    await HotwordsRepository.open();
    return ShortcutsRepository._();
  }

  Future<List<UserHotword>> all() => HotwordsRepository.instance.loadAll();

  Future<UserHotword> upsert({
    String? id,
    required String trigger,
    required String expansion,
  }) =>
      HotwordsRepository.instance.upsert(
        id: id,
        trigger: trigger,
        expansion: expansion,
      );

  Future<void> delete(String id) => HotwordsRepository.instance.delete(id);
}
