/// Single-pass analysis at word boundary (space / punctuation).
library;

import '../dictionaries/dictionary.dart';
import '../dictionaries/dictionary_manager.dart';
import '../dictionaries/locale_bundle.dart';
import '../dictionaries/toxic_category.dart';
import '../engines/normalizer.dart';
import '../engines/shortcut_table.dart';
import '../engines/text_skip.dart';
import '../input/text_context.dart';
import '../input/word_length_policy.dart';
import '../rules/rule_signal.dart';

/// Output of one [WordBoundaryAnalyzer.analyzeAtBoundary] call.
final class WordBoundaryResult {
  const WordBoundaryResult({
    required this.normalized,
    required this.lookup,
    required this.signals,
  });

  final String normalized;
  final DictionaryLookup lookup;
  final List<RuleSignal> signals;
}

/// Runs spell, mat, toxic, shortcut, and improve checks in a single pass.
final class WordBoundaryAnalyzer {
  WordBoundaryAnalyzer({
    required DictionaryManager manager,
    Normalizer? normalizer,
    ShortcutTable? shortcuts,
    this.personalWords = const {},
    this.improveMinChars = 30,
  })  : _manager = manager,
        _normalizer = normalizer ?? Normalizer(),
        _shortcuts = shortcuts ??
            ShortcutTable(builtin: manager.builtinShortcuts);

  final DictionaryManager _manager;
  final Normalizer _normalizer;
  ShortcutTable _shortcuts;
  final Set<String> personalWords;
  final int improveMinChars;

  void setShortcuts(ShortcutTable table) => _shortcuts = table;

  /// All word-boundary checks in one function — called on space / punctuation.
  WordBoundaryResult analyzeAtBoundary(TextContext ctx, String localeKey) {
    final word = ctx.word;
    final bundle = _manager.bundleFor(localeKey);
    final runLexicon = shouldRunLexiconAnalysis(word);
    final normalized = _normalizer.normalize(word);
    final lookup = bundle.spell.lookup(normalized);
    final lexiconKey =
        runLexicon ? _normalizer.normalizeForLexicon(word) : '';
    final skipLexicon = !runLexicon || TextSkip.shouldSkip(word);

    final signals = <RuleSignal>[];

    if (!skipLexicon && lexiconKey.isNotEmpty) {
      _checkSpell(
        signals: signals,
        word: word,
        normalized: normalized,
        lexiconKey: lexiconKey,
        range: ctx.range,
        bundle: bundle,
        known: lookup.known,
      );
      _checkMat(
        signals: signals,
        word: word,
        lexiconKey: lexiconKey,
        range: ctx.range,
        bundle: bundle,
      );
      _checkToxic(
        signals: signals,
        word: word,
        lexiconKey: lexiconKey,
        range: ctx.range,
        bundle: bundle,
      );
      _checkImprove(signals: signals, ctx: ctx);
    }

    _checkShortcut(signals: signals, word: word, range: ctx.range);

    return WordBoundaryResult(
      normalized: normalized,
      lookup: lookup,
      signals: signals,
    );
  }

  /// Live shortcut chips while typing (before space).
  List<RuleSignal> analyzeShortcutOnly(TextContext ctx) {
    final signals = <RuleSignal>[];
    _checkShortcut(signals: signals, word: ctx.word, range: ctx.range);
    return signals;
  }

  void _checkSpell({
    required List<RuleSignal> signals,
    required String word,
    required String normalized,
    required String lexiconKey,
    required EditRange range,
    required LocaleBundle bundle,
    required bool known,
  }) {
    if (bundle.mat.contains(lexiconKey)) return;
    if (known) return;
    if (personalWords.contains(normalized)) return;

    final typoFix = bundle.typo.lookup(normalized);
    final candidates =
        typoFix != null ? [typoFix] : bundle.spell.candidates(normalized);
    if (candidates.isEmpty) return;

    signals.add(
      RuleSignal(
        kind: SignalKind.spellError,
        severity: 80,
        confidence: 0.85,
        range: range,
        payload: SpellPayload(word: word, candidates: candidates),
      ),
    );
  }

  void _checkMat({
    required List<RuleSignal> signals,
    required String word,
    required String lexiconKey,
    required EditRange range,
    required LocaleBundle bundle,
  }) {
    if (lexiconKey.length < kMinLexiconWordLength) return;
    if (!bundle.mat.contains(lexiconKey)) return;

    signals.add(
      RuleSignal(
        kind: SignalKind.mat,
        severity: 90,
        confidence: 0.95,
        range: range,
        payload: word,
      ),
    );
  }

  void _checkToxic({
    required List<RuleSignal> signals,
    required String word,
    required String lexiconKey,
    required EditRange range,
    required LocaleBundle bundle,
  }) {
    if (lexiconKey.length < kMinLexiconWordLength) return;

    final entry = bundle.toxic.lookup(lexiconKey);
    if (entry == null) return;

    final level = _toxicLevel(
      entry.score,
      warning: bundle.toxic.warningAt,
      conflict: bundle.toxic.conflictAt,
    );
    if (level == ToxicLevel.safe) return;

    signals.add(
      RuleSignal(
        kind: SignalKind.toxic,
        severity: entry.score,
        confidence: entry.score / 100.0,
        range: range,
        payload: ToxicPayload(
          word: word,
          level: level,
          score: entry.score,
          category: entry.category,
        ),
      ),
    );
  }

  void _checkImprove({
    required List<RuleSignal> signals,
    required TextContext ctx,
  }) {
    if (ctx.fullMessage.length < improveMinChars) return;

    signals.add(
      RuleSignal(
        kind: SignalKind.improve,
        severity: 40,
        confidence: 0.6,
        range: ctx.range,
      ),
    );
  }

  void _checkShortcut({
    required List<RuleSignal> signals,
    required String word,
    required EditRange range,
  }) {
    if (word.length < kMinShortcutTriggerLength) return;

    final match = _shortcuts.lookup(word);
    if (match == null) return;

    signals.add(
      RuleSignal(
        kind: SignalKind.shortcutMatch,
        severity: 70,
        confidence: 1.0,
        range: range,
        payload: ShortcutPayload(
          trigger: match.trigger,
          expansions: match.expansions,
        ),
      ),
    );
  }

  static ToxicLevel _toxicLevel(
    int score, {
    required int warning,
    required int conflict,
  }) {
    if (score >= conflict) return ToxicLevel.conflict;
    if (score >= warning) return ToxicLevel.warning;
    return ToxicLevel.safe;
  }
}
