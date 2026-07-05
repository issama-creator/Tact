// lib/keyboard/dictionaries/dictionary_loader.dart
//
// DictionaryLoader — lazy per-language loading of Dictionary objects.
//
// Purpose:
//   • Loads a Dictionary from `assets/dictionaries/<locale>.bin` on first use.
//   • Caches loaded Dictionaries in a small LRU (typically 1–2 languages hot).
//   • Unloads on memory pressure — important for iOS keyboard extensions
//     which run with a tight memory budget.
//
// Contents (planned):
//   • class DictionaryLoader {
//       Future<Dictionary> load(String locale);
//       void evictAllExcept(String locale);
//       void evictAll();
//     }
//
// Depends on: dictionaries/dictionary.dart. Uses rootBundle to read assets.
// Must NOT: import package:flutter/material or widgets. Asset access only.
//
// TODO: implement.
library;
