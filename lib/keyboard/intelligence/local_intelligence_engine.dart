/// Local Intelligence Engine — full offline pipeline for completed words.
library;

import '../dictionaries/dictionary.dart';
import '../dictionaries/dictionary_loader.dart';
import '../dictionaries/dictionary_manager.dart';
import '../engines/improve_engine.dart';
import '../engines/mat_engine.dart';
import '../engines/normalizer.dart';
import '../engines/shortcut_engine.dart';
import '../engines/shortcut_table.dart';
import '../engines/spell_engine.dart';
import '../engines/toxic_engine.dart';
import '../input/text_context.dart';
import '../input/word_length_policy.dart';
import '../panel/panel_state.dart';
import '../rules/rule_signal.dart';
import '../rules/rules_engine.dart';
import 'undo_tracker.dart';

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
    DictionaryManager? dictionaryManager,
    DictionaryLoader? dictionaryLoader,
    Normalizer? normalizer,
    ShortcutTable? shortcuts,
    RulesEngine? rules,
    UndoTracker? undo,
    Set<String>? personalWords,
  })  : _manager = dictionaryManager ?? DictionaryManager.shared,
        _dictionaries = dictionaryLoader ?? DictionaryLoader(dictionaryManager),
        _normalizer = normalizer ?? Normalizer(),
        _shortcuts = shortcuts ??
            ShortcutTable(
              builtin: DictionaryManager.shared.builtinShortcuts,
            ),
        _rules = rules ?? const RulesEngine(),
        _undo = undo ?? UndoTracker(),
        _personalWords = personalWords ?? const {} {
    _preload('en');
    _preload('ru');
    _shortcut = ShortcutEngine(_shortcuts);
  }

  final DictionaryManager _manager;

  final DictionaryLoader _dictionaries;
  final Normalizer _normalizer;
  ShortcutTable _shortcuts;
  final RulesEngine _rules;
  final UndoTracker _undo;
  final Set<String> _personalWords;

  final Map<String, SpellEngine> _spellByLocale = {};
  final Map<String, MatEngine> _matByLocale = {};
  final Map<String, ToxicEngine> _toxicByLocale = {};
  final ImproveEngine _improve = ImproveEngine();
  late ShortcutEngine _shortcut;

  UndoTracker get undo => _undo;

  void _preload(String locale) {
    final bundle = _manager.bundleFor(locale);
    final dict = bundle.spell;
    final matTokens = bundle.mat;
    _spellByLocale[locale] = SpellEngine(
      dict,
      typo: bundle.typo,
      personalWords: _personalWords,
      skipTokens: matTokens,
      normalizer: _normalizer,
    );
    _matByLocale[locale] = MatEngine(matTokens, _normalizer);
    _toxicByLocale[locale] = ToxicEngine(bundle.toxic, _normalizer);
  }

  String _localeKey(String locale) {
    final lower = locale.toLowerCase();
    if (lower.startsWith('ru')) return 'ru';
    return 'en';
  }

  /// Runs the full pipeline for one completed word.
  IntelligenceResult process(TextContext ctx, {int? nowMs}) {
    final clock = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final locale = _localeKey(ctx.locale);

    final runLexicon = shouldRunLexiconAnalysis(ctx.word);
    final normalized = _normalizer.normalize(ctx.word);
    final dict = _dictionaries.forLocale(locale);
    final lookup = dict.lookup(normalized);

    final spell = _spellByLocale[locale]!;
    final mat = _matByLocale[locale]!;
    final toxic = _toxicByLocale[locale]!;

    final signals = <RuleSignal>[
      if (runLexicon) ...spell.analyze(ctx),
      if (runLexicon) ...mat.analyze(ctx),
      if (runLexicon) ...toxic.analyze(ctx),
      ..._shortcut.analyze(ctx),
      if (runLexicon) ..._improve.analyze(ctx),
    ];

    final suggestions =
        runLexicon && lookup.known ? lookup.nextWords : const <String>[];

    final decision = _rules.evaluate(
      signals: signals,
      undoAvailable: _undo.available,
      defaultSuggestions: suggestions,
      nowMs: clock,
      messageLength: ctx.fullMessage.length,
    );

    return IntelligenceResult(
      normalized: normalized,
      dictionary: lookup,
      signals: List.unmodifiable(signals),
      decision: decision,
    );
  }

  /// Live shortcut chips while typing (before space).
  IntelligenceResult processShortcutOnly(TextContext ctx, {int? nowMs}) {
    final clock = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final signals = _shortcut.analyze(ctx);
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
      signals: List.unmodifiable(signals),
      decision: decision,
    );
  }

  void setUserShortcuts(Iterable<TextShortcut> shortcuts) {
    _shortcuts = ShortcutTable(
      builtin: defaultBuiltinShortcuts,
      user: shortcuts,
    );
    _shortcut = ShortcutEngine(_shortcuts);
  }

  /// Refreshes spell/mat/toxic engines after [DictionaryManager.open].
  void reloadDictionaries() {
    _preload('en');
    _preload('ru');
  }
}
