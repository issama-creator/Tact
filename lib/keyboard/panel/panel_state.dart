// lib/keyboard/panel/panel_state.dart
//
// PanelState — the live state of the suggestion panel.
//
// The panel is the heart of TACT's UX. It is a domain distinct from
// KeyboardState: the keyboard can be in `Typing` while the panel is
// `Showing[SpellError, NextWord, NextWord]`.
//
// This module owns:
//   • PanelSlot        — one entry on the panel.
//   • PanelDecision    — the RulesEngine's output for the current context.
//   • PanelState       — the currently visible panel + hysteresis / dismiss.
//
// Slot kinds (in priority order — see docs/RULES.md):
//   1. spellError → chip "📝 Mistake found"      button [Fix]
//   2. mat        → chip "⚠ Profanity detected"  button [Remove]
//   3. toxic      → chip "⚠ Possible conflict"   button [Soften]
//   4. improve    → chip "✨ Improve text"       button [Improve]
//   5. nextWord   → normal word candidate         (tap inserts)
//   +  undo       → chip "↶ Undo"                overlay when UndoAvailable
//
// Contents (planned):
//   • sealed class PanelSlot with subclasses (spellError, mat, toxic, improve, nextWord, undo).
//   • class PanelDecision  { List<PanelSlot> slots; DateTime producedAt; }
//   • class PanelState     { List<PanelSlot> visible; bool dismissedByUser; }
//   • PanelState reduce(PanelState prev, PanelDecision next, PanelSettings s)
//         — applies hysteresis (anti-flicker) and slot budget.
//
// Depends on: rules/rule_signal.dart (for SignalKind types referenced in slots).
// Must NOT: import Flutter or plugins. Pure data + a pure reducer.
//
// TODO: implement.
library;
