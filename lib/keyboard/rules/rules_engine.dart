/// Picks exactly one panel state from engine signals.
library;

import '../intelligence/undo_tracker.dart';
import '../panel/panel_state.dart';
import '../rules/rule_signal.dart';

/// Decides which single panel mode to show.
final class RulesEngine {
  const RulesEngine();

  PanelDecision evaluate({
    required List<RuleSignal> signals,
    required bool undoAvailable,
    required List<String> defaultSuggestions,
    required int nowMs,
    int messageLength = 0,
    String undoLabel = UndoLabels.fallback,
  }) {
    if (undoAvailable) {
      return PanelDecision(
        state: PanelUndo(label: undoLabel),
        producedAtMs: nowMs,
      );
    }

    RuleSignal? mat;
    RuleSignal? toxic;
    RuleSignal? improve;
    RuleSignal? aiAssist;
    RuleSignal? shortcut;

    for (final s in signals) {
      switch (s.kind) {
        case SignalKind.mat:
          mat ??= s;
        case SignalKind.toxic:
          toxic ??= s;
        case SignalKind.improve:
          improve ??= s;
        case SignalKind.aiAssist:
          aiAssist ??= s;
        case SignalKind.shortcutMatch:
          shortcut ??= s;
        case SignalKind.nextWord:
        case SignalKind.undo:
          break;
      }
    }

    if (mat != null) {
      final payload = mat.payload;
      final matWord = payload is MatPayload
          ? payload.word
          : payload is String
              ? payload
              : '';
      return PanelDecision(
        state: PanelMat(
          word: matWord,
          range: mat.range,
        ),
        producedAtMs: nowMs,
      );
    }

    if (toxic != null) {
      final payload = toxic.payload! as ToxicPayload;
      return PanelDecision(
        state: PanelToxic(
          word: payload.word,
          level: payload.level,
          score: payload.score,
          range: toxic.range,
        ),
        producedAtMs: nowMs,
      );
    }

    if (aiAssist != null) {
      return PanelDecision(
        state: PanelAiAssist(messageLength: messageLength),
        producedAtMs: nowMs,
      );
    }

    if (improve != null && mat == null && toxic == null) {
      return PanelDecision(
        state: PanelImprove(messageLength: messageLength),
        producedAtMs: nowMs,
      );
    }

    if (shortcut != null) {
      final payload = shortcut.payload! as ShortcutPayload;
      final expansions = payload.expansions.take(3).toList(growable: false);
      return PanelDecision(
        state: PanelShortcut(
          trigger: payload.trigger,
          expansions: expansions,
          range: shortcut.range,
        ),
        producedAtMs: nowMs,
      );
    }

    if (defaultSuggestions.isNotEmpty) {
      return PanelDecision(
        state: PanelSuggestions(words: defaultSuggestions),
        producedAtMs: nowMs,
      );
    }

    return PanelDecision(
      state: const PanelIdle(),
      producedAtMs: nowMs,
    );
  }
}
