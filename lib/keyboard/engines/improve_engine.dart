// lib/keyboard/engines/improve_engine.dart
//
// ImproveEngine — implements SignalProvider.
//
// Emits SignalKind.improve when:
//   • The current message (not the word) is longer than ~30 characters, AND
//   • No other signal is present in this context.
//
// Unlike the other engines, ImproveEngine looks at the whole message, not
// just the last word. The RulesEngine still decides whether to show it and
// which slot it takes.
//
// Contents (planned):
//   • class ImproveEngine implements SignalProvider {
//       ImproveEngine({int minChars = 30});
//       @override List<RuleSignal> analyze(TextContext ctx);
//     }
//
// Notes:
//   • This engine is a signal producer, not an editor. The actual improvement
//     is performed by ImproveAction (keyboard/actions/text_actions.dart) via
//     the AiService, only after the user taps [Improve].
//   • Threshold `minChars` may become a tunable later.
//
// Depends on: engines/signal_provider.dart, rules/rule_signal.dart, input/text_context.dart.
// Must NOT: import Flutter or plugins.
//
// TODO: implement.
library;
