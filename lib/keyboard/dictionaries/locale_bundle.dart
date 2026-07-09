/// Immutable per-locale dictionary bundle — single memory owner.
library;

import 'dictionary.dart';
import 'mat_lexicon.dart';
import 'phrase_spell.dart';
import 'toxic_category.dart';
import 'typo_dictionary.dart';

/// Load-time statistics for one locale bundle.
final class BundleStats {
  const BundleStats({
    required this.spellWords,
    required this.typoEntries,
    required this.matTokens,
    required this.toxicEntries,
    required this.phraseSpellEntries,
    required this.nextWordKeys,
    required this.estimatedBytes,
  });

  final int spellWords;
  final int typoEntries;
  final int matTokens;
  final int toxicEntries;
  final int phraseSpellEntries;
  final int nextWordKeys;
  final int estimatedBytes;

  int get totalEntries =>
      spellWords +
      typoEntries +
      matTokens +
      toxicEntries +
      phraseSpellEntries +
      nextWordKeys;
}

/// All dictionary data for one locale — loaded once, never mutated.
final class LocaleBundle {
  const LocaleBundle({
    required this.locale,
    required this.version,
    required this.spell,
    required this.typo,
    required this.mat,
    required this.toxic,
    required this.phraseSpell,
    required this.stats,
  });

  final String locale;
  final int version;
  final Dictionary spell;
  final TypoDictionary typo;
  final MatLexicon mat;
  final ToxicLexicon toxic;
  final PhraseSpellLexicon phraseSpell;
  final BundleStats stats;
}
