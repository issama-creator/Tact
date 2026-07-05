import 'package:flutter_test/flutter_test.dart';
import 'package:tact/core/bridge/ime_bridge_facade.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/keyboard/panel/panel_anchor.dart';
import 'package:tact/keyboard/panel/panel_state.dart';

void main() {
  test('anchoredWord extracts mat and shortcut triggers', () {
    expect(
      anchoredWord(const PanelMat(word: 'хуй', range: EditRange(0, 3))),
      'хуй',
    );
    expect(
      anchoredWord(
        const PanelShortcut(
          trigger: 'др',
          expansions: ['Добрый день'],
          range: EditRange(0, 2),
        ),
      ),
      'др',
    );
    expect(anchoredWord(const PanelIdle()), isNull);
  });

  test('word present in before text', () {
    const snap = SurroundingSnapshot(
      before: 'say хуй ',
      after: '',
      selectionStart: 8,
      selectionEnd: 8,
      isPassword: false,
    );
    expect(isAnchoredWordPresent(snap, 'хуй'), isTrue);
  });

  test('word absent after manual delete', () {
    const snap = SurroundingSnapshot(
      before: 'say ',
      after: '',
      selectionStart: 4,
      selectionEnd: 4,
      isPassword: false,
    );
    expect(isAnchoredWordPresent(snap, 'хуй'), isFalse);
  });

  test('masked mat no longer matches original word', () {
    const snap = SurroundingSnapshot(
      before: 'say *** ',
      after: '',
      selectionStart: 8,
      selectionEnd: 8,
      isPassword: false,
    );
    expect(isAnchoredWordPresent(snap, 'хуй'), isFalse);
  });
}
