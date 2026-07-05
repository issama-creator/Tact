// test/undo_stack_test.dart
//
// UndoStack behavior:
//   • push respects capacity; oldest entries drop first.
//   • Consecutive character insertions within the coalescing window merge
//     into a single undo unit.
//   • pop returns the last inverse edit and removes it.
//   • pop on empty returns null; isEmpty and length are consistent.
//
// TODO: implement.
library;
