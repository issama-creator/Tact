/// Loads user hotwords into the intelligence engine.
library;

import '../../core/hotwords/hotwords_mapper.dart';
import '../../core/hotwords/hotwords_repository.dart';
import '../intelligence/local_intelligence_engine.dart';

final class HotwordsLoader {
  HotwordsLoader(this._engine);

  final LocalIntelligenceEngine _engine;
  bool _opened = false;

  Future<void> ensureOpen() async {
    if (_opened) return;
    await HotwordsRepository.open();
    _opened = true;
  }

  Future<void> reload() async {
    await ensureOpen();
    final items = await HotwordsRepository.instance.loadAll();
    _engine.setUserShortcuts(HotwordsMapper.toTextShortcuts(items));
  }
}
