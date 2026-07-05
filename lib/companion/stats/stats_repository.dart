// lib/companion/stats/stats_repository.dart
//
// StatsRepository — read side of core/statistics.dart.
//
// The IME writes StatEvents via `Statistics`. The companion reads aggregated
// counters via this repository.
//
// Contents (planned):
//   • class StatsSummary {
//       final double wpmRollingAvg;
//       final int correctionsAccepted;
//       final int softeningsApplied;
//       final int removesApplied;
//       final int improvementsApplied;
//       final int shortcutsExpanded;
//     }
//   • abstract class StatsRepository {
//       Future<StatsSummary> summary({Duration window = const Duration(days: 30)});
//       Stream<StatsSummary> watch();
//     }
//
// Depends on: core/statistics.dart (shared write/read format).
// Must NOT: import Flutter widgets.
//
// TODO: implement.
library;
