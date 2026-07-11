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

/// Immutable O(1) toxic lexicon — normalized token → entry + phrase scan.
final class ToxicLexicon {
  ToxicLexicon._(
    this._entries,
    this._phrases,
    this.warningThreshold,
    this.conflictThreshold,
  );

  final Map<String, ToxicEntry> _entries;
  /// Longest phrases first for greedy substring match.
  final List<MapEntry<String, ToxicEntry>> _phrases;
  final int warningThreshold;
  final int conflictThreshold;

  factory ToxicLexicon.fromEntries(
    Map<String, ToxicEntry> entries, {
    Map<String, ToxicEntry> phrases = const {},
    int warningThreshold = 50,
    int conflictThreshold = 75,
  }) {
    final normalized = <String, ToxicEntry>{};
    for (final e in entries.entries) {
      final key = e.key.toLowerCase();
      if (key.isEmpty) continue;
      normalized[key] = e.value;
    }

    final phraseList = <MapEntry<String, ToxicEntry>>[];
    for (final e in phrases.entries) {
      final key = e.key.toLowerCase().trim();
      if (key.length < 4) continue;
      phraseList.add(MapEntry(key, e.value));
    }
    phraseList.sort((a, b) => b.key.length.compareTo(a.key.length));

    return ToxicLexicon._(
      Map<String, ToxicEntry>.unmodifiable(normalized),
      List<MapEntry<String, ToxicEntry>>.unmodifiable(phraseList),
      warningThreshold,
      conflictThreshold,
    );
  }

  ToxicEntry? lookup(String normalizedToken) => _entries[normalizedToken];

  /// Scans a normalized message for multi-word toxic phrases.
  ToxicEntry? lookupPhrase(String normalizedMessage) {
    if (normalizedMessage.isEmpty || _phrases.isEmpty) return null;
    for (final p in _phrases) {
      if (normalizedMessage.contains(p.key)) return p.value;
    }
    return null;
  }

  int get size => _entries.length;

  int get phraseCount => _phrases.length;

  int get warningAt => warningThreshold;

  int get conflictAt => conflictThreshold;
}
