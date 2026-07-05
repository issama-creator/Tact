/// Dictionary facade — O(1) membership and bounded spell correction.
library;

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
  Dictionary._(this._words, this._next);

  final Set<String> _words;
  final Map<String, List<String>> _next;

  factory Dictionary.fromWords(
    Iterable<String> words, {
    Map<String, List<String>> nextWords = const {},
  }) {
    return Dictionary._(
      Set<String>.unmodifiable(words.map((w) => w.toLowerCase())),
      Map<String, List<String>>.unmodifiable(
        nextWords.map(
          (k, v) => MapEntry(k.toLowerCase(), List<String>.unmodifiable(v)),
        ),
      ),
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

  /// Bounded-edit spell candidates — checks generated neighbors only.
  List<String> candidates(
    String word, {
    int maxEdits = 2,
    int max = 5,
  }) {
    final key = word.toLowerCase();
    if (_words.contains(key)) return const [];

    final found = <String>{};
    var frontier = <String>{key};

    for (var d = 1; d <= maxEdits; d++) {
      final nextFrontier = <String>{};
      for (final token in frontier) {
        for (final edit in _edits1(token)) {
          if (_words.contains(edit)) found.add(edit);
          if (d < maxEdits) nextFrontier.add(edit);
        }
      }
      frontier = nextFrontier;
      if (found.length >= max) break;
    }

    final list = found.toList()..sort();
    if (list.length <= max) return List<String>.unmodifiable(list);
    return List<String>.unmodifiable(list.sublist(0, max));
  }

  Iterable<String> _edits1(String word) sync* {
    final chars = word.split('');

    for (var i = 0; i < chars.length; i++) {
      yield chars.sublist(0, i).join() + chars.sublist(i + 1).join();
    }

    for (var i = 0; i < chars.length - 1; i++) {
      final copy = List<String>.from(chars);
      final tmp = copy[i];
      copy[i] = copy[i + 1];
      copy[i + 1] = tmp;
      yield copy.join();
    }

    for (var i = 0; i < chars.length; i++) {
      for (final c in _alphabet(chars[i])) {
        if (c == chars[i]) continue;
        yield chars.sublist(0, i).join() + c + chars.sublist(i + 1).join();
      }
    }

    for (var i = 0; i <= chars.length; i++) {
      for (final c in _alphabet(null)) {
        yield chars.sublist(0, i).join() + c + chars.sublist(i).join();
      }
    }
  }

  Iterable<String> _alphabet(String? ch) sync* {
    if (ch != null && ch.isNotEmpty) {
      final code = ch.codeUnitAt(0);
      if (code >= 0x61 && code <= 0x7A) {
        if (code > 0x61) yield String.fromCharCode(code - 1);
        if (code < 0x7A) yield String.fromCharCode(code + 1);
        yield ch;
        return;
      }
      if (code >= 0x0430 && code <= 0x044F) {
        if (code > 0x0430) yield String.fromCharCode(code - 1);
        if (code < 0x044F) yield String.fromCharCode(code + 1);
        yield ch;
        return;
      }
    }
    for (var c = 0x61; c <= 0x7A; c++) {
      yield String.fromCharCode(c);
    }
  }

  int get size => _words.length;

  /// Number of tokens with next-word suggestions.
  int get nextWordKeyCount => _next.length;
}
