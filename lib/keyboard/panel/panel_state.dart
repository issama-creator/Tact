/// Exactly one visible panel mode — no boolean explosion.
library;

import '../input/text_context.dart';
import '../rules/rule_signal.dart';

/// The single panel state shown in the suggestion bar.
sealed class PanelState {
  const PanelState();
}

/// No actionable panel — bar may stay empty or show passive hints.
final class PanelIdle extends PanelState {
  const PanelIdle();
}

final class PanelUndo extends PanelState {
  const PanelUndo({required this.label});

  final String label;
}

final class PanelMat extends PanelState {
  const PanelMat({
    required this.word,
    required this.range,
  });

  final String word;
  final EditRange range;
}

final class PanelToxic extends PanelState {
  const PanelToxic({
    required this.word,
    required this.level,
    required this.score,
    required this.range,
  });

  final String word;
  final ToxicLevel level;
  final int score;
  final EditRange range;
}

final class PanelImprove extends PanelState {
  const PanelImprove({required this.messageLength});

  final int messageLength;
}

/// Sentence-end AI chips: орфография / пунктуация / улучшить текст.
final class PanelAiAssist extends PanelState {
  const PanelAiAssist({required this.messageLength});

  final int messageLength;

  static const chipLabels = <String>[
    'орфография',
    'пунктуация',
    'улучшить текст',
  ];
}

final class PanelShortcut extends PanelState {
  const PanelShortcut({
    required this.trigger,
    required this.expansions,
    required this.range,
  });

  final String trigger;
  final List<String> expansions;
  final EditRange range;
}

final class PanelSuggestions extends PanelState {
  const PanelSuggestions({required this.words});

  final List<String> words;
}

/// Output of [RulesEngine] — wraps the winning [PanelState].
final class PanelDecision {
  const PanelDecision({
    required this.state,
    required this.producedAtMs,
  });

  final PanelState state;
  final int producedAtMs;
}

/// Settings for panel reduction / hysteresis.
final class PanelSettings {
  const PanelSettings({
    this.hysteresisMs = 200,
  });

  final int hysteresisMs;
}

/// Applies hysteresis so the panel does not flicker between modes.
PanelState reducePanel({
  required PanelState previous,
  required PanelDecision next,
  required PanelSettings settings,
  required int nowMs,
  int? lastChangeMs,
}) {
  if (previous is PanelIdle) return next.state;
  if (lastChangeMs == null) return next.state;
  if (nowMs - lastChangeMs < settings.hysteresisMs) return previous;
  return next.state;
}

bool _expansionsEqual(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool panelModesEqual(PanelState a, PanelState b) {
  if (a.runtimeType != b.runtimeType) return false;
  return switch ((a, b)) {
    (PanelIdle(), PanelIdle()) => true,
    (PanelUndo la, PanelUndo lb) => la.label == lb.label,
    (PanelMat ma, PanelMat mb) => ma.word == mb.word,
    (PanelToxic ta, PanelToxic tb) =>
      ta.word == tb.word && ta.level == tb.level,
    (PanelImprove ia, PanelImprove ib) =>
      ia.messageLength == ib.messageLength,
    (PanelAiAssist aa, PanelAiAssist ab) =>
      aa.messageLength == ab.messageLength,
    (PanelShortcut sa, PanelShortcut sb) =>
      sa.trigger == sb.trigger &&
      sa.expansions.length == sb.expansions.length &&
      _expansionsEqual(sa.expansions, sb.expansions),
    (PanelSuggestions sa, PanelSuggestions sb) =>
      sa.words.length == sb.words.length &&
      _expansionsEqual(sa.words, sb.words),
    _ => false,
  };
}
