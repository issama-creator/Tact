/// Profanity lexicon — O(1) exact tokens + prefix stems with severity levels.
library;

/// [block] — auto-removed on word boundary when anti-mat is on.
/// [warn] — word stays; suggestion bar offers [Remove].
enum MatLevel {
  block,
  warn,
}

/// Immutable mat lexicon with exact and stem-prefix matching.
final class MatLexicon {
  MatLexicon._(this._exact, this._stems);

  final Map<String, MatLevel> _exact;
  /// Longest stems first — early exit on first prefix hit.
  final List<({String stem, MatLevel level})> _stems;

  /// [tokens] / [stems] without levels default to [MatLevel.warn].
  /// [tokenLevels] / [stemLevels] override per entry.
  factory MatLexicon.fromParts({
    Iterable<String> tokens = const [],
    Iterable<String> stems = const [],
    Map<String, MatLevel> tokenLevels = const {},
    Map<String, MatLevel> stemLevels = const {},
  }) {
    final exact = <String, MatLevel>{};
    for (final t in tokens) {
      final key = t.toLowerCase().trim();
      if (key.length >= 2) {
        exact[key] = tokenLevels[key] ?? MatLevel.warn;
      }
    }
    for (final e in tokenLevels.entries) {
      final key = e.key.toLowerCase().trim();
      if (key.length >= 2) exact[key] = e.value;
    }

    final stemMap = <String, MatLevel>{};
    for (final s in stems) {
      final key = s.toLowerCase().trim();
      if (key.length >= 3) {
        stemMap[key] = stemLevels[key] ?? MatLevel.warn;
      }
    }
    for (final e in stemLevels.entries) {
      final key = e.key.toLowerCase().trim();
      if (key.length >= 3) stemMap[key] = e.value;
    }
    final stemList = stemMap.entries
        .map((e) => (stem: e.key, level: e.value))
        .toList()
      ..sort((a, b) => b.stem.length.compareTo(a.stem.length));

    return MatLexicon._(
      Map<String, MatLevel>.unmodifiable(exact),
      List<({String stem, MatLevel level})>.unmodifiable(stemList),
    );
  }

  /// Backward-compatible: all entries are [MatLevel.warn].
  factory MatLexicon.fromTokens(Iterable<String> tokens) =>
      MatLexicon.fromParts(tokens: tokens);

  /// Exact token wins over stem prefix (e.g. blocked «блядь» vs warn stem «бля»).
  /// [normalizedToken] must already be lowercased (see [Normalizer]).
  MatLevel? lookup(String normalizedToken) {
    final exact = _exact[normalizedToken];
    if (exact != null) return exact;
    for (final entry in _stems) {
      if (normalizedToken.length >= entry.stem.length &&
          normalizedToken.startsWith(entry.stem)) {
        return entry.level;
      }
    }
    return null;
  }

  bool contains(String normalizedToken) => lookup(normalizedToken) != null;

  int get tokenCount => _exact.length;

  int get stemCount => _stems.length;

  int get size => tokenCount + stemCount;
}
