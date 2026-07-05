// lib/keyboard/rules/rule_signal.dart
//
// RuleSignal — a normalized message emitted by an engine for a TextContext.
//
// Engines never talk to the panel directly. They emit RuleSignals; the
// RulesEngine decides what to show. Adding a new engine is a matter of
// adding a new SignalKind + a corresponding rule entry in RulesEngine.
//
// Contents (planned):
//   • enum SignalKind {
//       spellError,     // priority 1
//       mat,            // priority 2  (profanity)
//       toxic,          // priority 3
//       improve,        // priority 4
//       nextWord,       // priority 5  (normal Gboard-style suggestion)
//       shortcutMatch,  // trigger → expansion (offered, not auto-applied)
//     }
//   • class RuleSignal {
//       final SignalKind kind;
//       final int severity;         // 0–100
//       final double confidence;    // 0.0–1.0
//       final EditRange range;      // to which text range this refers
//       final Object? payload;      // e.g. correction candidates
//     }
//
// Depends on: input/text_context.dart (for EditRange).
// Must NOT: import Flutter or plugins.
//
// TODO: implement.
library;
