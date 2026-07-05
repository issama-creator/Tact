// lib/keyboard/actions/undo_stack.dart
//
// UndoStack — bounded stack of reversible text edits.
//
// Every mutation applied by TACT — typed characters, shortcut expansion,
// spell fix, AI improvement, tone softening, mat removal — pushes an inverse
// TextEdit onto this stack. The `Undo` action pops and re-applies the
// inverse via ImeBridge.replaceRange.
//
// Coalescing:
//   Consecutive character insertions within a short window (~500 ms) are
//   coalesced into a single undo unit — so pressing Undo once reverts the
//   whole word, not one letter.
//
// Contents (planned):
//   • class UndoStack {
//       UndoStack({int capacity = 64});
//       void push(TextEdit inverse);
//       TextEdit? pop();
//       bool get isEmpty;
//       int get length;
//     }
//
// Depends on: actions/text_actions.dart (for TextEdit).
// Must NOT: import Flutter or plugins.
//
// TODO: implement.
library;
