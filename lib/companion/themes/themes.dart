// lib/companion/themes/themes.dart
//
// Companion app themes + theme picker screen.
//
// One file, two responsibilities (they always change together in a small app):
//   • AppTheme  — Material 3 light + dark ColorSchemes for the companion.
//   • ThemesScreen — picker: system / light / dark. Applies to companion AND,
//                    via SettingsRepository, hints the keyboard theme.
//
// Note:
//   The keyboard's own theme tokens are in lib/keyboard/theme/keyboard_theme.dart.
//   This file is only for the companion app.
//
// Contents (planned):
//   • class AppTheme (static getters: light, dark)
//   • class ThemesScreen extends ConsumerWidget
//
// Depends on: companion/settings/settings_repository.dart.
// Must NOT: reference keyboard engines.
//
// TODO: implement.
library;
