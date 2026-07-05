import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/actions/text_replacement.dart';
import 'package:tact/keyboard/actions/undo_stack.dart';

void main() {
  test('push and pop LIFO', () {
    final stack = UndoStack(capacity: 4);
    stack.push(const TextEdit(
      deleteBefore: 5,
      deleteAfter: 0,
      insertedText: 'helo ',
      replacedText: 'hello ',
      selectionStart: 5,
      selectionEnd: 5,
    ));
    stack.push(const TextEdit(
      deleteBefore: 3,
      deleteAfter: 0,
      insertedText: 'old',
      replacedText: 'new',
      selectionStart: 1,
      selectionEnd: 1,
    ));
    expect(stack.length, 2);
    expect(stack.pop()?.replacedText, 'new');
    expect(stack.pop()?.replacedText, 'hello ');
    expect(stack.isEmpty, isTrue);
  });

  test('respects capacity', () {
    final stack = UndoStack(capacity: 2);
    for (var i = 0; i < 5; i++) {
      stack.push(TextEdit(
        deleteBefore: 1,
        deleteAfter: 0,
        insertedText: '$i',
        replacedText: 'x',
        selectionStart: 0,
        selectionEnd: 0,
      ));
    }
    expect(stack.length, 2);
    expect(stack.pop()?.insertedText, '4');
  });
}
