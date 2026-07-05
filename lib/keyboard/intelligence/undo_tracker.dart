/// Tracks whether an undo action is available for the rules layer.
library;

import 'package:clock/clock.dart';

/// Undo chip and stack stay valid for this window after each panel action.
const int kUndoWindowMs = 3000;

final class UndoTracker {
  bool _available = false;
  int? _expiresAtMs;

  bool get available {
    if (!_available) return false;
    final expires = _expiresAtMs;
    if (expires == null) return true;
    return clock.now().millisecondsSinceEpoch < expires;
  }

  int? get expiresAtMs => _expiresAtMs;

  void markAvailable({int? nowMs}) {
    final now = nowMs ?? clock.now().millisecondsSinceEpoch;
    _available = true;
    _expiresAtMs = now + kUndoWindowMs;
  }

  void clear() {
    _available = false;
    _expiresAtMs = null;
  }
}
