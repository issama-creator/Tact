// pigeons/ime_bridge.dart
//
// TACT bridge contract (source of truth for Kotlin/Swift <-> Dart calls).
//
// This file is the Pigeon schema. It is NOT imported by app code.
// Running Pigeon generates:
//   lib/core/bridge/ime_bridge.g.dart   (Dart)
//   android/app/src/main/kotlin/.../ImeBridgeGenerated.kt (Kotlin host)
//   ios/.../ImeBridgeGenerated.swift    (Swift host)  -- future
//
// Rules:
//   • DTOs only. No behavior.
//   • Every call must be justified: either a word-boundary event or a user action.
//     Per-keystroke traffic across the bridge is FORBIDDEN.
//
// -----------------------------------------------------------------------------
// Intended surface (to be encoded as @HostApi / @FlutterApi when we add the
// `pigeon` dev dependency and run the generator):
//
// ── Host side (implemented in native) ────────────────────────────────────────
//   ImeHost {
//     void commitText(String text);
//     void deleteSurrounding(int before, int after);
//     void replaceRange(int start, int end, String replacement);
//     void setComposingText(String text);
//     void finishComposing();
//     TextSnapshot getSurroundingText(int beforeChars, int afterChars);
//     void applyTheme(KeyboardThemeDto theme);        // colors, densities
//     void applyLayout(KeyboardLayoutDto layout);     // key spec (JSON parsed on Dart side)
//   }
//
// ── Flutter side (implemented in Dart) ───────────────────────────────────────
//   ImeFlutter {
//     void onStartInputView(InputContextDto ctx);
//     void onFinishInputView();
//     void onWordCommitted(WordEventDto ev);          // ONLY at word boundaries
//     void onSelectionChanged(SelectionDto sel);
//     void onActionTapped(ActionKind kind);           // Fix / Improve / Soften / Remove / Undo
//     void onPanelSlotTapped(int slotIndex);
//   }
//
// ── DTOs ────────────────────────────────────────────────────────────────────
//   TextSnapshot { String before; String after; }
//   WordEventDto { String word; String beforeCtx; String afterCtx; int rangeStart; int rangeEnd; String locale; }
//   SelectionDto { int start; int end; }
//   InputContextDto { String packageName; int inputType; String locale; }
//   KeyboardThemeDto { int background; int keyBackground; int keyText; int accent; double keyRadius; }
//   KeyboardLayoutDto { String id; String rawJson; }  // parsed on Dart side
//   enum ActionKind { fix, improve, soften, remove, undo }
//
// -----------------------------------------------------------------------------
// TODO: When we add `pigeon` to dev_dependencies, replace this comment block
// with the real annotated classes and run `dart run pigeon --input pigeons/ime_bridge.dart`.
library;
