/// Executes panel actions through [ImeBridge] with undo and haptics.
library;

import 'dart:async';

import '../../core/bridge/ime_bridge_facade.dart';
import '../../core/result.dart';
import '../intelligence/undo_tracker.dart';
import '../panel/panel_state.dart';
import 'text_actions.dart';
import 'text_replacement.dart';
import 'undo_stack.dart';

typedef PanelSetter = void Function(PanelState state);

/// Completes the user interaction cycle: tap → replace → undo.
final class ActionsEngine {
  ActionsEngine({
    required ImeBridge bridge,
    required UndoStack undoStack,
    required UndoTracker undoTracker,
    PanelSetter? onPanel,
  })  : _bridge = bridge,
        _undo = undoStack,
        _undoTracker = undoTracker,
        _onPanel = onPanel;

  final ImeBridge _bridge;
  final UndoStack _undo;
  final UndoTracker _undoTracker;
  final PanelSetter? _onPanel;

  Timer? _undoHideTimer;

  ActionContext? _lastContext;

  ActionContext? get lastContext => _lastContext;

  void rememberContext(ActionContext ctx) => _lastContext = ctx;

  void clearContext() => _lastContext = null;

  UndoStack get undoStack => _undo;

  Future<Result<TextEdit, ActionError>> applyPlan(
    ReplacementPlan plan, {
    bool blockOnPassword = false,
    bool showUndo = true,
    String undoLabel = UndoLabels.fallback,
  }) async {
    if (blockOnPassword) {
      final snap = await _bridge.getSurroundingText();
      if (snap == null) return const Result.err(ActionError.noConnection);
      if (snap.isPassword) {
        return const Result.err(ActionError.passwordBlocked);
      }
    }

    final outcome = await _bridge.replaceSurrounding(
      deleteBefore: plan.deleteBefore,
      deleteAfter: plan.deleteAfter,
      replacement: plan.replacement,
    );
    if (outcome == null) return const Result.err(ActionError.failed);

    final inverse = TextEdit(
      deleteBefore: outcome.insertedLength,
      deleteAfter: 0,
      insertedText: outcome.replacedText,
      replacedText: plan.replacement,
      selectionStart: outcome.previousSelectionStart,
      selectionEnd: outcome.previousSelectionEnd,
    );
    if (showUndo) {
      _undo.push(inverse);
      _undoTracker.markAvailable(label: undoLabel);
      await _bridge.actionHaptic();
      _showUndoPanel(undoLabel);
    } else {
      // Autocomplete / next-word — silent insert, keep typing.
      _cancelUndoTimer();
      _undo.clear();
      _undoTracker.clear();
      _onPanel?.call(const PanelIdle());
    }
    return Result.ok(inverse);
  }

  Future<Result<TextEdit, ActionError>> removeMat(PanelMat panel) async {
    final ctx = _lastContext;
    if (ctx == null) return const Result.err(ActionError.invalidRange);
    final plan = TextActions.removeMat(panel: panel, ctx: ctx);
    if (plan.isErr) return Result.err(plan.errorOrNull!);
    return applyPlan(plan.valueOrNull!, undoLabel: UndoLabels.matRemoved);
  }

  Future<Result<TextEdit, ActionError>> softenToxic(PanelToxic panel) async {
    final ctx = _lastContext;
    if (ctx == null) return const Result.err(ActionError.invalidRange);
    final plan = TextActions.softenToxic(panel: panel, ctx: ctx);
    if (plan.isErr) return Result.err(plan.errorOrNull!);
    return applyPlan(plan.valueOrNull!, undoLabel: UndoLabels.toxicSoftened);
  }

  Future<Result<TextEdit, ActionError>> expandShortcut(String expansion) async {
    final ctx = _lastContext;
    if (ctx == null) return const Result.err(ActionError.invalidRange);
    final plan = TextActions.expandShortcut(expansion: expansion, ctx: ctx);
    if (plan.isErr) return Result.err(plan.errorOrNull!);
    return applyPlan(
      plan.valueOrNull!,
      undoLabel: UndoLabels.shortcutExpanded,
    );
  }

  Future<Result<TextEdit, ActionError>> insertSuggestion(String word) async {
    final ctx = _lastContext;
    if (ctx == null) return const Result.err(ActionError.invalidRange);
    final plan = TextActions.insertSuggestion(word: word, ctx: ctx);
    if (plan.isErr) return Result.err(plan.errorOrNull!);
    return applyPlan(plan.valueOrNull!, showUndo: false);
  }

  Future<Result<TextEdit, ActionError>> improve() async {
    final snap = await _bridge.getSurroundingText();
    if (snap == null) return const Result.err(ActionError.noConnection);
    final plan = TextActions.improveMessage(
      before: snap.before,
      after: snap.after,
    );
    if (plan.isErr) return Result.err(plan.errorOrNull!);
    return applyPlan(
      plan.valueOrNull!,
      blockOnPassword: true,
      undoLabel: UndoLabels.improved,
    );
  }

  Future<Result<void, ActionError>> undo() async {
    _cancelUndoTimer();
    final edit = _undo.pop();
    if (edit == null) {
      _undoTracker.clear();
      _onPanel?.call(const PanelIdle());
      return const Result.err(ActionError.undoEmpty);
    }

    final outcome = await _bridge.replaceSurrounding(
      deleteBefore: edit.deleteBefore,
      deleteAfter: edit.deleteAfter,
      replacement: edit.insertedText,
    );
    if (outcome == null) {
      _undo.push(edit);
      return const Result.err(ActionError.failed);
    }

    await _bridge.setSelection(edit.selectionStart, edit.selectionEnd);

    if (_undo.isEmpty) {
      _undoTracker.clear();
      _onPanel?.call(const PanelIdle());
    } else {
      _showUndoPanel(_undoTracker.label);
    }
    await _bridge.actionHaptic();
    return const Result.ok(null);
  }

  void onFieldCleared() {
    _cancelUndoTimer();
    _undo.clear();
    _undoTracker.clear();
    _lastContext = null;
  }

  void dispose() {
    _cancelUndoTimer();
  }

  void _cancelUndoTimer() {
    _undoHideTimer?.cancel();
    _undoHideTimer = null;
  }

  void _onUndoWindowExpired() {
    _undoHideTimer = null;
    _undo.clear();
    _undoTracker.clear();
    _onPanel?.call(const PanelIdle());
  }

  void _showUndoPanel(String label) {
    _cancelUndoTimer();
    _onPanel?.call(PanelUndo(label: label));
    _undoHideTimer = Timer(
      const Duration(milliseconds: kUndoWindowMs),
      _onUndoWindowExpired,
    );
  }
}
