/// Tracks whether an undo action is available for the rules layer.
library;

final class UndoTracker {
  bool _available = false;

  bool get available => _available;

  void markAvailable() => _available = true;

  void clear() => _available = false;
}
