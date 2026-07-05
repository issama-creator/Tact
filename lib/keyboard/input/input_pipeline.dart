/// Routes word-boundary events through the Local Intelligence Engine.
library;

import 'dart:async';

import '../actions/text_replacement.dart';
import '../intelligence/local_intelligence_engine.dart';
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
  PanelState _panel = const PanelIdle();
  int? _lastChangeMs;
  int _generation = 0;

  PanelState get panel => _panel;

  void start() {
    _sub ??= _bridge.onWordCommitted.listen(_onWord);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void _onWord(WordEvent event) {
    final word = event.word.trim();
    if (!shouldProcessWordBoundary(word)) return;

    // Native commit buffer is authoritative — never block on host InputConnection.
    final before = event.before;
    final after = event.after;

    _dispatch(event, word, before, after);

    if (before.isEmpty) {
      unawaited(_enrichActionContext(event, word));
    }
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
    _onFieldCleared?.call();
    _panel = const PanelIdle();
    _onPanel?.call(_panel);
  }

  void dispose() {
    stop();
  }
}
