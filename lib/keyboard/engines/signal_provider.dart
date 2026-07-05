// lib/keyboard/engines/signal_provider.dart
//
// SignalProvider — the single interface every engine implements.
//
// This is the extensibility seam of TACT. Adding a new engine = implementing
// this interface + registering in keyboard_app.dart + adding a priority
// entry in RulesEngine.
//
// Contract:
//   • List<RuleSignal> analyze(TextContext ctx);
//   • Must be pure and fast (target < 1 ms per call for local engines).
//   • Must be safe to call synchronously on the UI isolate (MVP concurrency).
//   • Must return [] (never null) when the context is out of scope
//     (wrong locale, no signal, word too short, etc.).
//
// Contents (planned):
//   • abstract class SignalProvider {
//       List<RuleSignal> analyze(TextContext ctx);
//     }
//
// Depends on: rules/rule_signal.dart, input/text_context.dart.
// Must NOT: import Flutter or plugins.
//
// TODO: implement.
library;
