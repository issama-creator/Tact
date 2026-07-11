/// Tracks whether an undo action is available for the rules layer.
library;

import 'package:clock/clock.dart';

/// Undo chip and stack stay valid for this window after each panel action.
const int kUndoWindowMs = 3000;

final class UndoTracker {
  bool _available = false;
  int? _expiresAtMs;
  String _label = UndoLabels.fallback;

  bool get available {
    if (!_available) return false;
    final expires = _expiresAtMs;
    if (expires == null) return true;
    return clock.now().millisecondsSinceEpoch < expires;
  }

  int? get expiresAtMs => _expiresAtMs;

  /// Status title shown on [PanelUndo] while the window is open.
  String get label => _label;

  void markAvailable({String label = UndoLabels.fallback, int? nowMs}) {
    final now = nowMs ?? clock.now().millisecondsSinceEpoch;
    _available = true;
    _label = label;
    _expiresAtMs = now + kUndoWindowMs;
  }

  void clear() {
    _available = false;
    _expiresAtMs = null;
    _label = UndoLabels.fallback;
  }
}

/// Per-action undo strip titles (RU). Detection copy lives in the suggestion bar.
abstract final class UndoLabels {
  static const matRemoved = 'Мат удалён';
  static const toxicSoftened = 'Тон смягчён';
  static const shortcutExpanded = 'Шаблон вставлен';
  static const improved = 'Текст улучшен';
  static const fallback = 'Изменение применено';
}
