/// Profanity lexicon — O(1) exact tokens + prefix stems for morphology.
library;

/// Immutable mat lexicon with exact and stem-prefix matching.
final class MatLexicon {
  MatLexicon._(this._exact, this._stems);

  final Set<String> _exact;
  /// Longest stems first — early exit on first prefix hit.
  final List<String> _stems;

  /// [tokens] are matched exactly; [stems] match as prefixes (RU morphology).
  factory MatLexicon.fromParts({
    required Iterable<String> tokens,
    Iterable<String> stems = const [],
  }) {
    final exact = <String>{};
    for (final t in tokens) {
      final key = t.toLowerCase().trim();
      if (key.length >= 2) exact.add(key);
    }

    final stemList = <String>[];
    for (final s in stems) {
      final key = s.toLowerCase().trim();
      if (key.length >= 3) stemList.add(key);
    }
    stemList.sort((a, b) => b.length.compareTo(a.length));

    return MatLexicon._(
      Set<String>.unmodifiable(exact),
      List<String>.unmodifiable(stemList),
    );
  }

  /// Backward-compatible: all entries are exact tokens.
  factory MatLexicon.fromTokens(Iterable<String> tokens) =>
      MatLexicon.fromParts(tokens: tokens);

  bool contains(String normalizedToken) {
    if (_exact.contains(normalizedToken)) return true;
    for (final stem in _stems) {
      if (normalizedToken.length >= stem.length &&
          normalizedToken.startsWith(stem)) {
        return true;
      }
    }
    return false;
  }

  int get tokenCount => _exact.length;

  int get stemCount => _stems.length;

  int get size => tokenCount + stemCount;
}
