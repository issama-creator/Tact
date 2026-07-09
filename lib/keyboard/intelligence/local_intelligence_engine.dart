/// Local Intelligence Engine — full offline pipeline for completed words.
library;

import '../dictionaries/dictionary.dart';
import '../dictionaries/dictionary_manager.dart';
import '../../core/keyboard_settings/keyboard_settings.dart';
import '../engines/shortcut_table.dart';
import '../input/word_length_policy.dart';
import '../input/text_context.dart';
import '../panel/panel_state.dart';
import '../rules/rule_signal.dart';
import '../rules/rules_engine.dart';
import 'undo_tracker.dart';
import 'word_boundary_analyzer.dart';

/// Immutable bundle produced by one pipeline pass.
final class IntelligenceResult {
  const IntelligenceResult({
    required this.normalized,
    required this.dictionary,
    required this.signals,
    required this.decision,
  });

  final String normalized;
  final DictionaryLookup dictionary;
  final List<RuleSignal> signals;
  final PanelDecision decision;
}

/// Heart of TACT — processes every completed word synchronously.
final class LocalIntelligenceEngine {
  LocalIntelligenceEngine({
    ShortcutTable? shortcuts,
    RulesEngine? rules,
    UndoTracker? undo,
    Set<String>? personalWords,
    WordBoundaryAnalyzer? analyzer,
  })  : _rules = rules ?? const RulesEngine(),
        _undo = undo ?? UndoTracker(),
        _analyzer = analyzer ??
            WordBoundaryAnalyzer(
              shortcuts: shortcuts,
              personalWords: personalWords ?? const {},
            ) {
    _loadedSource = DictionaryManager.shared.source;
  }

  final RulesEngine _rules;
  final UndoTracker _undo;
  final WordBoundaryAnalyzer _analyzer;
  String? _loadedSource;

  UndoTracker get undo => _undo;

  String _localeKey(String locale) {
    final lower = locale.toLowerCase();
    if (lower.startsWith('ru')) return 'ru';
    return 'en';
  }

  /// Runs the full pipeline for one completed word (space / punctuation).
  IntelligenceResult process(TextContext ctx, {int? nowMs}) {
    final clock = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final locale = _localeKey(ctx.locale);

    final checked = _analyzer.analyzeAtBoundary(ctx, locale);

    final suggestions = shouldRunLexiconAnalysis(ctx.word) && checked.lookup.known
        ? checked.lookup.nextWords
        : const <String>[];

    final decision = _rules.evaluate(
      signals: checked.signals,
      undoAvailable: _undo.available,
      defaultSuggestions: suggestions,
      nowMs: clock,
      messageLength: ctx.fullMessage.length,
    );

    return IntelligenceResult(
      normalized: checked.normalized,
      dictionary: checked.lookup,
      signals: checked.signals,
      decision: decision,
    );
  }

  /// Live shortcut chips while typing (before space).
  IntelligenceResult processShortcutOnly(TextContext ctx, {int? nowMs}) {
    final clock = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final signals = _analyzer.analyzeShortcutOnly(ctx);
    final decision = _rules.evaluate(
      signals: signals,
      undoAvailable: false,
      defaultSuggestions: const [],
      nowMs: clock,
      messageLength: ctx.fullMessage.length,
    );
    return IntelligenceResult(
      normalized: ctx.word,
      dictionary: const DictionaryLookup(known: false, nextWords: []),
      signals: signals,
      decision: decision,
    );
  }

  void setUserShortcuts(Iterable<TextShortcut> shortcuts) {
    _analyzer.setShortcuts(
      ShortcutTable(
        builtin: defaultBuiltinShortcuts,
        user: shortcuts,
      ),
    );
  }

  void setPersonalWords(Set<String> words) => _analyzer.setPersonalWords(words);

  void setAntiMatEnabled(bool enabled) => _analyzer.setAntiMatEnabled(enabled);

  bool get antiMatEnabled => _analyzer.antiMatEnabled;

  void applySettings(KeyboardSettings settings) {
    _analyzer.setAntiMatEnabled(settings.antiMat);
    _analyzer.setAntiToxicEnabled(settings.antiToxic);
    _analyzer.setSpellEnabled(settings.errorCorrection);
    _analyzer.setImproveEnabled(settings.textImprovement);
    _analyzer.setFillerWordsEnabled(settings.fillerWords);
  }

  /// Refreshes when [DictionaryManager.open] loads new assets.
  void reloadDictionaries() {
    final source = DictionaryManager.shared.source;
    if (_loadedSource == source) return;
    _loadedSource = source;
  }
}
