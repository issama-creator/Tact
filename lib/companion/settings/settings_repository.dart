// lib/companion/settings/settings_repository.dart
//
// SettingsRepository — reactive KV-backed settings storage.
//
// Contents (planned):
//   • class SettingsRepository {
//       SettingsRepository(this._kv);
//       Future<Settings> load();
//       Future<void> save(Settings s);
//       Stream<Settings> watch();
//     }
//
// Read on both sides:
//   • Companion: for the settings screen.
//   • IME (keyboard_app.dart): to know which engines are enabled, which
//     locale is active, panel budget, etc.
//
// Depends on: core/kv_store.dart, companion/settings/settings.dart.
// Must NOT: import Flutter widgets.
//
// TODO: implement.
library;
