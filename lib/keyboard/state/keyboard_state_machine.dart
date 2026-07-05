// lib/keyboard/state/keyboard_state_machine.dart
//
// The keyboard state machine — a pure transition function.
//
// Purpose:
//   Single source of truth for "what mode is the keyboard in right now".
//   The panel, the UI and the action pipeline all read this stream.
//
// Contract:
//   • KeyboardState next(KeyboardState current, KbEvent event)   — pure.
//   • Stream<KeyboardState> get states                            — hot stream.
//
// Golden invariants enforced by the transition table (see test/):
//   1. RunningAI can be entered ONLY via KbEvent.ActionTapped.
//      No other event can produce a transition into RunningAI.
//   2. WordBoundary is ignored if TextContext.word.length < 3.
//   3. Any Keypress while in ShowingSuggestion / RunningAI cancels
//      pending engines and pending AI, returning to Typing.
//   4. Detach / Blur always leads to Idle (aborting AI if any).
//
// Contents (planned):
//   • class KeyboardStateMachine
//       - final StreamController<KeyboardState> _out;
//       - void dispatch(KbEvent event);
//       - Stream<KeyboardState> get states;
//   • Transition table encoded as a private pure function.
//
// Depends on: state/keyboard_state.dart.
// Must NOT: import Flutter, plugins, or perform side effects.
//   Side effects (commit text, call AI) are performed by callers subscribed
//   to `states` and `events`.
//
// TODO: implement.
library;
