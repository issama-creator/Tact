/// Multi-word phrase spell corrections — "как дла" → "как дела".
library;

/// Immutable phrase typo map loaded from [phrases_spell.json].
final class PhraseSpellLexicon {
  PhraseSpellLexicon._(this._corrections, this._valid);

  final Map<String, String> _corrections;
  final Set<String> _valid;

  factory PhraseSpellLexicon.fromMap({
    Map<String, String> corrections = const {},
    Iterable<String> valid = const [],
  }) {
    final fixed = <String, String>{};
    for (final e in corrections.entries) {
      final key = _normalizeKey(e.key);
      final val = e.value.trim().toLowerCase();
      if (key.length >= 3 && val.isNotEmpty) {
        fixed[key] = val;
      }
    }
    final known = <String>{
      for (final v in valid) _normalizeKey(v),
      ...fixed.values,
    }..remove('');
    return PhraseSpellLexicon._(
      Map<String, String>.unmodifiable(fixed),
      Set<String>.unmodifiable(known),
    );
  }

  factory PhraseSpellLexicon.empty() =>
      PhraseSpellLexicon.fromMap();

  /// Looks up a normalized multi-word phrase (up to 4 tokens).
  String? lookup(String normalizedPhrase) {
    final key = _normalizeKey(normalizedPhrase);
    if (key.isEmpty) return null;
    if (_valid.contains(key)) return null;
    return _corrections[key];
  }

  /// Scans trailing [windowWords] of a message for a phrase correction.
  String? lookupTrailing(String normalizedMessage, {int windowWords = 4}) {
    if (normalizedMessage.isEmpty || _corrections.isEmpty) return null;
    final tokens = normalizedMessage
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return null;

    final start = tokens.length > windowWords ? tokens.length - windowWords : 0;
    for (var len = windowWords; len >= 2; len--) {
      for (var i = start; i + len <= tokens.length; i++) {
        final phrase = tokens.sublist(i, i + len).join(' ');
        final fix = lookup(phrase);
        if (fix != null) return fix;
      }
    }
    return null;
  }

  int get size => _corrections.length;

  static String _normalizeKey(String input) =>
      input.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
}
