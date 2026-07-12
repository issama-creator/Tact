/// Single-pass analysis at word boundary (space / punctuation).
library;

import '../dictionaries/dictionary.dart';
import '../dictionaries/dictionary_manager.dart';
import '../dictionaries/locale_bundle.dart';
import '../dictionaries/mat_lexicon.dart';
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

/// Runs mat, toxic, shortcut, and improve checks in a single pass.
/// Dictionary lookup feeds next-word suggestions — no spell-correction panel.
final class WordBoundaryAnalyzer {
  WordBoundaryAnalyzer({
    Normalizer? normalizer,
    ShortcutTable? shortcuts,
    Set<String> personalWords = const {},
    this.improveMinChars = 30,
  }) : _normalizer = normalizer ?? Normalizer(),
       _shortcuts =
           shortcuts ??
           ShortcutTable(builtin: DictionaryManager.shared.builtinShortcuts),
       _personalWords = personalWords;

  /// Always reads the live singleton — asset load replaces [DictionaryManager.shared].
  DictionaryManager get _manager => DictionaryManager.shared;
  final Normalizer _normalizer;
  ShortcutTable _shortcuts;
  Set<String> _personalWords;
  final int improveMinChars;
  bool antiMatEnabled = true;
  bool antiToxicEnabled = true;
  bool improveEnabled = false;
  bool aiAssistantEnabled = true;
  double aiIntensity = 0.55;

  /// Reserved for filler-word detection (toggle wired, engine TBD).
  bool fillerWordsEnabled = false;

  String? _autoCacheKey;
  List<String> _autoCache = const [];

  void setShortcuts(ShortcutTable table) => _shortcuts = table;

  /// Kept for companion personal dictionary — reserved for suggestion filtering.
  void setPersonalWords(Set<String> words) {
    _personalWords = Set<String>.unmodifiable(
      words.map((w) => w.toLowerCase()).where((w) => w.length >= 2),
    );
  }

  Set<String> get personalWords => _personalWords;

  void setAntiMatEnabled(bool enabled) => antiMatEnabled = enabled;

  void setAntiToxicEnabled(bool enabled) => antiToxicEnabled = enabled;

  void setImproveEnabled(bool enabled) => improveEnabled = enabled;

  void setAiAssistantEnabled(bool enabled) => aiAssistantEnabled = enabled;

  void setAiIntensity(double value) => aiIntensity = value.clamp(0.0, 1.0);

  void setFillerWordsEnabled(bool enabled) => fillerWordsEnabled = enabled;

  void clearAutocompleteCache() {
    _autoCacheKey = null;
    _autoCache = const [];
  }

  /// Live shortcut chips while typing (before space).
  List<RuleSignal> analyzeShortcutOnly(TextContext ctx) {
    final signals = <RuleSignal>[];
    _checkShortcut(signals: signals, word: ctx.word, range: ctx.range);
    return signals;
  }

  /// Prefix autocomplete — Gboard-style completions while typing.
  /// Returns up to [max] dictionary words starting with the typed prefix.
  List<String> autocompletePrefix(
    String word,
    String localeKey, {
    int max = 3,
  }) {
    if (word.length < kMinShortcutTriggerLength) return const [];
    final normalized = _normalizer.normalize(word);
    if (normalized.length < kMinShortcutTriggerLength) return const [];

    // Include leading code unit so "Доб" vs "доб" casing stays correct.
    final caseCu = word.isEmpty ? 0 : word.codeUnitAt(0);
    final cacheKey = '$localeKey|$normalized|$max|$caseCu';
    if (_autoCacheKey == cacheKey) return _autoCache;

    final hits = _manager
        .bundleFor(localeKey)
        .spell
        .prefixCompletions(normalized, max: max);
    final out = hits.isEmpty
        ? const <String>[]
        : [for (final h in hits) _matchTypedCase(word, h)];
    _autoCacheKey = cacheKey;
    _autoCache = out;
    return out;
  }

  /// Preserve leading capital from what the user typed (Доб → Добрый).
  static String _matchTypedCase(String typed, String lowerCandidate) {
    if (typed.isEmpty || lowerCandidate.isEmpty) return lowerCandidate;
    final cu = typed.codeUnitAt(0);
    final upper =
        (cu >= 0x41 && cu <= 0x5A) ||
        (cu >= 0x0410 && cu <= 0x042F) ||
        cu == 0x0401;
    if (!upper) return lowerCandidate;
    final first = lowerCandidate[0].toUpperCase();
    if (lowerCandidate.length == 1) return first;
    return '$first${lowerCandidate.substring(1)}';
  }

  /// All word-boundary checks in one function — called on space / punctuation.
  WordBoundaryResult analyzeAtBoundary(TextContext ctx, String localeKey) {
    final word = ctx.word;
    final bundle = _manager.bundleFor(localeKey);
    final runLexicon = shouldRunLexiconAnalysis(word);
    final normalized = _normalizer.normalize(word);
    final lookup = bundle.spell.lookup(normalized);
    final lexiconKey = runLexicon ? _normalizer.normalizeForLexicon(word) : '';
    final skipLexicon = !runLexicon || TextSkip.shouldSkip(word);

    final signals = <RuleSignal>[];

    if (!skipLexicon && lexiconKey.isNotEmpty) {
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
        messageKey: _normalizer.normalizeForLexicon(
          _trailingWindow(ctx.fullMessage),
        ),
      );
    }

    // AI chips: after . ! ? once the message is long enough — independent of lexicon.
    _checkAiAssist(signals: signals, ctx: ctx);
    // Legacy improve status bar — only if AI assistant is off.
    if (!aiAssistantEnabled) {
      _checkImprove(signals: signals, ctx: ctx);
    }

    _checkShortcut(signals: signals, word: word, range: ctx.range);

    return WordBoundaryResult(
      normalized: normalized,
      lookup: lookup,
      signals: signals,
    );
  }

  void _checkMat({
    required List<RuleSignal> signals,
    required String word,
    required String lexiconKey,
    required EditRange range,
    required LocaleBundle bundle,
  }) {
    if (!antiMatEnabled) return;
    if (lexiconKey.length < kMinLexiconWordLength) return;
    final level = bundle.mat.lookup(lexiconKey);
    if (level == null) return;

    signals.add(
      RuleSignal(
        kind: SignalKind.mat,
        severity: level == MatLevel.block ? 100 : 90,
        confidence: 0.95,
        range: range,
        payload: MatPayload(word: word, level: level),
      ),
    );
  }

  void _checkToxic({
    required List<RuleSignal> signals,
    required String word,
    required String lexiconKey,
    required EditRange range,
    required LocaleBundle bundle,
    required String messageKey,
  }) {
    if (!antiToxicEnabled) return;
    ToxicEntry? entry;
    if (lexiconKey.length >= kMinLexiconWordLength) {
      entry = bundle.toxic.lookup(lexiconKey);
    }
    entry ??= bundle.toxic.lookupPhrase(messageKey);
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
    if (!improveEnabled) return;
    if (ctx.fullMessage.length < improveMinChars) return;
    // Require enough content — avoids improve spam on short padded messages.
    if (_wordCount(ctx.fullMessage) < 5) return;

    signals.add(
      RuleSignal(
        kind: SignalKind.improve,
        severity: 40,
        confidence: 0.6,
        range: ctx.range,
      ),
    );
  }

  static const _sentenceEnds = {'.', '!', '?'};

  /// Min chars before AI chips — fixed ~20.
  static const _aiMinChars = 20;

  void _checkAiAssist({
    required List<RuleSignal> signals,
    required TextContext ctx,
  }) {
    if (!aiAssistantEnabled) return;
    final b = ctx.boundary.trim();
    if (b.isEmpty || !_sentenceEnds.contains(b)) return;
    // Include the terminator so "…текст." counts toward the threshold.
    final len = ctx.fullMessage.length + b.length;
    if (len < _aiMinChars) return;

    signals.add(
      RuleSignal(
        kind: SignalKind.aiAssist,
        severity: 45,
        confidence: 0.7,
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

    // Triggers are stored lowercased; skip alloc when already lower.
    final match = _shortcuts.lookup(_shortcutKey(word));
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

  static int _wordCount(String message) {
    var count = 0;
    var inWord = false;
    for (var i = 0; i < message.length; i++) {
      final cu = message.codeUnitAt(i);
      final isSpace = cu == 0x20 || cu == 0x09 || cu == 0x0A || cu == 0x0D;
      if (isSpace) {
        inWord = false;
      } else if (!inWord) {
        inWord = true;
        count++;
      }
    }
    return count;
  }

  /// Phrase toxic scans only a trailing window — O(1) vs message length.
  static const _toxicWindowChars = 96;

  static String _trailingWindow(
    String message, [
    int chars = _toxicWindowChars,
  ]) {
    if (message.length <= chars) return message;
    return message.substring(message.length - chars);
  }

  /// Avoid [String.toLowerCase] when the trigger has no uppercase letters.
  static String _shortcutKey(String word) {
    for (var i = 0; i < word.length; i++) {
      final cu = word.codeUnitAt(i);
      if (cu >= 0x41 && cu <= 0x5A) return word.toLowerCase();
      if (cu >= 0x0410 && cu <= 0x042F) return word.toLowerCase();
      if (cu == 0x0401) return word.toLowerCase(); // Ё
    }
    return word;
  }
}
