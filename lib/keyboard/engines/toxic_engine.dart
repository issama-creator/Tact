// lib/keyboard/engines/toxic_engine.dart
//
// ToxicEngine — implements SignalProvider.
//
// Emits SignalKind.toxic when the normalized word is a member of the
// language-specific toxic lexicon (loaded via LexiconLoader).
//
// Contents (planned):
//   • class ToxicEngine implements SignalProvider {
//       ToxicEngine(this._lexicon, this._normalizer);
//       final Set<String> _lexicon;
//       final Normalizer _normalizer;
//       @override List<RuleSignal> analyze(TextContext ctx);
//     }
//
// Notes:
//   • Purely passive: never rewrites, never censors. The panel shows a hint.
//   • False positives are inevitable — users can suppress a word by adding it
//     to the personal allow-list (settings).
//
// Depends on: engines/signal_provider.dart, engines/normalizer.dart,
//             dictionaries/lexicon_loader.dart.
// Must NOT: import Flutter or plugins.
//
// TODO: implement.
library;
