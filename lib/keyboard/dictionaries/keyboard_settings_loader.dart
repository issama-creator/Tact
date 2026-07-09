/// Loads companion keyboard toggles into the intelligence engine.
library;

import '../../core/keyboard_settings/keyboard_settings_repository.dart';
import '../intelligence/local_intelligence_engine.dart';

final class KeyboardSettingsLoader {
  KeyboardSettingsLoader(this._engine);

  final LocalIntelligenceEngine _engine;
  bool _opened = false;
  String? _lastRaw;

  Future<void> ensureOpen() async {
    if (_opened) return;
    await KeyboardSettingsRepository.open();
    _opened = true;
  }

  Future<void> reload() async {
    await ensureOpen();
    final raw = await KeyboardSettingsRepository.instance.readRaw();
    if (raw == _lastRaw) return;
    _lastRaw = raw;
    final settings = await KeyboardSettingsRepository.instance.load();
    _engine.applySettings(settings);
  }
}
