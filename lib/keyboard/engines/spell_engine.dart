// lib/keyboard/engines/spell_engine.dart
//
// SpellEngine — implements SignalProvider.
//
// Emits SignalKind.spellError when:
//   • ctx.word.length >= 3, AND
//   • ctx.word is not in the active-language Dictionary, AND
//   • ctx.word is not in the user's personal dictionary, AND
//   • a bounded Damerau-Levenshtein search over the Dictionary yields
//     at least one candidate within edit distance 2.
//
// Contents (planned):
//   • class SpellEngine implements SignalProvider {
//       SpellEngine(this._dict, this._userDict);
//       final Dictionary _dict;
//       final Dictionary _userDict;
//       @override List<RuleSignal> analyze(TextContext ctx);
//     }
//   • Candidate list is attached to the RuleSignal.payload as List<String>.
//
// Depends on: engines/signal_provider.dart, dictionaries/dictionary.dart.
// Must NOT: import Flutter or plugins.
//
// TODO: implement.
library;
