/// Loads personal dictionary into the intelligence engine.
library;

import '../../core/personal_words/personal_words_repository.dart';
import '../intelligence/local_intelligence_engine.dart';

final class PersonalWordsLoader {
  PersonalWordsLoader(this._engine);

  final LocalIntelligenceEngine _engine;
  bool _opened = false;
  String? _lastRaw;

  Future<void> ensureOpen() async {
    if (_opened) return;
    await PersonalWordsRepository.open();
    _opened = true;
  }

  Future<void> reload() async {
    await ensureOpen();
    final raw = await PersonalWordsRepository.instance.readRaw();
    if (raw == _lastRaw) return;
    _lastRaw = raw;
    final words = await PersonalWordsRepository.instance.loadAll();
    _engine.setPersonalWords(words);
  }
}
