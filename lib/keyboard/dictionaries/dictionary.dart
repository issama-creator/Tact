// lib/keyboard/dictionaries/dictionary.dart
//
// Dictionary — the query facade over one language's word data.
//
// Two internal structures:
//   • HashSet<String> for O(1) membership → SpellEngine, ShortcutEngine.
//   • Trie / FST      for prefix + bounded-edit-distance search → correction candidates.
//
// Contents (planned):
//   • class Dictionary {
//       Dictionary(this._members, this._trie);
//       bool contains(String word);
//       List<String> candidates(String word, {int maxEdits = 2, int max = 5});
//       List<String> completions(String prefix, {int max = 5});
//     }
//
// The choice of trie vs FST is an implementation detail behind this facade.
// If we replace one, no engine code changes.
//
// Depends on: nothing.
// Must NOT: import Flutter or plugins. Loading concern is separate (dictionary_loader.dart).
//
// TODO: implement.
library;
