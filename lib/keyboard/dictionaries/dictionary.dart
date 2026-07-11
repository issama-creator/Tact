/// Dictionary facade — O(1) membership, prefix autocomplete, lazy SymSpell.
library;

import 'sym_spell_index.dart';

/// Result of a dictionary lookup for one normalized token.
final class DictionaryLookup {
  const DictionaryLookup({
    required this.known,
    required this.nextWords,
  });

  final bool known;
  final List<String> nextWords;
}

/// Immutable per-language word data loaded once at startup.
final class Dictionary {
  Dictionary._(
    this._words,
    this._sorted,
    this._next,
    this._frequency,
    this._locale,
  );

  final Set<String> _words;
  /// Lexicographically sorted — binary-search prefix completions (10k-ready).
  final List<String> _sorted;
  final Map<String, List<String>> _next;
  final Map<String, int> _frequency;
  final String _locale;

  /// Built only if [candidates] is called (spell path unused on typing hot path).
  SymSpellIndex? _symSpell;

  factory Dictionary.fromWords(
    Iterable<String> words, {
    Map<String, List<String>> nextWords = const {},
    Map<String, int> frequency = const {},
    String locale = 'en',
  }) {
    final normalized =
        words.map((w) => w.toLowerCase()).where((w) => w.isNotEmpty);
    final wordSet = Set<String>.from(normalized);
    final freq = <String, int>{};
    for (final w in wordSet) {
      freq[w] = frequency[w] ?? 1;
    }
    for (final e in frequency.entries) {
      final key = e.key.toLowerCase();
      if (wordSet.contains(key)) freq[key] = e.value;
    }

    final sorted = wordSet.toList(growable: false)..sort();

    return Dictionary._(
      Set<String>.unmodifiable(wordSet),
      sorted,
      Map<String, List<String>>.unmodifiable(
        nextWords.map(
          (k, v) => MapEntry(k.toLowerCase(), List<String>.unmodifiable(v)),
        ),
      ),
      Map<String, int>.unmodifiable(freq),
      locale,
    );
  }

  /// [normalizedWord] must already be lowercased (see [Normalizer]).
  bool contains(String normalizedWord) => _words.contains(normalizedWord);

  /// [normalizedWord] must already be lowercased (see [Normalizer]).
  DictionaryLookup lookup(String normalizedWord) {
    return DictionaryLookup(
      known: _words.contains(normalizedWord),
      nextWords: _next[normalizedWord] ?? const [],
    );
  }

  /// Gboard-style completions for a typed prefix — O(log n + k), max [max] hits.
  ///
  /// [normalizedPrefix] must already be lowercased. Skips the exact prefix
  /// itself (already typed); ranks by frequency, then shorter length.
  List<String> prefixCompletions(
    String normalizedPrefix, {
    int max = 3,
  }) {
    if (max <= 0) return const [];
    final prefix = normalizedPrefix;
    if (prefix.length < 2 || prefix.length > 32) return const [];

    final start = _lowerBound(prefix);
    if (start >= _sorted.length) return const [];

    // Cap scan so ultra-common prefixes ("th", "по") stay cheap at 10k+.
    const scanCap = 48;
    final scored = <_PrefixHit>[];
    for (var i = start; i < _sorted.length && scored.length < scanCap; i++) {
      final w = _sorted[i];
      if (!w.startsWith(prefix)) break;
      if (w.length == prefix.length) continue;
      scored.add(_PrefixHit(w, _frequency[w] ?? 1));
    }
    if (scored.isEmpty) return const [];

    scored.sort((a, b) {
      final byFreq = b.frequency.compareTo(a.frequency);
      if (byFreq != 0) return byFreq;
      final byLen = a.word.length.compareTo(b.word.length);
      if (byLen != 0) return byLen;
      return a.word.compareTo(b.word);
    });

    final n = scored.length < max ? scored.length : max;
    return List<String>.generate(n, (i) => scored[i].word, growable: false);
  }

  int _lowerBound(String prefix) {
    var lo = 0;
    var hi = _sorted.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_sorted[mid].compareTo(prefix) < 0) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// SymSpell candidates. [normalizedWord] must already be lowercased.
  List<String> candidates(
    String normalizedWord, {
    int maxEdits = 2,
    int max = 5,
  }) {
    if (_words.contains(normalizedWord)) return const [];
    if (normalizedWord.length > 24 || normalizedWord.length < 2) {
      return const [];
    }

    return _ensureSymSpell().suggest(
      normalizedWord,
      max: max,
    );
  }

  SymSpellIndex _ensureSymSpell() =>
      _symSpell ??= SymSpellIndex(
        words: _words,
        frequency: _frequency,
        locale: _locale,
      );

  int frequencyOf(String normalizedWord) =>
      _frequency[normalizedWord] ?? 0;

  int get size => _words.length;

  int get nextWordKeyCount => _next.length;
}

final class _PrefixHit {
  const _PrefixHit(this.word, this.frequency);
  final String word;
  final int frequency;
}
