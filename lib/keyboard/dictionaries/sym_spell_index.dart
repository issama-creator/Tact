/// SymSpell delete-index — O(1) candidate lookup, scales past 5k words.
library;

import 'keyboard_proximity.dart';

/// Pre-built SymSpell index for one locale dictionary.
final class SymSpellIndex {
  SymSpellIndex({
    required Iterable<String> words,
    Map<String, int> frequency = const {},
    this.maxEditDistance = 2,
    this.locale = 'en',
  })  : _words = Set<String>.unmodifiable(
          words.map((w) => w.toLowerCase()).where((w) => w.isNotEmpty),
        ),
        _freq = _buildFreq(words, frequency) {
    _buildDeleteIndex();
  }

  final Set<String> _words;
  final Map<String, int> _freq;
  final int maxEditDistance;
  final String locale;

  /// delete-fragment → dictionary words reachable within [maxEditDistance].
  final Map<String, Set<String>> _deleteIndex = {};

  static Map<String, int> _buildFreq(
    Iterable<String> words,
    Map<String, int> frequency,
  ) {
    final out = <String, int>{};
    for (final w in words) {
      final key = w.toLowerCase();
      out[key] = frequency[key] ?? 1;
    }
    return out;
  }

  void _buildDeleteIndex() {
    for (final word in _words) {
      _addToIndex(word, word);
      _generateDeletes(word, maxEditDistance).forEach((del) {
        _addToIndex(del, word);
      });
    }
  }

  void _addToIndex(String key, String word) {
    final set = _deleteIndex.putIfAbsent(key, () => <String>{});
    set.add(word);
  }

  Set<String> _generateDeletes(String word, int distance) {
    final results = <String>{};
    void recurse(String w, int d) {
      if (d == 0) return;
      for (var i = 0; i < w.length; i++) {
        final del = w.substring(0, i) + w.substring(i + 1);
        if (del.isEmpty || !results.add(del)) continue;
        recurse(del, d - 1);
      }
    }

    recurse(word, distance);
    return results;
  }

  /// Ranked spell suggestions — empty when [input] is already known.
  List<String> suggest(String input, {int max = 5}) {
    final key = input.toLowerCase();
    if (_words.contains(key)) return const [];

    final effectiveMax = key.length > 8 ? 1 : maxEditDistance;
    final candidates = <String, _CandidateScore>{};

    void consider(String word, int distance) {
      if (!_words.contains(word)) return;
      final actual = _editDistanceAtMost(key, word, effectiveMax);
      if (actual < 0) return;
      final kb = KeyboardProximity.neighborBonus(key, word, locale);
      final score = _CandidateScore(
        distance: actual,
        frequency: _freq[word] ?? 1,
        lengthDelta: (word.length - key.length).abs(),
        keyboardBonus: kb,
      );
      final prev = candidates[word];
      if (prev == null || score.compareRank(prev) > 0) {
        candidates[word] = score;
      }
    }

    if (_deleteIndex.containsKey(key)) {
      for (final w in _deleteIndex[key]!) {
        consider(w, 0);
      }
    }

    var frontier = <String>{key};
    for (var d = 1; d <= effectiveMax; d++) {
      final next = <String>{};
      for (final fragment in frontier) {
        final bucket = _deleteIndex[fragment];
        if (bucket != null) {
          for (final w in bucket) {
            consider(w, d);
          }
        }
        for (var i = 0; i < fragment.length; i++) {
          final del = fragment.substring(0, i) + fragment.substring(i + 1);
          if (del.isNotEmpty) next.add(del);
        }
      }
      frontier = next;
      if (candidates.length >= max * 3) break;
    }

    if (candidates.isEmpty) {
      _proximitySubstituteRescue(key, candidates, effectiveMax);
    }

    if (candidates.isEmpty) return const [];

    final ranked = candidates.entries.toList()
      ..sort((a, b) => b.value.compareRank(a.value));

    return List<String>.unmodifiable(
      ranked.take(max).map((e) => e.key),
    );
  }

  /// One keyboard-neighbor substitution when delete-index finds nothing.
  void _proximitySubstituteRescue(
    String key,
    Map<String, _CandidateScore> out,
    int maxDist,
  ) {
    if (maxDist < 1) return;
    final chars = key.split('');
    for (var i = 0; i < chars.length; i++) {
      for (final c in KeyboardProximity.neighbors(chars[i], locale: locale)) {
        if (c == chars[i]) continue;
        final trial = chars.sublist(0, i).join() + c + chars.sublist(i + 1).join();
        if (!_words.contains(trial)) continue;
        final dist = _editDistanceAtMost(key, trial, 1);
        if (dist < 0) continue;
        out[trial] = _CandidateScore(
          distance: dist,
          frequency: _freq[trial] ?? 1,
          lengthDelta: 0,
          keyboardBonus: KeyboardProximity.neighborBonus(key, trial, locale),
        );
      }
    }
  }

  /// Returns edit distance if <= [max], else -1.
  static int _editDistanceAtMost(String a, String b, int max) {
    if (a == b) return 0;
    if ((a.length - b.length).abs() > max) return -1;

    final m = a.length;
    final n = b.length;
    var prev = List<int>.generate(n + 1, (j) => j);
    for (var i = 1; i <= m; i++) {
      final cur = List<int>.filled(n + 1, 0);
      cur[0] = i;
      var rowMin = cur[0];
      for (var j = 1; j <= n; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        cur[j] = _min3(
          prev[j] + 1,
          cur[j - 1] + 1,
          prev[j - 1] + cost,
        );
        if (cur[j] < rowMin) rowMin = cur[j];
      }
      if (rowMin > max) return -1;
      prev = cur;
    }
    final d = prev[n];
    return d <= max ? d : -1;
  }

  static int _min3(int a, int b, int c) {
    if (a <= b && a <= c) return a;
    if (b <= a && b <= c) return b;
    return c;
  }
}

final class _CandidateScore {
  const _CandidateScore({
    required this.distance,
    required this.frequency,
    required this.lengthDelta,
    required this.keyboardBonus,
  });

  final int distance;
  final int frequency;
  final int lengthDelta;
  final int keyboardBonus;

  int compareRank(_CandidateScore other) {
    if (distance != other.distance) {
      return other.distance.compareTo(distance);
    }
    if (frequency != other.frequency) {
      return frequency.compareTo(other.frequency);
    }
    if (keyboardBonus != other.keyboardBonus) {
      return keyboardBonus.compareTo(other.keyboardBonus);
    }
    if (lengthDelta != other.lengthDelta) {
      return other.lengthDelta.compareTo(lengthDelta);
    }
    return 0;
  }
}
