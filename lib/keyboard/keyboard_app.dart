// lib/keyboard/keyboard_app.dart
//
// Composition root + root widget for the IME suggestion bar.
//
// Purpose:
//   Wires the small graph of objects that make TACT tick:
//     ImeBridge  →  InputPipeline  →  engines[]  →  RulesEngine  →  PanelState
//                                                                       ↓
//                                                    SuggestionController → SuggestionBar
//
//   Also owns lifecycle: attaches to IME start/stop events from the bridge,
//   lazy-loads dictionaries via DictionaryLoader on first use of a language.
//
// Notes:
//   • No DI framework. This file IS the DI.
//   • Everything created here is scoped to the IME's Flutter engine lifetime.
//   • Kept small — anything bigger than wiring belongs in the owned module.
//
// Depends on: everything under keyboard/*.
// Must NOT: contain business logic. Wiring only.
//
// TODO: implement.
library;
