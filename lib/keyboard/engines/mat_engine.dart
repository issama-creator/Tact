/// Profanity detection — local HashSet membership.
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

  @override
  List<RuleSignal> analyze(TextContext ctx) {
    final word = ctx.word;
    if (!shouldRunLexiconAnalysis(word)) return const [];
    if (TextSkip.shouldSkip(word)) return const [];

    final normalized = ctx.lexiconKey ?? _normalizer.normalizeForLexicon(word);
    if (normalized.length < 3) return const [];
    if (!_lexicon.contains(normalized)) return const [];

    return [
      RuleSignal(
        kind: SignalKind.mat,
        severity: 90,
        confidence: 0.95,
        range: ctx.range,
        payload: word,
      ),
    ];
  }
}
