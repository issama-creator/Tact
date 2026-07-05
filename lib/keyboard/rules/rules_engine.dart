// lib/keyboard/rules/rules_engine.dart
//
// RulesEngine — the UX brain of TACT.
//
// Consumes RuleSignal[] for a TextContext and produces exactly one
// PanelDecision. Pure, synchronous, deterministic. Trivially testable.
//
// Priority (higher wins the highest-priority slot):
//   1. SpellError
//   2. Mat (profanity)
//   3. Toxic
//   4. Improve
//   5. NextWord (normal suggestion)
//
// Guarantees (see docs/RULES.md):
//   • Deduplication (Mat + Toxic on same range → one slot).
//   • Slot budget (N slots max; default 3).
//   • Hysteresis to prevent panel flicker (a signal must exceed the previous
//     by a threshold to replace an already-shown slot).
//   • Passivity — decisions never include an automatic mutation. Only chips.
//
// Contents (planned):
//   • class RulesEngineSettings { final int slotBudget; final Duration hysteresis; }
//   • class RulesEngine {
//       PanelDecision evaluate(List<RuleSignal> signals, RulesEngineSettings s);
//     }
//   • The priority order is a private const list — modifying it is a design
//     decision documented in docs/RULES.md.
//
// Depends on: rules/rule_signal.dart, panel/panel_state.dart.
// Must NOT: import Flutter, plugins, or perform I/O.
//
// TODO: implement.
library;
