/// Routes word-boundary events through the Local Intelligence Engine.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';

import '../actions/text_replacement.dart';
import '../dictionaries/mat_lexicon.dart';
import '../intelligence/local_intelligence_engine.dart';
import '../panel/panel_anchor.dart';
import '../panel/panel_state.dart';
import '../rules/rule_signal.dart';
import '../../core/bridge/ime_bridge_facade.dart';
import 'text_context.dart';
import 'word_length_policy.dart';

typedef PanelListener = void Function(PanelState state);
typedef ActionContextListener = void Function(ActionContext ctx);
typedef MatBlockHandler = Future<void> Function(PanelMat panel);

/// Subscribes to [ImeBridge.onWordCommitted] and runs the intelligence pipeline.
final class InputPipeline {
  InputPipeline({
    required ImeBridge bridge,
    required LocalIntelligenceEngine engine,
    PanelListener? onPanel,
    ActionContextListener? onActionContext,
    void Function()? onFieldCleared,
    MatBlockHandler? onMatBlock,
    PanelSettings settings = const PanelSettings(),
  })  : _bridge = bridge,
        _engine = engine,
        _onPanel = onPanel,
        _onActionContext = onActionContext,
        _onFieldCleared = onFieldCleared,
        _onMatBlock = onMatBlock,
        _settings = settings;

  final ImeBridge _bridge;
  final LocalIntelligenceEngine _engine;
  final PanelListener? _onPanel;
  final ActionContextListener? _onActionContext;
  final void Function()? _onFieldCleared;
  final MatBlockHandler? _onMatBlock;
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
  bool _disposed = false;

  PanelState get panel => _panel;

  void start() {
    _sub ??= _bridge.onWordCommitted.listen(_onWord);
    _partialSub ??= _bridge.onPartialWord.listen(_onPartialWord);
    _partialClearSub ??=
        _bridge.onPartialWordClear.listen((_) => _onPartialWordClear());
    _textEditSub ??= _bridge.onTextEdited.listen((_) => _scheduleAnchorValidation());
  }

  void stop() {
    _disposed = true;
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
    if (_disposed || _bridge.isPasswordField) return;
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
    if (_disposed || _bridge.isPasswordField) {
      _clearPartialPanel();
      return;
    }
    final word = event.word.trim();
    if (word.length < kMinShortcutTriggerLength) {
      _clearPartialPanel();
      return;
    }

    // Never replace a committed analysis panel (mat / toxic / …).
    if (_panel is! PanelIdle &&
        _panel is! PanelShortcut &&
        _panel is! PanelSuggestions) {
      return;
    }

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
    final result = _engine.processPartial(ctx);
    final next = result.decision.state;

    if (next is PanelShortcut || next is PanelSuggestions) {
      // So chip tap replaces the current partial fragment.
      _onActionContext?.call(
        ActionContext(
          word: word,
          locale: event.locale,
          deleteBefore:
              event.deleteBefore > 0 ? event.deleteBefore : word.length,
          deleteAfter: event.deleteAfter,
          boundary: event.boundary,
          before: before,
          after: after,
        ),
      );
      if (kDebugMode) {
        if (next is PanelShortcut) {
          debugPrint('[TACT Pipeline] partial shortcut trigger="$word"');
        } else {
          debugPrint(
            '[TACT Pipeline] partial autocomplete "$word" → '
            '${(next as PanelSuggestions).words.join(", ")}',
          );
        }
      }
      _panelFromPartialOnly = _panel is PanelIdle || _panelFromPartialOnly;
      if (panelModesEqual(_panel, next)) return;
      _panel = next;
      _onPanel?.call(_panel);
    } else {
      _clearPartialPanel();
    }

    if (_shouldValidateAnchor(_panel)) {
      _reactToPartialEdit(event);
    }
  }

  void _onPartialWordClear() {
    _clearPartialPanel();
    if (!_shouldValidateAnchor(_panel)) return;
    _anchorValidationDebounce?.cancel();
    unawaited(_validatePanelAnchor());
  }

  /// Mat / spell / toxic only — shortcuts have their own partial/committed lifecycle.
  bool _shouldValidateAnchor(PanelState panel) => switch (panel) {
        PanelMat() || PanelSpell() || PanelToxic() => true,
        _ => false,
      };

  /// Immediate anchor check only while backspacing into the anchored token.
  void _reactToPartialEdit(WordEvent event) {
    final partialWord = event.word;
    final anchor = anchoredWord(_panel);
    if (anchor == null || anchor.isEmpty) return;

    final partial = partialWord.toLowerCase();
    final anchorLower = anchor.toLowerCase();
    final stillDeleting =
        partial.isEmpty || anchorLower.startsWith(partial);
    if (!stillDeleting) return;

    _anchorValidationDebounce?.cancel();
    // Prefer native commit buffers — no InputConnection round-trip on typing.
    unawaited(
      _validatePanelAnchor(
        localHint: SurroundingSnapshot(
          before: '${event.before}${event.word}',
          after: event.after,
          selectionStart: 0,
          selectionEnd: 0,
          isPassword: false,
        ),
      ),
    );
  }

  void _clearPartialPanel() {
    if (!_panelFromPartialOnly) return;
    if (_panel is PanelShortcut || _panel is PanelSuggestions) {
      if (kDebugMode) {
        debugPrint('[TACT Pipeline] clear partial panel');
      }
      _panelFromPartialOnly = false;
      _panel = const PanelIdle();
      _onPanel?.call(_panel);
    }
  }

  /// Hides mat/spell/toxic/shortcut panels when the user erased the word.
  Future<void> _validatePanelAnchor({SurroundingSnapshot? localHint}) async {
    if (_disposed) return;
    final panel = _panel;
    if (panel is PanelUndo || panel is PanelIdle) return;
    if (!panelTracksAnchoredWord(panel)) return;

    final word = anchoredWord(panel);
    if (word == null || word.isEmpty) return;

    if (localHint != null) {
      if (isAnchoredWordPresent(localHint, word)) return;
      // Commit buffer is authoritative while typing in the IME.
      if (kDebugMode) {
        debugPrint('[TACT Pipeline] anchor "$word" removed -> PanelIdle');
      }
      _panelFromPartialOnly = false;
      _panel = const PanelIdle();
      _onPanel?.call(_panel);
      return;
    }

    // Host-driven edits: small window is enough for panel anchors.
    final snap = await _bridge.getSurroundingText(before: 96, after: 32);
    if (_disposed || snap == null) return;

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
    if (_disposed) return;
    final snap = await _bridge.getSurroundingText();
    if (_disposed || snap == null || snap.before.isEmpty) return;
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
    // New word boundary supersedes any pending undo chip.
    if (_engine.undo.available) {
      _engine.undo.clear();
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

    if (_engine.antiMatEnabled && _onMatBlock != null) {
      final blocked = _blockMatPayload(result.signals);
      if (blocked != null) {
        if (kDebugMode) {
          debugPrint(
            '[TACT Pipeline] block mat "${blocked.word}" -> auto remove',
          );
        }
        unawaited(_onMatBlock!(PanelMat(word: word, range: ctx.range)));
        return;
      }
    }

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

  static MatPayload? _blockMatPayload(List<RuleSignal> signals) {
    for (final signal in signals) {
      if (signal.kind != SignalKind.mat) continue;
      final payload = signal.payload;
      if (payload is MatPayload && payload.level == MatLevel.block) {
        return payload;
      }
    }
    return null;
  }
}
