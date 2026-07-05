// lib/core/logger.dart
//
// Minimal leveled logger.
//
// Purpose:
//   One tiny logger shared by all layers. Debug/info/warn/error. Off by default
//   in release builds. Not a framework — one file.
//
// Contents (planned):
//   • enum LogLevel { debug, info, warn, error }
//   • class Log with static methods: d(), i(), w(), e(String tag, Object msg)
//   • Log.level = LogLevel.warn in release, debug in debug builds.
//
// Depends on: nothing.
// Must NOT: log user text content (privacy).
//
// TODO: implement.
library;
