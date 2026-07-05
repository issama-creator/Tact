import 'package:flutter_test/flutter_test.dart';
import 'package:tact/keyboard/actions/local_text_transform.dart';
import 'package:tact/keyboard/actions/text_actions.dart';
import 'package:tact/keyboard/actions/text_replacement.dart';
import 'package:tact/keyboard/input/text_context.dart';
import 'package:tact/core/result.dart';
import 'package:tact/keyboard/panel/panel_state.dart';
import 'package:tact/keyboard/rules/rule_signal.dart';

ActionContext baseCtx() => const ActionContext(
      word: 'helo',
      locale: 'en',
      deleteBefore: 5,
      deleteAfter: 0,
      boundary: ' ',
      before: '',
      after: '',
    );

void main() {
  test('plan word replace keeps boundary', () {
    final plan = TextReplacement.planWordReplace(
      ctx: baseCtx(),
      newWord: 'hello',
    );
    expect(plan.isOk, isTrue);
    expect(plan.valueOrNull!.replacement, 'hello ');
    expect(plan.valueOrNull!.deleteBefore, 5);
  });

  test('fix action plans correction', () {
    final plan = TextActions.fixSpell(
      panel: const PanelSpell(
        word: 'helo',
        candidates: ['hello', 'help'],
        range: EditRange(0, 4),
      ),
      ctx: baseCtx(),
    );
    expect(plan.valueOrNull!.replacement, 'hello ');
  });

  test('mat removal masks word', () {
    final plan = TextActions.removeMat(
      panel: const PanelMat(word: 'bad', range: EditRange(0, 3)),
      ctx: baseCtx(),
    );
    expect(plan.valueOrNull!.replacement.contains('*'), isTrue);
  });

  test('soften uses local transform', () {
    final soft = LocalTextTransform.softenWord('идиот');
    expect(soft, isNot('идиот'));
    final plan = TextActions.softenToxic(
      panel: const PanelToxic(
        word: 'идиот',
        level: ToxicLevel.conflict,
        score: 80,
        range: EditRange(0, 5),
      ),
      ctx: const ActionContext(
        word: 'идиот',
        locale: 'ru',
        deleteBefore: 6,
        deleteAfter: 0,
        boundary: ' ',
        before: '',
        after: '',
      ),
    );
    expect(plan.valueOrNull!.replacement.contains('идиот'), isFalse);
  });

  test('shortcut expansion plan', () {
    final plan = TextActions.expandShortcut(
      expansion: 'Доброе утро',
      ctx: const ActionContext(
        word: 'др',
        locale: 'ru',
        deleteBefore: 3,
        deleteAfter: 0,
        boundary: ' ',
        before: '',
        after: '',
      ),
    );
    expect(plan.valueOrNull!.replacement, 'Доброе утро ');
  });
}
