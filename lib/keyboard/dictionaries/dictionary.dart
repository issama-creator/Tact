/// Dictionary facade — O(1) membership and SymSpell correction.
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
    this._next,
    this._symSpell,
    this._frequency,
  );

  final Set<String> _words;
  final Map<String, List<String>> _next;
  final SymSpellIndex _symSpell;
  final Map<String, int> _frequency;

  factory Dictionary.fromWords(
    Iterable<String> words, {
    Map<String, List<String>> nextWords = const {},
    Map<String, int> frequency = const {},
    String locale = 'en',
  }) {
    final normalized = words.map((w) => w.toLowerCase()).where((w) => w.isNotEmpty);
    final wordSet = Set<String>.from(normalized);
    final freq = <String, int>{};
    for (final w in wordSet) {
      freq[w] = frequency[w] ?? 1;
    }
    for (final e in frequency.entries) {
      final key = e.key.toLowerCase();
      if (wordSet.contains(key)) freq[key] = e.value;
    }

    return Dictionary._(
      Set<String>.unmodifiable(wordSet),
      Map<String, List<String>>.unmodifiable(
        nextWords.map(
          (k, v) => MapEntry(k.toLowerCase(), List<String>.unmodifiable(v)),
        ),
      ),
      SymSpellIndex(words: wordSet, frequency: freq, locale: locale),
      Map<String, int>.unmodifiable(freq),
    );
  }

  bool contains(String word) => _words.contains(word.toLowerCase());

  DictionaryLookup lookup(String normalizedWord) {
    final key = normalizedWord.toLowerCase();
    return DictionaryLookup(
      known: _words.contains(key),
      nextWords: _next[key] ?? const [],
    );
  }

  /// SymSpell + frequency + keyboard-proximity ranked candidates.
  List<String> candidates(
    String word, {
    int maxEdits = 2,
    int max = 5,
  }) {
    final key = word.toLowerCase();
    if (_words.contains(key)) return const [];

    return _symSpell.suggest(
      key,
      max: max,
    );
  }

  int frequencyOf(String word) => _frequency[word.toLowerCase()] ?? 0;

  int get size => _words.length;

  int get nextWordKeyCount => _next.length;
}
