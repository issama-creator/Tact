// lib/keyboard/engines/normalizer.dart
//
// Shared text normalization used by spell / toxic / mat engines.
//
// Purpose:
//   Reduce false negatives from users typing `аcc`, `Fu.ck`, `s h i t`, etc.
//   Applied only when checking membership in lexicons — the user's original
//   text is NEVER modified.
//
// Operations (planned):
//   • toLowerCase                 (Unicode-aware)
//   • strip diacritics            (é → e, ё → е)
//   • fold leetspeak              (0→o, 1→i/l, 3→e, 4→a, 5→s, 7→t, @→a, $→s)
//   • collapse repeated chars     ("suuuupeeer" → "super")
//   • strip non-letters           (spaces, punctuation)
//
// Contract:
//   • String normalize(String input, {required String locale});
//   • Pure. No allocations beyond the returned String where possible.
//
// Depends on: nothing.
// Must NOT: import Flutter or plugins.
//
// TODO: implement.
library;
