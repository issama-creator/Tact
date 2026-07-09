/// Local spell detection for completed words.
library;

import '../dictionaries/dictionary.dart';
import '../input/word_length_policy.dart';
import '../dictionaries/typo_dictionary.dart';
import '../input/text_context.dart';
import '../rules/rule_signal.dart';
import 'normalizer.dart';
import 'signal_provider.dart';
import 'text_skip.dart';

final class SpellEngine implements SignalProvider {
  SpellEngine(
    this._dictionary, {
    TypoDictionary? typo,
    this.personalWords = const {},
    this.skipTokens = const {},
    Normalizer? normalizer,
  })  : _typo = typo ?? TypoDictionary.empty(),
        _normalizer = normalizer ?? Normalizer();

  final Dictionary _dictionary;
  final TypoDictionary _typo;
  final Set<String> personalWords;
  final Set<String> skipTokens;
  final Normalizer _normalizer;

  @override
  List<RuleSignal> analyze(TextContext ctx, {String? lowerWord}) {
    final word = ctx.word;
    if (!shouldRunLexiconAnalysis(word)) return const [];
    if (TextSkip.shouldSkip(word)) return const [];

    final lower = lowerWord ?? _lowerWord(word);
    final lexiconKey = ctx.lexiconKey ?? _normalizer.normalizeForLexicon(word);
    if (lexiconKey.isNotEmpty && skipTokens.contains(lexiconKey)) {
      return const [];
    }
    if (_dictionary.lookup(lower).known || personalWords.contains(lower)) {
      return const [];
    }

    final typoFix = _typo.lookup(lower);
    final candidates = typoFix != null
        ? [typoFix]
        : _dictionary.candidates(lower);
    if (candidates.isEmpty) return const [];

    return [
      RuleSignal(
        kind: SignalKind.spellError,
        severity: 80,
        confidence: 0.85,
        range: ctx.range,
        payload: SpellPayload(word: word, candidates: candidates),
      ),
    ];
  }

  static String _lowerWord(String word) {
    final buf = StringBuffer();
    for (var i = 0; i < word.length; i++) {
      final cu = word.codeUnitAt(i);
      if (cu >= 0x41 && cu <= 0x5A) {
        buf.writeCharCode(cu + 32);
      } else {
        buf.writeCharCode(cu);
      }
    }
    return buf.toString();
  }
}
