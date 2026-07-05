import 'package:flutter_test/flutter_test.dart';
import 'package:tact/core/bridge/ime_bridge_facade.dart';
import 'package:tact/core/result.dart';
import 'package:tact/keyboard/actions/actions_engine.dart';
import 'package:tact/keyboard/actions/text_replacement.dart';
import 'package:tact/keyboard/actions/undo_stack.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/intelligence/undo_tracker.dart';
import 'package:tact/keyboard/panel/panel_state.dart';
import 'package:tact/keyboard/rules/rule_signal.dart';

void main() {
  late FakeTextField field;
  late ImeBridge bridge;
  late ActionsEngine actions;
  late UndoTracker tracker;

  ActionContext ctx({
    String word = 'helo',
    String boundary = ' ',
    int deleteBefore = 5,
  }) =>
      ActionContext(
        word: word,
        locale: 'en',
        deleteBefore: deleteBefore,
        deleteAfter: 0,
        boundary: boundary,
        before: 'say ',
        after: '',
      );

  setUp(() {
    field = FakeTextField(text: 'say helo ', selectionStart: 9, selectionEnd: 9);
    bridge = ImeBridge(fakeField: field);
    tracker = UndoTracker();
    actions = ActionsEngine(
      bridge: bridge,
      undoStack: UndoStack(),
      undoTracker: tracker,
    );
    actions.rememberContext(ctx());
  });

  test('fix spell replaces word and enables undo', () async {
    final panel = PanelSpell(
      word: 'helo',
      candidates: ['hello'],
      range: const EditRange(4, 8),
    );
    final result = await actions.fixSpell(panel);
    expect(result.isOk, isTrue);
    expect(field.text, 'say hello ');
    expect(tracker.available, isTrue);
    expect(actions.undoStack.isNotEmpty, isTrue);
  });

  test('undo restores previous text and cursor', () async {
    const cursorBefore = 9;
    field.selectionStart = cursorBefore;
    field.selectionEnd = cursorBefore;
    await actions.fixSpell(
      const PanelSpell(
        word: 'helo',
        candidates: ['hello'],
        range: EditRange(4, 8),
      ),
    );
    await actions.undo();
    expect(field.text, 'say helo ');
    expect(field.selectionStart, cursorBefore);
    expect(tracker.available, isFalse);
  });

  test('remove mat deletes profanity word', () async {
    field.text = 'oh хуй ';
    field.selectionStart = 7;
    field.selectionEnd = 7;
    actions.rememberContext(ctx(word: 'хуй', deleteBefore: 4, boundary: ' '));
    await actions.removeMat(
      const PanelMat(word: 'хуй', range: EditRange(3, 6)),
    );
    expect(field.text, 'oh ');
    expect(field.text.contains('хуй'), isFalse);
  });

  test('soften toxic replaces word locally', () async {
    field.text = 'ты идиот ';
    field.selectionStart = 9;
    field.selectionEnd = 9;
    actions.rememberContext(ctx(word: 'идиот', deleteBefore: 6, boundary: ' '));
    await actions.softenToxic(
      const PanelToxic(
        word: 'идиот',
        level: ToxicLevel.conflict,
        score: 80,
        range: EditRange(3, 8),
      ),
    );
    expect(field.text.contains('идиот'), isFalse);
    expect(field.text.contains('не лучший вариант'), isTrue);
  });

  test('shortcut expansion replaces trigger', () async {
    field.text = 'др ';
    field.selectionStart = 3;
    field.selectionEnd = 3;
    actions.rememberContext(
      const ActionContext(
        word: 'др',
        locale: 'ru',
        deleteBefore: 3,
        deleteAfter: 0,
        boundary: ' ',
        before: '',
        after: '',
      ),
    );
    await actions.expandShortcut('Доброе утро');
    expect(field.text, 'Доброе утро ');
  });

  test('improve normalizes full message', () async {
    field.text = '  hello   world  ';
    field.selectionStart = field.text.length;
    field.selectionEnd = field.text.length;
    await actions.improve();
    expect(field.text, 'Hello world');
  });

  test('repeated actions stack undo', () async {
    await actions.fixSpell(
      const PanelSpell(
        word: 'helo',
        candidates: ['hello'],
        range: EditRange(4, 8),
      ),
    );
    field.text = 'say hello ';
    field.selectionStart = 10;
    field.selectionEnd = 10;
    actions.rememberContext(ctx(word: 'hello', deleteBefore: 6));
    await actions.fixSpell(
      const PanelSpell(
        word: 'hello',
        candidates: ['hello'],
        range: EditRange(4, 9),
      ),
    );
    expect(actions.undoStack.length, 2);
  });

  test('unicode emoji preserved in replacement', () async {
    field.text = 'hi helo 😀';
    field.selectionStart = 8;
    field.selectionEnd = 8;
    actions.rememberContext(
      ActionContext(
        word: 'helo',
        locale: 'en',
        deleteBefore: 5,
        deleteAfter: 0,
        boundary: ' ',
        before: 'hi ',
        after: '😀',
      ),
    );
    await actions.fixSpell(
      const PanelSpell(
        word: 'helo',
        candidates: ['hello'],
        range: EditRange(3, 7),
      ),
    );
    expect(field.text, 'hi hello 😀');
  });

  test('password field blocks improve', () async {
    field.isPassword = true;
    final result = await actions.improve();
    expect(result.isErr, isTrue);
  });

  test('large text improve handles long message', () async {
    final long = 'word ' * 200;
    field.text = long;
    field.selectionStart = long.length;
    field.selectionEnd = long.length;
    final result = await actions.improve();
    expect(result.isOk, isTrue);
    expect(field.text.startsWith('Word '), isTrue);
  });
}
