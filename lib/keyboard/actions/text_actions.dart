/// User-invoked text actions: Fix / Remove / Soften / Improve / Shortcut.
library;

import '../../core/result.dart';
import '../panel/panel_state.dart';
import 'local_text_transform.dart';
import 'text_replacement.dart';

enum PanelActionKind {
  fixSpell,
  removeMat,
  softenToxic,
  improve,
  expandShortcut,
  insertSuggestion,
  undo,
}

/// Plans replacements for each panel action — pure, no I/O.
abstract final class TextActions {
  static Result<ReplacementPlan, ActionError> fixSpell({
    required PanelSpell panel,
    required ActionContext ctx,
    String? candidate,
  }) {
    final fix = candidate ?? panel.candidates.firstOrNull;
    if (fix == null) return const Result.err(ActionError.emptyReplacement);
    return TextReplacement.planWordReplace(ctx: ctx, newWord: fix);
  }

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
    return TextReplacement.planWordReplace(
      ctx: ctx,
      newWord: word,
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

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
