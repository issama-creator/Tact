// test/keyboard_state_machine_test.dart
//
// Transition-table tests for KeyboardStateMachine.
//
// The critical invariants that MUST pass:
//   1. RunningAI is reachable ONLY through KbEvent.ActionTapped.
//      For every other event, from every other state, next() must NOT
//      produce a RunningAI.
//   2. WordBoundary with word.length < 3 does not leave Typing.
//   3. Keypress while in ShowingSuggestion or RunningAI returns to Typing.
//   4. Detach / Blur always terminates in Idle regardless of prior state.
//   5. Undo edits update the UndoRegion but never change the primary state.
//
// Style:
//   • Enumerate every (state × event) cell and assert the expected next state.
//
// TODO: implement.
library;
