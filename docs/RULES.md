# TACT — Panel & UX Rules

> Companion documents: [`PRODUCT.md`](PRODUCT.md) (vision) and [`ARCHITECTURE.md`](ARCHITECTURE.md) (system design).
> This document is the source of truth for **what the panel shows and when**. It is deliberately short so it stays true.

## What the Panel Is

The suggestion panel is a horizontal bar above the keys with **N slots** (default `N = 3`). Each slot displays one of:

- A next-word / correction suggestion (like Gboard).
- An **action hint** with a single primary button: `Fix`, `Soften`, `Remove`, `Improve`.

The panel is **advisory**. It never rewrites text on its own.

## Signal Priority (highest first)

The Rules Engine collects `RuleSignal`s from all engines for the currently completed word (and current message) and fills slots top-down by priority.

| Priority | Signal            | Emitted by         | UI                       | Button    |
|---------:|-------------------|--------------------|--------------------------|-----------|
|      1   | `SpellError`      | `spell_engine`     | 📝 Mistake found         | `Fix`     |
|      2   | `Mat` (profanity) | `mat_engine`       | ⚠ Profanity detected    | `Remove`  |
|      3   | `Toxic`           | `toxic_engine`     | ⚠ Possible conflict     | `Soften`  |
|      4   | `Improve`         | `improve_engine`   | ✨ Improve text          | `Improve` |
|      5   | `NextWord`        | dictionary         | word candidate           | (tap)     |

Rules Engine guarantees:

- **Deduplication.** If `Mat` and `Toxic` fire on the same range, only the higher-priority slot is shown.
- **Slot budget.** Never more than `N` slots. If action signals + next-word candidates exceed `N`, next-word candidates are dropped first.
- **Hysteresis (anti-flicker).** A slot stays visible for at least a small window; a new signal must exceed the previous by a threshold to replace it.
- **Passive.** Slots for `Mat`/`Toxic`/`Improve` are hints, not blocks. `Fix`/`Improve`/`Soften`/`Remove` mutate text **only after the user taps**.

## When Signals Fire

### `SpellError`
- Only on **completed** words (word boundary reached).
- Word length ≥ 3 characters.
- Word is not in the active dictionary **and** the personal dictionary.
- Bounded Damerau-Levenshtein search yields at least one candidate.

### `Mat` (profanity)
- On completed words, length ≥ 3.
- Word (after normalization: lowercase, leetspeak fold, diacritics strip) is in the language-specific mat lexicon.

### `Toxic`
- On completed words, length ≥ 3.
- Word (normalized) is in the toxic lexicon.

### `Improve`
- Current message length ≳ **30 characters**.
- No `SpellError`, `Mat`, or `Toxic` signals present.
- Debounced — recomputed at most a few times per second while typing.

### `NextWord`
- Continuous. Ranked by dictionary + light context.

## AI Actions (`Fix` / `Improve` / `Soften`)

- Triggered **only** by an explicit tap on the corresponding chip.
- The keyboard state machine enters `RunningAI` on tap. This is the **only** entry to that state.
- Result is a **proposed edit**. It is not applied until the user confirms.
- Applied edits become one entry on `UndoStack` (fully reversible).
- Offline / no `AiService` available → the chip is greyed out / hidden. Nothing else changes.

## Never Rules

The panel and its rules **never**:

- block, delay, or slow typing;
- rewrite text automatically;
- censor text;
- surprise the user with a modal or a toast;
- run AI without an explicit tap;
- react to words shorter than 3 characters;
- fire on incomplete (currently-typing) words.

## Localization Notes

- Lexicons and dictionaries are per-language. The active locale determines which engines fire.
- Copy for hints (`📝 Mistake found`, `⚠ Profanity detected`, `⚠ Possible conflict`, `✨ Improve text`) lives in `lib/l10n/*.arb`.

## Tunables (defaults)

| Tunable                             | Default |
|-------------------------------------|---------|
| Panel slot budget                   | 3       |
| Minimum word length for engines     | 3       |
| Improve threshold (message length)  | 30      |
| Spell edit-distance max             | 2       |
| Hysteresis window                   | ~200 ms |

Tunables live in constants near their usage until we have a reason to expose them (e.g., A/B tests).
