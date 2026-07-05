/// Shared word-length gates for the intelligence pipeline.
library;

/// Spell, mat, toxic, and next-word suggestions run at this length or longer.
/// Skips short tokens like «я», «ты», «и», «мы».
const int kMinLexiconWordLength = 3;

/// Shortcut triggers (др, пж, …) may be two graphemes.
const int kMinShortcutTriggerLength = 2;

/// True when lexicon engines and next-word chips should run.
bool shouldRunLexiconAnalysis(String word) =>
    word.length >= kMinLexiconWordLength;

/// True when a completed word should enter the pipeline at all.
bool shouldProcessWordBoundary(String word) =>
    word.trim().length >= kMinShortcutTriggerLength;
