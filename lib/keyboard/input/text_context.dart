// lib/keyboard/input/text_context.dart
//
// TextContext — the immutable snapshot of "what was just typed".
//
// Emitted by the InputPipeline at word boundaries and consumed by engines
// and RulesEngine. Immutable so it is safe to share and cache.
//
// Contents (planned):
//   • class TextContext {
//       final String word;         // the completed word (already trimmed)
//       final String before;       // limited text before the word (~64 chars)
//       final String after;        // limited text after the cursor (~16 chars)
//       final EditRange range;     // where in the target field
//       final String locale;       // active language tag
//     }
//   • class EditRange { final int start; final int end; }
//
// Depends on: nothing.
// Must NOT: import Flutter or plugins.
//
// TODO: implement.
library;
