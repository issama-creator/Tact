// lib/keyboard/dictionaries/lexicon_loader.dart
//
// LexiconLoader — loads toxic / mat hashsets from binary assets.
//
// Same shape as DictionaryLoader but for the small membership-only sets
// consumed by ToxicEngine and MatEngine.
//
// Contents (planned):
//   • enum LexiconKind { toxic, mat }
//   • class LexiconLoader {
//       Future<Set<String>> load(LexiconKind kind, String locale);
//       void evictAll();
//     }
//
// Depends on: nothing beyond dart:async and rootBundle.
// Must NOT: import Flutter widgets. Asset access only.
//
// TODO: implement.
library;
