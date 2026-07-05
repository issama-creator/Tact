# TACT — Architecture

> Companion documents: [`PRODUCT.md`](PRODUCT.md) (vision) and [`RULES.md`](RULES.md) (panel/UX rules).
> This document describes *how* we build TACT. It answers "where does this code live and why".

## Guiding Principles

1. **Typing is the product.** The keypress path is native-only. Dart is never on the hot path.
2. **Two developers, five minutes.** Any module must be locatable in ≤5 minutes by grep on a feature name.
3. **Simple things stay simple.** Complexity is introduced only when justified by evidence, not by fear.
4. **Feature-first, single package.** Folders are the boundary. No premature multi-package split.
5. **Offline-first.** Everything that can work locally, does.
6. **AI is optional.** It is one folder (`keyboard/ai/`) with one file — deletable without breaking the keyboard.
7. **Prepared for iOS from day one.** Business logic is pure Dart. Only the IME shell and native key grid are per-platform.

## Layered View

```
┌────────────────────────────────────────────────────────────────┐
│ PLATFORM (thin)                                                  │
│  Android: InputMethodService + native KeyGridView (Canvas)       │
│  iOS (future): UIInputViewController + native KeyGridView (UIKit)│
└──────────────▲──────────────────────────────────────────────────┘
               │  Pigeon typed bridge (contract only)
┌──────────────┴──────────────────────────────────────────────────┐
│ PRESENTATION (Flutter, shared)                                    │
│  Suggestion bar, chips, settings, onboarding, stats, themes       │
└──────────────▲──────────────────────────────────────────────────┘
               │
┌──────────────┴──────────────────────────────────────────────────┐
│ APPLICATION (pure Dart, shared)                                   │
│  KeyboardStateMachine · InputPipeline · PanelState · text actions │
└──────────────▲──────────────────────────────────────────────────┘
               │
┌──────────────┴──────────────────────────────────────────────────┐
│ DOMAIN + DATA (pure Dart, shared)                                 │
│  RulesEngine · SignalProviders (Spell/Mat/Toxic/Shortcut/Improve) │
│  Dictionaries · Lexicons · AiService · Repositories               │
└──────────────────────────────────────────────────────────────────┘
```

The dependency rule points inward. `keyboard/state`, `keyboard/panel`, `keyboard/rules`, `keyboard/engines`, `keyboard/input`, `keyboard/actions`, `keyboard/dictionaries` are **pure Dart** — no Flutter, no plugins. Enforced by folder discipline and code review (see `analysis_options.yaml`).

## The Split That Defines TACT

- **Key grid rendering + touch** — **native** per platform, driven by a shared JSON layout spec. Sub-frame latency. No Dart on the keypress path.
- **Suggestion bar & chips** — **Flutter**. Not on the microsecond-critical path; shared across platforms.
- **All engines, rules, state, actions, storage, AI** — **shared pure Dart**.

Result: >80% shared code, Gboard-class typing latency.

## Two Core Abstractions

### 1. Keyboard State Machine (`lib/keyboard/state/`)

Explicit sealed states: `Idle → Typing → WordCompleted → ShowingSuggestion → RunningAI → …`. Parallel `UndoRegion`. **`RunningAI` is reachable only through explicit tap events** — enforced by the transition function, not by convention.

### 2. Rules Engine + Panel State (`lib/keyboard/rules/` + `lib/keyboard/panel/`)

- Engines emit `RuleSignal`s. They don't know about the panel.
- `RulesEngine` collects signals and produces a `PanelDecision` in priority order:
  `SpellError → Mat → Toxic → Improve → NextWord`.
- `PanelState` owns the live panel (currently visible slots, dismiss, hover). It is separate from `KeyboardState`.

See [`RULES.md`](RULES.md) for priority tables, budgets, and hysteresis.

## Concurrency Model (MVP)

- **UI isolate**: renders the suggestion bar. Never runs engines.
- **Native (main) thread**: renders keys, handles touches, owns InputConnection.
- **Engines run on the UI isolate synchronously.** HashSet/HashMap/trie lookups are microsecond-scale — a dedicated isolate is **not** justified at this stage.
- When (and if) an engine begins to cost more than a frame budget under real load, we add a background isolate then, and only for that engine.

Bridge calls between native and Dart happen **only at word boundaries** and on **explicit action taps**, never per keystroke.

## Repository Map

```
docs/                        # This doc, PRODUCT.md, RULES.md
pigeons/ime_bridge.dart      # Typed Kotlin/Swift <-> Dart contract
assets/
  dictionaries/              # Binary FST + hashset per language
  lexicons/                  # Toxic + mat hashsets per language
  shortcuts/builtin.json     # "thx" -> "Thanks", etc.
  layouts/*.json             # Key layout spec (shared across platforms)

lib/
  main.dart                  # Companion app entrypoint
  ime_main.dart              # IME Flutter entrypoint (suggestion bar only)

  core/
    result.dart              # Result<T,E>
    logger.dart              # leveled logger
    statistics.dart          # WPM / accepted fixes / softenings sink
    kv_store.dart            # thin shared_preferences wrapper
    bridge/
      ime_bridge.g.dart      # Pigeon-generated (do not edit)
      ime_bridge_facade.dart # Dart-side API on top of the generated stub

  keyboard/
    keyboard_app.dart        # Suggestion bar root + composition root
    state/
      keyboard_state.dart          # sealed states + events
      keyboard_state_machine.dart  # transitions, guards
    panel/
      panel_state.dart             # PanelState + PanelSlot + PanelDecision
    input/
      text_context.dart
      input_pipeline.dart          # word boundary handler
    rules/
      rule_signal.dart             # RuleSignal + SignalKind
      rules_engine.dart            # priority evaluation -> PanelDecision
    engines/
      signal_provider.dart         # interface
      normalizer.dart              # lowercase / deleet / strip
      spell_engine.dart
      toxic_engine.dart
      mat_engine.dart
      shortcut_engine.dart
      improve_engine.dart
    dictionaries/
      dictionary.dart              # FST + hashset facade
      dictionary_loader.dart       # lazy per-language mmap
      lexicon_loader.dart          # toxic / mat hashset loader
    actions/
      text_actions.dart            # Fix / Improve / Soften (three tiny classes)
      undo_stack.dart              # bounded reversible edits
    ai/
      ai_service.dart              # ONE file: interface + HTTP client + DTOs
    theme/
      keyboard_theme.dart          # tokens, exported to native
      key_layout.dart              # layout JSON parser
    ui/
      suggestion_bar.dart          # bar + slot chips
      suggestion_controller.dart   # Riverpod notifier (state -> slots)

  companion/                       # Settings app (opened from launcher)
    companion_app.dart
    onboarding/onboarding.dart
    settings/{settings, settings_repository, settings_screen}.dart
    shortcuts/{shortcut, shortcuts_repository, shortcuts_screen}.dart
    stats/{stats_repository, stats_screen}.dart
    themes/themes.dart

  l10n/
    app_en.arb
    app_ru.arb
    l10n.yaml

android/app/src/main/
  res/xml/method.xml                     # IME declaration
  kotlin/com/example/tact/ime/
    TactInputMethodService.kt            # IME shell, InputConnection owner
    KeyGridView.kt                       # native Canvas keys + touch
    FlutterEngineHost.kt                 # warm cached FlutterEngine
    ImeBridgeImpl.kt                     # Pigeon host implementation

ios/                                     # Scaffold only. Future extension.

test/
  rules_engine_test.dart                 # signal -> decision golden tables
  keyboard_state_machine_test.dart       # transition table + AI-manual invariant
  panel_state_test.dart                  # dismiss, hysteresis, slot budget
  spell_engine_test.dart
  shortcut_engine_test.dart
  input_pipeline_test.dart
  undo_stack_test.dart
```

## What We Deliberately Did Not Build (Yet)

- No **background isolate** for engines. HashSet/HashMap are fast enough. Revisit under evidence.
- No **feature flags** framework. Add when we run our first A/B test.
- No **analytics/telemetry** framework. Only user-facing `Statistics` (WPM, accepted fixes, softenings). Add crash/perf reporting when we have real users.
- No **DI framework**. `keyboard_app.dart` and `companion_app.dart` are the composition roots.
- No **plugin system, marketplace, community**. See `PRODUCT.md` non-goals.

Each of these has a natural insertion point in the folder tree if/when it becomes justified.

## Extension Points (10-year friendliness)

- **New language** → add `assets/dictionaries/<lang>.bin`, `assets/lexicons/*_<lang>.bin`, a layout JSON, and ARB entries.
- **New engine** → add a file under `keyboard/engines/` implementing `SignalProvider`, register in `keyboard_app.dart`. `RulesEngine` needs one new priority entry.
- **New action chip** (beyond Fix/Improve/Soften) → add a class in `text_actions.dart` + a new `RuleSignal` kind or panel slot type.
- **iOS** → mirror the four Kotlin files with four Swift files. Nothing above the bridge changes.
- **Cloud sync** → add a `sync_repository.dart` alongside `settings_repository.dart` / `shortcuts_repository.dart`. Storage abstractions are already local-first.

## Golden Invariants

These are architectural laws. Breaking any of them is a bug even if the code compiles.

1. **The keypress path never enters Dart.** Native → InputConnection → target app. Word boundaries only cross the bridge.
2. **`RunningAI` state is entered only via explicit tap events.** Enforced in the transition table.
3. **Words <3 characters are never analyzed.** Enforced at `InputPipeline`.
4. **TACT never auto-mutates user text.** Every mutation is a proposed edit, applied only on Apply.
5. **`keyboard/state`, `keyboard/panel`, `keyboard/rules`, `keyboard/engines`, `keyboard/input`, `keyboard/dictionaries`, `keyboard/actions` never import Flutter.**

Golden tests in `test/` guard these where possible.
