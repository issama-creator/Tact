// lib/keyboard/ui/suggestion_controller.dart
//
// SuggestionController — Riverpod notifier that bridges KeyboardState /
// PanelState to the SuggestionBar widget.
//
// Purpose:
//   • Subscribes to KeyboardStateMachine.states.
//   • Applies the PanelState reducer as PanelDecisions arrive.
//   • Exposes a `List<PanelSlot>` for the bar to render.
//   • Emits intents back to the machine when the user taps a slot
//     (KbEvent.ActionTapped, KbEvent.PanelSlotTapped).
//
// Kept intentionally thin — no business logic. The rules are in
// keyboard/rules and keyboard/panel.
//
// Contents (planned):
//   • class SuggestionController extends Notifier<PanelState> { ... }
//   • Provider wiring (Riverpod) — added when flutter_riverpod is a dep.
//
// Depends on: keyboard/state/*, keyboard/panel/panel_state.dart.
// Must NOT: touch AiService directly. Actions are dispatched via events to
//   the state machine; text_actions.dart performs the effects.
//
// TODO: implement.
library;
