package com.example.tact.ime

/**
 * Data model for a keyboard layout.
 *
 * A layout is a stack of rows. Each row is a horizontal list of keys with
 * relative widths. All rendering and touch handling in [KeyGridView] is
 * driven purely by these immutable data structures — no reflection, no
 * per-key subclasses, no allocations on the hot path.
 */

enum class LayerKind {
    ALPHA,
    SYMBOLS,
    SYMBOLS_ALT,
    NUMBERS,
}

enum class ShiftState {
    OFF,
    ON,
    LOCKED,
}

enum class LanguageKind(val tag: String, val label: String) {
    EN("en", "English"),
    RU("ru", "Русский"),
}

/**
 * What happens when a key is activated.
 *
 * Kept as a sealed hierarchy so the [KeyGridView] can pattern-match on
 * key actions with no branch tables and no downcasts.
 */
sealed class KeyAction {

    /** Insert a character. [label] is the primary glyph. */
    data class Character(
        val label: String,
        val labelUpper: String? = null,
    ) : KeyAction()

    /** Toggle shift (double-tap → caps lock). */
    object Shift : KeyAction()

    /** Delete-backward. Long press repeats and eventually deletes by word. */
    object Backspace : KeyAction()

    /** Space bar. Long-press swaps language. Horizontal slide moves the cursor. */
    object Space : KeyAction()

    /** Contextual "enter" — behavior depends on EditorInfo imeOptions. */
    object Enter : KeyAction()

    /** Explicitly switch to another language (globe key when >1 enabled). */
    object LanguageSwitch : KeyAction()

    /** Move to another layer (letters ↔ symbols ↔ symbols-alt ↔ numbers). */
    data class LayerSwitch(val target: LayerKind) : KeyAction()

    /** Emoji key. Emoji panel itself is out of scope; the action exists so
     *  the layout looks like a real keyboard. Behavior: no-op for MVP. */
    object Emoji : KeyAction()

    /** Comma / period / etc. — a character with a specific role. Not used for
     *  branching in the current MVP; the label carries the character. */
}

/**
 * One key in a row.
 *
 * @property weight relative width in a row. Sum of weights in a row is
 *   distributed across the row's usable width (after gaps).
 * @property longPress the primary glyph produced by a long press. If empty,
 *   the standard behavior for the [action] applies (e.g. repeat for
 *   backspace, language switch for space).
 * @property longPressAlternatives extra glyphs shown in a small popup on a
 *   sustained press, above the key. The user can slide horizontally to
 *   choose. When empty, [longPress] alone is used (if present).
 * @property subLabel a small annotation drawn top-right of the key (e.g.
 *   a digit sitting on top of the first alpha row).
 */
data class Key(
    val action: KeyAction,
    val weight: Float = 1f,
    val longPress: String? = null,
    val longPressAlternatives: List<String> = emptyList(),
    val subLabel: String? = null,
)

/** A horizontal row of keys with an optional height weight (default 1). */
data class KeyRow(
    val keys: List<Key>,
    val heightWeight: Float = 1f,
)

/**
 * A full layer of a layout — one screenful of keys shown at a time.
 *
 * The rendering pipeline never mutates a layer; changing which layer is
 * displayed is a pointer swap on [KeyboardState].
 */
data class KeyboardLayer(
    val id: String,
    val language: LanguageKind,
    val kind: LayerKind,
    val rows: List<KeyRow>,
)
