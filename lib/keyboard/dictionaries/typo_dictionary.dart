/// Dedicated typo → correction map — O(1) lookup, loaded once.
library;

/// Common typo corrections (missing letters, swaps, keyboard mistakes).
final class TypoDictionary {
  TypoDictionary._(this._corrections);

  final Map<String, String> _corrections;

  factory TypoDictionary.fromMap(Map<String, String> corrections) {
    final normalized = <String, String>{};
    for (final e in corrections.entries) {
      final from = e.key.toLowerCase().trim();
      final to = e.value.toLowerCase().trim();
      if (from.isEmpty || to.isEmpty) continue;
      normalized[from] = to;
    }
    return TypoDictionary._(Map<String, String>.unmodifiable(normalized));
  }

  factory TypoDictionary.empty() => TypoDictionary._(const {});

  /// Returns the correction when [word] is a known typo, else null.
  String? lookup(String word) => _corrections[word.toLowerCase()];

  bool contains(String word) => _corrections.containsKey(word.toLowerCase());

  int get size => _corrections.length;
}
