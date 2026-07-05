/// Bounded stack of reversible text edits with cursor restoration.
library;

import 'text_replacement.dart';

final class UndoStack {
  UndoStack({this.capacity = 32});

  final int capacity;
  final List<TextEdit> _stack = [];

  bool get isEmpty => _stack.isEmpty;
  bool get isNotEmpty => _stack.isNotEmpty;
  int get length => _stack.length;

  void push(TextEdit inverse) {
    if (_stack.length >= capacity) {
      _stack.removeAt(0);
    }
    _stack.add(inverse);
  }

  TextEdit? peek() => _stack.isEmpty ? null : _stack.last;

  TextEdit? pop() {
    if (_stack.isEmpty) return null;
    return _stack.removeLast();
  }

  void clear() => _stack.clear();
}
