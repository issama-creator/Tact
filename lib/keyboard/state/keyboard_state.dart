// lib/keyboard/state/keyboard_state.dart
//
// KeyboardState + KbEvent — the sealed data types of the keyboard state machine.
//
// STATES:
//   • Idle              — keyboard not shown.
//   • Typing            — user is typing; no completed word yet.
//   • WordCompleted     — a word boundary was just crossed; engines running.
//   • ShowingSuggestion — panel has one or more slots; user may tap or keep typing.
//   • RunningAI         — an AI action is in flight (Fix / Improve / Soften / Remove).
//
// PARALLEL REGIONS (orthogonal):
//   • UndoRegion { empty | available } — reversible edits exist.
//   • Modifiers  { lower | shift | caps | symbols | langA | langB }.
//
// EVENTS (KbEvent):
//   • Attach(InputContext)          — IME started (onStartInputView).
//   • Detach()                      — IME finished.
//   • Keypress                      — a keystroke happened (native told us).
//   • WordBoundary(TextContext)     — a completed word crossed the boundary.
//   • Signals(RuleSignal[])         — engines produced signals.
//   • PanelDecided(PanelDecision)   — RulesEngine produced a decision.
//   • ActionTapped(ActionKind)      — the user tapped a chip.
//   • EditProposed(TextEdit)        — AI or engine proposed an edit.
//   • EditApplied(TextEdit)         — proposed edit was confirmed & committed.
//   • Undo()                        — user requested undo.
//   • Blur()                        — focus lost.
//
// Contents (planned):
//   • sealed class KeyboardState with subclasses above.
//   • sealed class KbEvent with subclasses above.
//   • enum ActionKind { fix, improve, soften, remove, undo }
//
// Depends on: rules/rule_signal.dart, panel/panel_state.dart, input/text_context.dart.
// Must NOT: import Flutter or plugins.
//
// TODO: implement.
library;
