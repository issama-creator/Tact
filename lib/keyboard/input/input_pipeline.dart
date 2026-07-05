/// Routes word-boundary events through the Local Intelligence Engine.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../actions/text_replacement.dart';
import '../intelligence/local_intelligence_engine.dart';
import '../panel/panel_anchor.dart';
import '../panel/panel_state.dart';
import '../../core/bridge/ime_bridge_facade.dart';
import 'text_context.dart';
import 'word_length_policy.dart';

typedef PanelListener = void Function(PanelState state);
typedef ActionContextListener = void Function(ActionContext ctx);

/// Subscribes to [ImeBridge.onWordCommitted] and runs the intelligence pipeline.
final class InputPipeline {
  InputPipeline({
    required ImeBridge bridge,
    required LocalIntelligenceEngine engine,
    PanelListener? onPanel,
    ActionContextListener? onActionContext,
    void Function()? onFieldCleared,
    PanelSettings settings = const PanelSettings(),
  })  : _bridge = bridge,
        _engine = engine,
        _onPanel = onPanel,
        _onActionContext = onActionContext,
        _onFieldCleared = onFieldCleared,
        _settings = settings;

  final ImeBridge _bridge;
  final LocalIntelligenceEngine _engine;
  final PanelListener? _onPanel;
  final ActionContextListener? _onActionContext;
  final void Function()? _onFieldCleared;
  final PanelSettings _settings;

  StreamSubscription<WordEvent>? _sub;
  StreamSubscription<WordEvent>? _partialSub;
  StreamSubscription<void>? _partialClearSub;
  StreamSubscription<void>? _textEditSub;
  Timer? _anchorValidationDebounce;
  PanelState _panel = const PanelIdle();
  /// True when [PanelShortcut] was shown by live partial-word typing only.
  bool _panelFromPartialOnly = false;
  int? _lastChangeMs;
  int _generation = 0;

  PanelState get panel => _panel;

  void start() {
    _sub ??= _bridge.onWordCommitted.listen(_onWord);
    _partialSub ??= _bridge.onPartialWord.listen(_onPartialWord);
    _partialClearSub ??=
        _bridge.onPartialWordClear.listen((_) => _clearPartialPanel());
    _textEditSub ??= _bridge.onTextEdited.listen((_) => _scheduleAnchorValidation());
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _partialSub?.cancel();
    _partialSub = null;
    _partialClearSub?.cancel();
    _partialClearSub = null;
    _textEditSub?.cancel();
    _textEditSub = null;
    _anchorValidationDebounce?.cancel();
    _anchorValidationDebounce = null;
  }

  void _onWord(WordEvent event) {
    final word = event.word.trim();
    if (!shouldProcessWordBoundary(word)) return;
    if (kDebugMode) {
      debugPrint('[TACT Pipeline] commit word="$word" locale=${event.locale}');
    }

    // Native commit buffer is authoritative — never block on host InputConnection.
    final before = event.before;
    final after = event.after;

    _dispatch(event, word, before, after);

    if (before.isEmpty) {
      unawaited(_enrichActionContext(event, word));
    }
  }

  void _onPartialWord(WordEvent event) {
    final word = event.word.trim();
    if (word.length < kMinShortcutTriggerLength) {
      _clearPartialPanel();
      return;
    }

    // Never replace a committed analysis panel (mat / spell / toxic / …).
    if (_panel is! PanelIdle && _panel is! PanelShortcut) return;

    // Keep a shortcut that was already committed at word boundary.
    if (!_panelFromPartialOnly && _panel is PanelShortcut) {
      final current = _panel as PanelShortcut;
      if (current.trigger == word) return;
    }

    final before = event.before;
    final after = event.after;
    final ctx = TextContext(
      word: word,
      before: before,
      after: after,
      range: EditRange(before.length, before.length + word.length),
      locale: event.locale,
      fullMessage: '$before$word$after',
    );
    final result = _engine.processShortcutOnly(ctx);
    final next = result.decision.state;
    if (next is PanelShortcut) {
      if (kDebugMode) {
        debugPrint('[TACT Pipeline] partial shortcut trigger="$word"');
      }
      _panelFromPartialOnly = _panel is PanelIdle;
      _panel = next;
      _onPanel?.call(_panel);
    } else {
      _clearPartialPanel();
    }
  }

  void _clearPartialPanel() {
    if (!_panelFromPartialOnly) return;
    if (_panel is PanelShortcut) {
      if (kDebugMode) {
        debugPrint('[TACT Pipeline] clear partial shortcut panel');
      }
      _panelFromPartialOnly = false;
      _panel = const PanelIdle();
      _onPanel?.call(_panel);
    }
  }

  /// Hides mat/spell/toxic/shortcut panels when the user erased the word.
  Future<void> _validatePanelAnchor() async {
    final panel = _panel;
    if (panel is PanelUndo || panel is PanelIdle) return;
    if (!panelTracksAnchoredWord(panel)) return;

    final word = anchoredWord(panel);
    if (word == null || word.isEmpty) return;

    final snap = await _bridge.getSurroundingText();
    if (snap == null) return;

    if (isAnchoredWordPresent(snap, word)) return;

    if (kDebugMode) {
      debugPrint('[TACT Pipeline] anchor "$word" removed -> PanelIdle');
    }
    _panelFromPartialOnly = false;
    _panel = const PanelIdle();
    _onPanel?.call(_panel);
  }

  void _scheduleAnchorValidation() {
    final panel = _panel;
    if (panel is PanelUndo || panel is PanelIdle) return;
    if (!panelTracksAnchoredWord(panel)) return;

    _anchorValidationDebounce?.cancel();
    _anchorValidationDebounce = Timer(
      const Duration(milliseconds: 40),
      () => unawaited(_validatePanelAnchor()),
    );
  }

  Future<void> _enrichActionContext(WordEvent event, String word) async {
    final snap = await _bridge.getSurroundingText();
    if (snap == null || snap.before.isEmpty) return;
    _onActionContext?.call(
      ActionContext(
        word: word,
        locale: event.locale,
        deleteBefore: event.deleteBefore > 0 ? event.deleteBefore : word.length,
        deleteAfter: event.deleteAfter,
        boundary: event.boundary,
        before: snap.before,
        after: snap.after.isNotEmpty ? snap.after : event.after,
      ),
    );
  }

  void _dispatch(WordEvent event, String word, String before, String after) {
    if (_panel is PanelUndo && _engine.undo.available) {
      return;
    }

    final actionCtx = ActionContext(
      word: word,
      locale: event.locale,
      deleteBefore: event.deleteBefore > 0 ? event.deleteBefore : word.length,
      deleteAfter: event.deleteAfter,
      boundary: event.boundary,
      before: before,
      after: after,
    );
    _onActionContext?.call(actionCtx);

    final gen = ++_generation;
    final ctx = TextContext(
      word: word,
      before: before,
      after: after,
      range: EditRange(before.length, before.length + word.length),
      locale: event.locale,
      fullMessage: '$before$word$after',
    );
    final result = _engine.process(ctx);
    if (gen != _generation) return;

    final now = result.decision.producedAtMs;
    final next = reducePanel(
      previous: _panel,
      next: result.decision,
      settings: _settings,
      nowMs: now,
      lastChangeMs: _lastChangeMs,
    );
    if (!panelModesEqual(_panel, next)) {
      _lastChangeMs = now;
    }
    if (kDebugMode) {
      debugPrint(
        '[TACT Pipeline] panel ${_panel.runtimeType} -> ${next.runtimeType} '
        '(signals=${result.signals.length}, locale=${event.locale}, word="$word")',
      );
    }
    _panelFromPartialOnly = false;
    _panel = next;
    _onPanel?.call(_panel);
  }

  /// Subsequent typing invalidates in-flight panel updates.
  void onKeystroke() {
    _generation++;
    if (_panel is! PanelUndo) {
      _panel = const PanelIdle();
      _onPanel?.call(_panel);
    }
  }

  void onFieldFinished() {
    if (kDebugMode) {
      debugPrint('[TACT Pipeline] field finished -> PanelIdle');
    }
    _onFieldCleared?.call();
    _panelFromPartialOnly = false;
    _panel = const PanelIdle();
    _onPanel?.call(_panel);
  }

  void dispose() {
    stop();
  }

  /// Keeps pipeline state aligned when [ActionsEngine] drives the panel directly.
  void adoptPanel(PanelState state) {
    _panel = state;
    _panelFromPartialOnly = false;
  }
}
