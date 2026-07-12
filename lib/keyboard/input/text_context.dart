/// Immutable snapshot of a completed word and its surrounding field text.
library;

/// Half-open range `[start, end)` in the target text field.
final class EditRange {
  const EditRange(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditRange && start == other.start && end == other.end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// Context emitted at word boundaries and consumed by engines.
final class TextContext {
  const TextContext({
    required this.word,
    required this.before,
    required this.after,
    required this.range,
    required this.locale,
    String? fullMessage,
    this.lexiconKey,
    this.boundary = '',
  }) : _fullMessage = fullMessage;

  /// The completed word as typed (trimmed, not normalized).
  final String word;

  /// Up to ~64 characters before [word].
  final String before;

  /// Up to ~16 characters after the cursor.
  final String after;

  /// Where [word] sits in the field.
  final EditRange range;

  /// Active language tag, e.g. `en` or `ru`.
  final String locale;

  /// Optional prebuilt `before + word + after` — prefer [fullMessage] getter.
  final String? _fullMessage;

  /// Precomputed [Normalizer.normalizeForLexicon] — set once in the pipeline.
  final String? lexiconKey;

  /// Boundary character that closed the word (space, `.`, `!`, `?`, …).
  final String boundary;

  /// `before + word + after` — allocated only when first needed.
  String get fullMessage => _fullMessage ?? '$before$word$after';

  /// Length without building [fullMessage] when override is absent.
  int get messageLength =>
      _fullMessage?.length ?? (before.length + word.length + after.length);

  TextContext copyWith({
    String? word,
    String? before,
    String? after,
    EditRange? range,
    String? locale,
    String? fullMessage,
    String? lexiconKey,
    String? boundary,
  }) {
    return TextContext(
      word: word ?? this.word,
      before: before ?? this.before,
      after: after ?? this.after,
      range: range ?? this.range,
      locale: locale ?? this.locale,
      fullMessage: fullMessage ?? _fullMessage,
      lexiconKey: lexiconKey ?? this.lexiconKey,
      boundary: boundary ?? this.boundary,
    );
  }
}
