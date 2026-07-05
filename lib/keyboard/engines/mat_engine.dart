// lib/keyboard/engines/mat_engine.dart
//
// MatEngine — implements SignalProvider.
//
// Emits SignalKind.mat when the normalized word is a member of the
// language-specific profanity lexicon (RU / EN / ...).
//
// Same shape as ToxicEngine, different lexicon. Kept as a separate class so
// the two vocabularies and their thresholds can evolve independently.
//
// Contents (planned):
//   • class MatEngine implements SignalProvider {
//       MatEngine(this._lexicon, this._normalizer);
//       final Set<String> _lexicon;
//       final Normalizer _normalizer;
//       @override List<RuleSignal> analyze(TextContext ctx);
//     }
//
// Depends on: engines/signal_provider.dart, engines/normalizer.dart,
//             dictionaries/lexicon_loader.dart.
// Must NOT: import Flutter or plugins.
//
// TODO: implement.
library;
