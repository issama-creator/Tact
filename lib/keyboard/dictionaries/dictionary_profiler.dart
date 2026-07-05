/// Debug-only dictionary load diagnostics — stripped in release.
library;

import 'package:flutter/foundation.dart';

import 'locale_bundle.dart';

/// One load/reload timing report.
final class DictionaryLoadReport {
  const DictionaryLoadReport({
    required this.loadDuration,
    required this.lookupDurationNs,
    required this.bundles,
    required this.builtinShortcutCount,
    required this.source,
  });

  final Duration loadDuration;
  final int lookupDurationNs;
  final Map<String, LocaleBundle> bundles;
  final int builtinShortcutCount;
  final String source;

  int get totalWords =>
      bundles.values.fold(0, (sum, b) => sum + b.stats.spellWords);

  int get estimatedBytes =>
      bundles.values.fold(0, (sum, b) => sum + b.stats.estimatedBytes);
}

/// Profiles dictionary loading and lookup — disabled in release builds.
final class DictionaryProfiler {
  DictionaryProfiler._();

  static DictionaryLoadReport? lastReport;

  static void record(DictionaryLoadReport report) {
    if (kReleaseMode) return;
    lastReport = report;
  }

  static void logSummary() {
    if (kReleaseMode) return;
    final r = lastReport;
    if (r == null) return;
    debugPrint(
      '[TACT Dict] source=${r.source} '
      'load=${r.loadDuration.inMilliseconds}ms '
      'words=${r.totalWords} '
      'est=${r.estimatedBytes}B '
      'lookup=${r.lookupDurationNs}ns '
      'shortcuts=${r.builtinShortcutCount}',
    );
  }
}
