/// Profanity detection — local HashSet membership with block/warn levels.
library;

import '../dictionaries/mat_lexicon.dart';
import '../input/word_length_policy.dart';
import '../input/text_context.dart';
import '../rules/rule_signal.dart';
import 'normalizer.dart';
import 'signal_provider.dart';
import 'text_skip.dart';

final class MatEngine implements SignalProvider {
  MatEngine(this._lexicon, this._normalizer);

  final MatLexicon _lexicon;
  final Normalizer _normalizer;

  bool antiMatEnabled = true;

  @override
  List<RuleSignal> analyze(TextContext ctx) {
    if (!antiMatEnabled) return const [];
    final word = ctx.word;
    if (!shouldRunLexiconAnalysis(word)) return const [];
    if (TextSkip.shouldSkip(word)) return const [];

    final normalized = ctx.lexiconKey ?? _normalizer.normalizeForLexicon(word);
    if (normalized.length < 3) return const [];
    final level = _lexicon.lookup(normalized);
    if (level == null) return const [];

    return [
      RuleSignal(
        kind: SignalKind.mat,
        severity: level == MatLevel.block ? 100 : 90,
        confidence: 0.95,
        range: ctx.range,
        payload: MatPayload(word: word, level: level),
      ),
    ];
  }
}
