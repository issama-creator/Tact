/// Toxic lexicon categories — dictionary-only classification.
library;

enum ToxicCategory {
  insult,
  aggressive,
  dismissive,
  hostile;

  static ToxicCategory? parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final key = raw.toLowerCase().trim();
    return switch (key) {
      'insult' => ToxicCategory.insult,
      'aggressive' => ToxicCategory.aggressive,
      'dismissive' => ToxicCategory.dismissive,
      'hostile' => ToxicCategory.hostile,
      _ => null,
    };
  }

  String get wireName => name;
}

/// One toxic lexicon entry with severity and category.
final class ToxicEntry {
  const ToxicEntry({
    required this.score,
    this.category,
  });

  final int score;
  final ToxicCategory? category;
}

/// Immutable O(1) toxic lexicon — normalized token → entry.
final class ToxicLexicon {
  ToxicLexicon._(
    this._entries,
    this.warningThreshold,
    this.conflictThreshold,
  );

  final Map<String, ToxicEntry> _entries;
  final int warningThreshold;
  final int conflictThreshold;

  factory ToxicLexicon.fromEntries(
    Map<String, ToxicEntry> entries, {
    int warningThreshold = 50,
    int conflictThreshold = 75,
  }) {
    final normalized = <String, ToxicEntry>{};
    for (final e in entries.entries) {
      final key = e.key.toLowerCase();
      if (key.isEmpty) continue;
      normalized[key] = e.value;
    }
    return ToxicLexicon._(
      Map<String, ToxicEntry>.unmodifiable(normalized),
      warningThreshold,
      conflictThreshold,
    );
  }

  ToxicEntry? lookup(String normalizedToken) =>
      _entries[normalizedToken.toLowerCase()];

  int get size => _entries.length;

  int get warningAt => warningThreshold;

  int get conflictAt => conflictThreshold;
}
