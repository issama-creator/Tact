// test/rules_engine_test.dart
//
// The most important test in TACT.
//
// Goldens for the panel priority contract (docs/RULES.md):
//   • Given signals [SpellError, Mat, Toxic, Improve, NextWord]
//     → PanelDecision fills slots in that order.
//   • Dedup: Mat + Toxic on same range → only Mat slot.
//   • Slot budget = 3 → NextWords are dropped first.
//   • Hysteresis: a small severity change does NOT swap a visible slot.
//   • Improve is NEVER shown when any of {SpellError, Mat, Toxic} is present.
//
// Style:
//   • Table-driven. Each row = (input signals, expected decision).
//   • Deterministic. No timing dependencies except a fake clock for hysteresis.
//
// TODO: implement.
library;
