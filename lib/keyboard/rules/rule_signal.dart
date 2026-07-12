/// Normalized messages emitted by engines for the rules layer.
library;

import '../dictionaries/mat_lexicon.dart';
import '../dictionaries/toxic_category.dart';
import '../input/text_context.dart';

enum SignalKind {
  undo,
  mat,
  toxic,
  improve,
  aiAssist,
  shortcutMatch,
  nextWord,
}

/// Toxic severity tiers — no sentiment analysis, dictionary scoring only.
enum ToxicLevel {
  safe,
  warning,
  conflict,
}

final class ToxicPayload {
  const ToxicPayload({
    required this.word,
    required this.level,
    required this.score,
    this.category,
  });

  final String word;
  final ToxicLevel level;
  final int score;
  final ToxicCategory? category;
}

final class ShortcutPayload {
  const ShortcutPayload({
    required this.trigger,
    required this.expansions,
  });

  final String trigger;
  final List<String> expansions;
}

/// Mat detection payload — [level] drives auto-block vs panel warn.
final class MatPayload {
  const MatPayload({
    required this.word,
    required this.level,
  });

  final String word;
  final MatLevel level;
}

final class RuleSignal {
  const RuleSignal({
    required this.kind,
    required this.severity,
    required this.confidence,
    required this.range,
    this.payload,
  });

  final SignalKind kind;
  final int severity;
  final double confidence;
  final EditRange range;
  final Object? payload;
}
