/// Pure helpers for planning and validating text replacements.
library;

import '../../core/result.dart';

/// Metadata captured when a word boundary fires — drives safe replacement.
final class ActionContext {
  const ActionContext({
    required this.word,
    required this.locale,
    required this.deleteBefore,
    required this.deleteAfter,
    required this.boundary,
    required this.before,
    required this.after,
  });

  final String word;
  final String locale;
  final int deleteBefore;
  final int deleteAfter;
  final String boundary;
  final String before;
  final String after;

  String get fullMessage => '$before$word$after';
}

/// A single reversible edit applied through the IME bridge.
final class TextEdit {
  const TextEdit({
    required this.deleteBefore,
    required this.deleteAfter,
    required this.insertedText,
    required this.replacedText,
    required this.selectionStart,
    required this.selectionEnd,
  });

  final int deleteBefore;
  final int deleteAfter;
  final String insertedText;
  final String replacedText;
  final int selectionStart;
  final int selectionEnd;
}

final class ReplacementPlan {
  const ReplacementPlan({
    required this.deleteBefore,
    required this.deleteAfter,
    required this.replacement,
    required this.expectedReplacedText,
    required this.selectionStart,
    required this.selectionEnd,
  });

  final int deleteBefore;
  final int deleteAfter;
  final String replacement;
  final String expectedReplacedText;
  final int selectionStart;
  final int selectionEnd;
}

abstract final class TextReplacement {
  static Result<ReplacementPlan, ActionError> planWordReplace({
    required ActionContext ctx,
    required String newWord,
    bool keepBoundary = true,
  }) {
    if (ctx.deleteBefore <= 0) return const Result.err(ActionError.invalidRange);
    if (newWord.isEmpty) return const Result.err(ActionError.emptyReplacement);

    final boundary = keepBoundary ? ctx.boundary : '';
    final replacement = '$newWord$boundary';
    final expected = '${ctx.word}$boundary';

    return Result.ok(
      ReplacementPlan(
        deleteBefore: ctx.deleteBefore,
        deleteAfter: ctx.deleteAfter,
        replacement: replacement,
        expectedReplacedText: expected,
        selectionStart: -1,
        selectionEnd: -1,
      ),
    );
  }

  /// Removes the committed word (and its boundary char, e.g. trailing space).
  static Result<ReplacementPlan, ActionError> planWordDelete({
    required ActionContext ctx,
  }) {
    if (ctx.deleteBefore <= 0) return const Result.err(ActionError.invalidRange);
    final expected = '${ctx.word}${ctx.boundary}';
    return Result.ok(
      ReplacementPlan(
        deleteBefore: ctx.deleteBefore,
        deleteAfter: ctx.deleteAfter,
        replacement: '',
        expectedReplacedText: expected,
        selectionStart: -1,
        selectionEnd: -1,
      ),
    );
  }

  static Result<ReplacementPlan, ActionError> planFullMessageReplace({
    required String before,
    required String after,
    required String replacement,
  }) {
    if (replacement.isEmpty) return const Result.err(ActionError.emptyReplacement);
    return Result.ok(
      ReplacementPlan(
        deleteBefore: before.length,
        deleteAfter: after.length,
        replacement: replacement,
        expectedReplacedText: '$before$after',
        selectionStart: -1,
        selectionEnd: -1,
      ),
    );
  }

  static TextEdit inverseFromOutcome({
    required ReplacementPlan plan,
    required String actualReplaced,
    required int selectionStart,
    required int selectionEnd,
  }) {
    return TextEdit(
      deleteBefore: plan.replacement.length,
      deleteAfter: 0,
      insertedText: actualReplaced,
      replacedText: plan.replacement,
      selectionStart: selectionStart,
      selectionEnd: selectionEnd,
    );
  }
}
