/// Toxic language scoring — dictionary-based, no sentiment analysis.
library;

import '../input/word_length_policy.dart';
import '../dictionaries/toxic_category.dart';
import '../input/text_context.dart';
import '../rules/rule_signal.dart';
import 'normalizer.dart';
import 'signal_provider.dart';
import 'text_skip.dart';

final class ToxicEngine implements SignalProvider {
  ToxicEngine(this._lexicon, this._normalizer);

  final ToxicLexicon _lexicon;
  final Normalizer _normalizer;

  @override
  List<RuleSignal> analyze(TextContext ctx) {
    final word = ctx.word;
    if (!shouldRunLexiconAnalysis(word)) return const [];
    if (TextSkip.shouldSkip(word)) return const [];

    final normalized = _normalizer.normalizeForLexicon(word);
    if (normalized.length < 3) return const [];

    final entry = _lexicon.lookup(normalized);
    if (entry == null) return const [];

    final level = _levelFor(
      entry.score,
      warning: _lexicon.warningAt,
      conflict: _lexicon.conflictAt,
    );
    if (level == ToxicLevel.safe) return const [];

    return [
      RuleSignal(
        kind: SignalKind.toxic,
        severity: entry.score,
        confidence: entry.score / 100.0,
        range: ctx.range,
        payload: ToxicPayload(
          word: word,
          level: level,
          score: entry.score,
          category: entry.category,
        ),
      ),
    ];
  }

  static ToxicLevel _levelFor(
    int score, {
    required int warning,
    required int conflict,
  }) {
    if (score >= conflict) return ToxicLevel.conflict;
    if (score >= warning) return ToxicLevel.warning;
    return ToxicLevel.safe;
  }
}
