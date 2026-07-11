import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tact/core/bridge/ime_bridge_facade.dart';
import 'package:tact/keyboard/actions/actions_engine.dart';
import 'package:tact/keyboard/actions/text_replacement.dart';
import 'package:tact/keyboard/actions/undo_stack.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/intelligence/undo_tracker.dart';
import 'package:tact/keyboard/panel/panel_state.dart';

void main() {
  test('undo tracker expires after 3 seconds', () {
    fakeAsync((async) {
      final tracker = UndoTracker();
      tracker.markAvailable();
      expect(tracker.available, isTrue);

      async.elapse(Duration(milliseconds: kUndoWindowMs + 1));
      expect(tracker.available, isFalse);
    });
  });

  test('undo panel hides and stack clears after 3 seconds', () {
    fakeAsync((async) {
      final field = FakeTextField(
        text: 'oh хуй ',
        selectionStart: 7,
        selectionEnd: 7,
      );
      final bridge = ImeBridge(fakeField: field);
      final tracker = UndoTracker();
      PanelState? panel;

      final actions = ActionsEngine(
        bridge: bridge,
        undoStack: UndoStack(),
        undoTracker: tracker,
        onPanel: (s) => panel = s,
      );
      actions.rememberContext(
        const ActionContext(
          word: 'хуй',
          locale: 'ru',
          deleteBefore: 4,
          deleteAfter: 0,
          boundary: ' ',
          before: 'oh ',
          after: '',
        ),
      );

      actions.removeMat(
        const PanelMat(word: 'хуй', range: EditRange(3, 6)),
      );
      async.flushMicrotasks();

      expect(panel, isA<PanelUndo>());
      expect((panel as PanelUndo).label, UndoLabels.matRemoved);
      expect(tracker.available, isTrue);
      expect(actions.undoStack.isNotEmpty, isTrue);

      async.elapse(const Duration(milliseconds: kUndoWindowMs));

      expect(panel, isA<PanelIdle>());
      expect(tracker.available, isFalse);
      expect(actions.undoStack.isEmpty, isTrue);
    });
  });

  test('manual undo cancels expiry timer', () {
    fakeAsync((async) {
      final field = FakeTextField(
        text: 'oh хуй ',
        selectionStart: 7,
        selectionEnd: 7,
      );
      final bridge = ImeBridge(fakeField: field);
      final tracker = UndoTracker();
      PanelState? panel;

      final actions = ActionsEngine(
        bridge: bridge,
        undoStack: UndoStack(),
        undoTracker: tracker,
        onPanel: (s) => panel = s,
      );
      actions.rememberContext(
        const ActionContext(
          word: 'хуй',
          locale: 'ru',
          deleteBefore: 4,
          deleteAfter: 0,
          boundary: ' ',
          before: 'oh ',
          after: '',
        ),
      );

      actions.removeMat(
        const PanelMat(word: 'хуй', range: EditRange(3, 6)),
      );
      async.flushMicrotasks();
      actions.undo();
      async.flushMicrotasks();

      expect(panel, isA<PanelIdle>());
      expect(tracker.available, isFalse);

      async.elapse(const Duration(milliseconds: kUndoWindowMs));
      expect(panel, isA<PanelIdle>());
    });
  });
}
