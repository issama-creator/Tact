/// User-invoked text actions: Remove / Soften / Improve / Shortcut / Suggest.
library;

import '../../core/result.dart';
import '../panel/panel_state.dart';
import 'local_text_transform.dart';
import 'text_replacement.dart';

/// Plans replacements for each panel action — pure, no I/O.
abstract final class TextActions {
  static Result<ReplacementPlan, ActionError> removeMat({
    required PanelMat panel,
    required ActionContext ctx,
  }) =>
      TextReplacement.planWordDelete(ctx: ctx);

  static Result<ReplacementPlan, ActionError> softenToxic({
    required PanelToxic panel,
    required ActionContext ctx,
  }) {
    final soft = LocalTextTransform.softenWord(panel.word);
    return TextReplacement.planWordReplace(ctx: ctx, newWord: soft);
  }

  static Result<ReplacementPlan, ActionError> expandShortcut({
    required String expansion,
    required ActionContext ctx,
  }) {
    return TextReplacement.planWordReplace(ctx: ctx, newWord: expansion);
  }

  static Result<ReplacementPlan, ActionError> insertSuggestion({
    required String word,
    required ActionContext ctx,
  }) {
    final trimmed = word.trimRight();
    if (trimmed.isEmpty) {
      return const Result.err(ActionError.emptyReplacement);
    }
    final alreadySpaced =
        ctx.after.isNotEmpty && ctx.after.codeUnitAt(0) == 0x20;
    final text = alreadySpaced ? trimmed : '$trimmed ';

    // After a completed word (space/punct) chips are next-word — insert only.
    // While typing a partial word, chips are autocomplete — replace the stub.
    if (ctx.boundary.isNotEmpty) {
      return TextReplacement.planInsertAtCursor(text);
    }
    return TextReplacement.planWordReplace(
      ctx: ctx,
      newWord: text,
      keepBoundary: false,
    );
  }

  static Result<ReplacementPlan, ActionError> improveMessage({
    required String before,
    required String after,
  }) {
    final improved = LocalTextTransform.improveMessage('$before$after');
    return TextReplacement.planFullMessageReplace(
      before: before,
      after: after,
      replacement: improved,
    );
  }
}
