/// Loads user hotwords into the intelligence engine.
library;

import '../../core/hotwords/hotwords_mapper.dart';
import '../../core/hotwords/hotwords_repository.dart';
import '../intelligence/local_intelligence_engine.dart';

final class HotwordsLoader {
  HotwordsLoader(this._engine);

  final LocalIntelligenceEngine _engine;
  bool _opened = false;
  bool _loadedOnce = false;
  String? _lastRaw;

  Future<void> ensureOpen() async {
    if (_opened) return;
    await HotwordsRepository.open();
    _opened = true;
  }

  /// Reads hotwords without refreshing prefs — caller must refresh once.
  Future<void> reloadPeek() async {
    await ensureOpen();
    final raw = await HotwordsRepository.instance.peekRaw();
    if (_loadedOnce && raw == _lastRaw) return;
    _loadedOnce = true;
    _lastRaw = raw;
    final items = await HotwordsRepository.instance.loadAll();
    _engine.setUserShortcuts(HotwordsMapper.toTextShortcuts(items));
  }
}
