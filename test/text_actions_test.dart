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

  test('insertSuggestion appends trailing space like Gboard', () {
    final plan = TextActions.insertSuggestion(
      word: 'добрый',
      ctx: const ActionContext(
        word: 'доб',
        locale: 'ru',
        deleteBefore: 3,
        deleteAfter: 0,
        boundary: '',
        before: '',
        after: '',
      ),
    );
    expect(plan.isOk, isTrue);
    expect(plan.valueOrNull!.replacement, 'добрый ');
    expect(plan.valueOrNull!.deleteBefore, 3);
  });

  test('insertSuggestion skips double space when after already has one', () {
    final plan = TextActions.insertSuggestion(
      word: 'hello',
      ctx: const ActionContext(
        word: 'hel',
        locale: 'en',
        deleteBefore: 3,
        deleteAfter: 0,
        boundary: '',
        before: '',
        after: ' world',
      ),
    );
    expect(plan.valueOrNull!.replacement, 'hello');
    expect(plan.valueOrNull!.deleteBefore, 3);
  });

  test('next-word suggestion inserts without erasing previous word', () {
    final plan = TextActions.insertSuggestion(
      word: 'дела',
      ctx: const ActionContext(
        word: 'как',
        locale: 'ru',
        deleteBefore: 4,
        deleteAfter: 0,
        boundary: ' ',
        before: '',
        after: '',
      ),
    );
    expect(plan.isOk, isTrue);
    expect(plan.valueOrNull!.deleteBefore, 0);
    expect(plan.valueOrNull!.replacement, 'дела ');
  });

  test('mat removal deletes word', () {
    final plan = TextActions.removeMat(
      panel: const PanelMat(word: 'bad', range: EditRange(0, 3)),
      ctx: baseCtx(),
    );
    expect(plan.valueOrNull!.replacement, isEmpty);
    expect(plan.valueOrNull!.expectedReplacedText, 'helo ');
  });

  test('censor masks last letters for panel display', () {
    expect(LocalTextTransform.censorForDisplay('хуй'), 'х**');
    expect(LocalTextTransform.censorForDisplay('bad'), 'b**');
    expect(LocalTextTransform.censorForDisplay('xy'), 'x*');
    expect(LocalTextTransform.censorForDisplay('a'), '*');
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
