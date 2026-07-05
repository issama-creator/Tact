// lib/keyboard/input/input_pipeline.dart
//
// InputPipeline — routes word-boundary events into engines and rules.
//
// Purpose:
//   • Subscribes to `ImeBridge.onWordCommitted`.
//   • Builds an immutable TextContext.
//   • Drops words shorter than 3 characters (see docs/RULES.md).
//   • Fans the context out to every SignalProvider (engines).
//   • Collects RuleSignal[] and forwards to RulesEngine.
//   • Cancels stale work on subsequent keystrokes (latest-only).
//
// Concurrency note:
//   In MVP the engines run synchronously on the UI isolate. HashSet / HashMap
//   / small trie lookups are microsecond-scale — a dedicated isolate is not
//   justified yet. If future profiling proves otherwise for a specific
//   engine, we add an isolate then, and only for that engine.
//
// Contents (planned):
//   • class InputPipeline
//       - InputPipeline(this._bridge, this._engines, this._rules, this._sm);
//       - void start();
//       - void stop();
//       - void _onWord(WordEvent event);   // internal
//
// Depends on:
//   core/bridge/ime_bridge_facade.dart,
//   input/text_context.dart,
//   engines/signal_provider.dart,
//   rules/rules_engine.dart,
//   state/keyboard_state_machine.dart.
// Must NOT: import Flutter (pure Dart module).
//
// TODO: implement.
library;
