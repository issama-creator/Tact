// lib/core/statistics.dart
//
// User-facing Statistics (not analytics).
//
// Purpose:
//   Tracks metrics the user cares about and sees in `companion/stats/`:
//     • WPM (rolling average).
//     • Corrections accepted (Fix taps that were applied).
//     • Softenings applied.
//     • Removes applied.
//     • Improvements applied.
//     • Shortcuts expanded.
//
//   This is NOT analytics. There is no crash/perf reporting here.
//   When we add crash/perf (post-MVP), it goes into a separate file, not this one.
//
// Contents (planned):
//   • class StatEvent (immutable): kind + timestamp + delta.
//   • class Statistics: fire-and-forget `record(event)`; small ring buffer;
//     periodic flush to KvStore or a lightweight local DB.
//   • Read side lives in lib/companion/stats/stats_repository.dart.
//
// Depends on: core/kv_store.dart.
// Must NOT: touch network. Must NOT record user text — only counters and durations.
//
// TODO: implement.
library;
