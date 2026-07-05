// test/spell_engine_test.dart
//
// SpellEngine invariants:
//   • Words with length < 3 → no signal (never).
//   • In-dictionary words → no signal.
//   • Personal-dictionary words → no signal.
//   • Out-of-dictionary word with at least one candidate within edit
//     distance 2 → SpellError signal with candidates in payload.
//   • No candidates → no signal (do not annoy the user).
//   • Deterministic ordering of candidates.
//
// Uses in-memory fake Dictionary — no assets required for unit tests.
//
// TODO: implement.
library;
