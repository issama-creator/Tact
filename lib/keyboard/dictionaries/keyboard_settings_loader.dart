/// Loads companion keyboard toggles into the intelligence engine.
library;

import '../../core/keyboard_settings/keyboard_settings.dart';
import '../../core/keyboard_settings/keyboard_settings_repository.dart';
import '../intelligence/local_intelligence_engine.dart';

final class KeyboardSettingsLoader {
  KeyboardSettingsLoader(this._engine);

  final LocalIntelligenceEngine _engine;
  bool _opened = false;
  bool _openedOnce = false;
  String? _lastRaw;
  KeyboardSettings _last = KeyboardSettings.defaults;

  KeyboardSettings get current => _last;

  Future<void> ensureOpen() async {
    if (_opened) return;
    await KeyboardSettingsRepository.open();
    _opened = true;
  }

  /// Reads settings without refreshing prefs — caller must refresh once.
  Future<KeyboardSettings?> reloadPeek() async {
    await ensureOpen();
    final raw = await KeyboardSettingsRepository.instance.peekRaw();
    if (_openedOnce && raw == _lastRaw) return null;
    _openedOnce = true;
    _lastRaw = raw;
    final settings = KeyboardSettingsRepository.parseRaw(raw);
    _last = settings;
    _engine.applySettings(settings);
    return settings;
  }
}
