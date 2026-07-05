// lib/keyboard/actions/text_actions.dart
//
// User-invoked text actions: Fix / Improve / Soften / Remove.
//
// All three (four including Remove) share the same shape — they:
//   1. Are triggered ONLY by an explicit chip tap (KbEvent.ActionTapped).
//   2. Read the current sentence / selection from ImeBridge.
//   3. Call AiService (except Remove, which is local: strips mat word +
//      trailing whitespace and proposes the edit).
//   4. Produce a TextEdit as a "proposed edit".
//   5. On user confirmation → commit via ImeBridge.replaceRange and push the
//      inverse edit onto UndoStack.
//
// Contents (planned):
//   • class TextEdit { final int start; final int end; final String replacement; }
//   • abstract class TextAction { Future<Result<TextEdit, ActionError>> run(TextContext ctx); }
//   • class FixAction     implements TextAction   // uses AiService.fix
//   • class ImproveAction implements TextAction   // uses AiService.improve
//   • class SoftenAction  implements TextAction   // uses AiService.soften
//   • class RemoveAction  implements TextAction   // LOCAL — no AI
//
// Depends on: ai/ai_service.dart, input/text_context.dart, actions/undo_stack.dart, core/result.dart.
// Must NOT: import Flutter or plugins.
//
// TODO: implement.
library;
