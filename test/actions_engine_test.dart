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
    String word = 'хуй',
    String boundary = ' ',
    int deleteBefore = 4,
  }) =>
      ActionContext(
        word: word,
        locale: 'ru',
        deleteBefore: deleteBefore,
        deleteAfter: 0,
        boundary: boundary,
        before: 'oh ',
        after: '',
      );

  setUp(() {
    field = FakeTextField(text: 'oh хуй ', selectionStart: 7, selectionEnd: 7);
    bridge = ImeBridge(fakeField: field);
    tracker = UndoTracker();
    actions = ActionsEngine(
      bridge: bridge,
      undoStack: UndoStack(),
      undoTracker: tracker,
    );
    actions.rememberContext(ctx());
  });

  test('remove mat deletes word and enables undo', () async {
    final result = await actions.removeMat(
      const PanelMat(word: 'хуй', range: EditRange(3, 6)),
    );
    expect(result.isOk, isTrue);
    expect(field.text, 'oh ');
    expect(tracker.available, isTrue);
    expect(tracker.label, UndoLabels.matRemoved);
    expect(actions.undoStack.isNotEmpty, isTrue);
  });

  test('undo restores previous text and cursor', () async {
    const cursorBefore = 7;
    field.selectionStart = cursorBefore;
    field.selectionEnd = cursorBefore;
    await actions.removeMat(
      const PanelMat(word: 'хуй', range: EditRange(3, 6)),
    );
    await actions.undo();
    expect(field.text, 'oh хуй ');
    expect(field.selectionStart, cursorBefore);
    expect(tracker.available, isFalse);
  });

  test('soften toxic replaces word locally', () async {
    field.text = 'ты идиот ';
    field.selectionStart = 9;
    field.selectionEnd = 9;
    actions.rememberContext(ctx(word: 'идиот', deleteBefore: 6));
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
    expect(tracker.label, UndoLabels.toxicSoftened);
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
    expect(tracker.label, UndoLabels.shortcutExpanded);
  });

  test('improve normalizes full message', () async {
    field.text = '  hello   world  ';
    field.selectionStart = field.text.length;
    field.selectionEnd = field.text.length;
    await actions.improve();
    expect(field.text, 'Hello world');
    expect(tracker.label, UndoLabels.improved);
  });

  test('repeated actions stack undo', () async {
    await actions.removeMat(
      const PanelMat(word: 'хуй', range: EditRange(3, 6)),
    );
    field.text = 'oh сука ';
    field.selectionStart = 8;
    field.selectionEnd = 8;
    actions.rememberContext(ctx(word: 'сука', deleteBefore: 5));
    await actions.removeMat(
      const PanelMat(word: 'сука', range: EditRange(3, 7)),
    );
    expect(actions.undoStack.length, 2);
  });

  test('unicode emoji preserved in replacement', () async {
    field.text = 'hi идиот 😀';
    field.selectionStart = 9;
    field.selectionEnd = 9;
    actions.rememberContext(
      const ActionContext(
        word: 'идиот',
        locale: 'ru',
        deleteBefore: 6,
        deleteAfter: 0,
        boundary: ' ',
        before: 'hi ',
        after: '😀',
      ),
    );
    await actions.softenToxic(
      const PanelToxic(
        word: 'идиот',
        level: ToxicLevel.conflict,
        score: 80,
        range: EditRange(3, 8),
      ),
    );
    expect(field.text.contains('😀'), isTrue);
    expect(field.text.contains('идиот'), isFalse);
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
