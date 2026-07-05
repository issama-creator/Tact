package com.example.tact.ime

import android.inputmethodservice.InputMethodService
import android.text.InputType
import android.text.TextUtils
import android.view.KeyEvent
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection

/**
 * A very thin, allocation-conscious wrapper around [InputConnection] and
 * [InputMethodService] calls performed on the typing hot path.
 *
 * Design rules:
 *   • Every method is defensive against a null InputConnection (returned
 *     by the platform between input sessions).
 *   • Nothing here allocates on typical calls.
 *   • Word-boundary detection lives here (not in the state machine)
 *     because it needs the InputConnection to look at the surrounding
 *     text.
 *
 * This class is deliberately kept small: the whole point is that the
 * shortest possible native call chain runs on every keystroke.
 */
class InputController(private val ime: InputMethodService) {

    /** Cached at [restart] and consulted for enter-key behavior. */
    var editorInfo: EditorInfo? = null
        private set

    /** True while the current field is a password. Used to disable learning
     *  and clipboard suggestions (moot for now, wired for future features). */
    var isPasswordField: Boolean = false
        private set

    /** True when the field accepts multiple lines (Enter inserts newline). */
    var isMultiLineField: Boolean = false
        private set

    // ── Lifecycle ─────────────────────────────────────────────────────

    fun restart(info: EditorInfo?) {
        editorInfo = info
        isPasswordField = info?.let {
            val cls = it.inputType and android.text.InputType.TYPE_MASK_CLASS
            val variation = it.inputType and android.text.InputType.TYPE_MASK_VARIATION
            when (cls) {
                android.text.InputType.TYPE_CLASS_TEXT -> variation ==
                    android.text.InputType.TYPE_TEXT_VARIATION_PASSWORD ||
                    variation == android.text.InputType.TYPE_TEXT_VARIATION_WEB_PASSWORD ||
                    variation == android.text.InputType.TYPE_TEXT_VARIATION_VISIBLE_PASSWORD
                android.text.InputType.TYPE_CLASS_NUMBER -> variation ==
                    android.text.InputType.TYPE_NUMBER_VARIATION_PASSWORD
                else -> false
            }
        } ?: false

        isMultiLineField = info?.let {
            (it.inputType and InputType.TYPE_TEXT_FLAG_MULTI_LINE) != 0
        } ?: false
    }

    fun finish() {
        editorInfo = null
    }

    // ── Text mutations ────────────────────────────────────────────────

    fun commitChar(char: CharSequence) {
        val ic = ime.currentInputConnection ?: return
        ic.commitText(char, 1)
    }

    fun commitText(text: CharSequence) {
        val ic = ime.currentInputConnection ?: return
        ic.commitText(text, 1)
    }

    fun deleteBackward() {
        val ic = ime.currentInputConnection ?: return
        val selectedLength = getSelectionLength(ic)
        if (selectedLength > 0) {
            ic.commitText("", 1)
        } else {
            ic.deleteSurroundingText(1, 0)
        }
    }

    /**
     * Delete backward one word (repeated backspace held long). Uses a
     * simple whitespace-then-nonwhitespace scan on the text before the
     * cursor.
     */
    fun deleteBackwardWord() {
        val ic = ime.currentInputConnection ?: return
        val before = ic.getTextBeforeCursor(64, 0)?.toString() ?: return
        if (before.isEmpty()) return

        var i = before.length
        // Trailing whitespace.
        while (i > 0 && before[i - 1].isWhitespace()) i--
        // The word itself.
        while (i > 0 && !before[i - 1].isWhitespace()) i--
        val toDelete = before.length - i
        if (toDelete > 0) {
            ic.deleteSurroundingText(toDelete, 0)
        } else {
            ic.deleteSurroundingText(1, 0)
        }
    }

    /**
     * Insert space. The IME service’s [InputConnection] handles caret
     * placement (the underlying editor may adjust).
     */
    fun commitSpace() {
        val ic = ime.currentInputConnection ?: return
        ic.commitText(" ", 1)
    }

    /**
     * Resolved IME action for the enter key label and [performEnter].
     * Mirrors [InputMethodService.sendDefaultEditorAction] logic.
     */
    fun effectiveImeAction(): Int? {
        val info = editorInfo ?: return null
        if (info.imeOptions and EditorInfo.IME_FLAG_NO_ENTER_ACTION != 0) return null
        var action = info.imeOptions and EditorInfo.IME_MASK_ACTION
        if (action == EditorInfo.IME_ACTION_UNSPECIFIED) {
            action = defaultActionFor(info)
        }
        if (action == EditorInfo.IME_ACTION_NONE) return null
        return action
    }

    /**
     * Contextual enter: Send in chat, Search in browser, Done in forms, etc.
     * Uses the platform default action resolver first (same as Gboard).
     */
    fun performEnter() {
        val ic = ime.currentInputConnection ?: return

        if (ime.sendDefaultEditorAction(true)) return

        // Fallback when the service helper declines but we resolved an action.
        val action = effectiveImeAction()
        if (action != null && ic.performEditorAction(action)) return

        if (isMultiLineField) {
            ic.commitText("\n", 1)
            return
        }
        sendDownUpKeyEvent(KeyEvent.KEYCODE_ENTER)
    }

    // ── Cursor & selection ────────────────────────────────────────────

    fun moveCursorBy(delta: Int) {
        if (delta == 0) return
        val ic = ime.currentInputConnection ?: return
        val info = ic.getExtractedText(android.view.inputmethod.ExtractedTextRequest(), 0) ?: return
        val text = info.text ?: return
        val currentEnd = info.selectionEnd
        if (currentEnd < 0) return
        val length = text.length
        val target = (currentEnd + delta).coerceIn(0, length)
        if (target == currentEnd && target == info.selectionStart) return
        ic.setSelection(target, target)
    }

    fun setSelection(start: Int, end: Int) {
        val ic = ime.currentInputConnection ?: return
        ic.setSelection(start, end)
    }

    // ── Word-boundary helpers (for future engines) ────────────────────

    /**
     * If the character just committed is a word terminator (space, punct),
     * returns the word that ended immediately before it — or null if no
     * word ended here. Used later by the InputPipeline for engine dispatch.
     */
    fun lastCompletedWord(justCommitted: CharSequence): String? {
        val ch = justCommitted.firstOrNull() ?: return null
        if (!isWordBoundary(ch)) return null
        val ic = ime.currentInputConnection ?: return null
        // Grab enough characters to safely capture a whole word.
        val before = ic.getTextBeforeCursor(96, 0)?.toString() ?: return null
        // The just-committed boundary char is included at the end; skip it.
        val end = before.length - 1
        if (end <= 0) return null
        var start = end
        while (start > 0 && !isWordBoundary(before[start - 1])) start--
        if (end - start < 3) return null
        return before.substring(start, end)
    }

    private fun isWordBoundary(ch: Char): Boolean =
        ch.isWhitespace() || ch == '.' || ch == ',' || ch == '!' || ch == '?' ||
            ch == ';' || ch == ':' || ch == '\n' || ch == '\t'

    // ── Utilities ─────────────────────────────────────────────────────

    private fun defaultActionFor(info: EditorInfo): Int {
        if ((info.inputType and InputType.TYPE_TEXT_FLAG_MULTI_LINE) != 0) {
            return EditorInfo.IME_ACTION_NONE
        }
        val variation = info.inputType and InputType.TYPE_MASK_VARIATION
        return when (variation) {
            InputType.TYPE_TEXT_VARIATION_URI,
            InputType.TYPE_TEXT_VARIATION_EMAIL_ADDRESS ->
                EditorInfo.IME_ACTION_GO
            else -> EditorInfo.IME_ACTION_DONE
        }
    }

    private fun getSelectionLength(ic: InputConnection): Int {
        val selected = ic.getSelectedText(0) ?: return 0
        return if (TextUtils.isEmpty(selected)) 0 else selected.length
    }

    private fun sendDownUpKeyEvent(keyCode: Int) {
        val ic = ime.currentInputConnection ?: return
        val eventTime = SystemClockAdapter.uptime()
        val flags = KeyEvent.FLAG_SOFT_KEYBOARD or KeyEvent.FLAG_KEEP_TOUCH_MODE
        val deviceId = android.view.KeyCharacterMap.VIRTUAL_KEYBOARD
        ic.sendKeyEvent(
            KeyEvent(
                eventTime, eventTime,
                KeyEvent.ACTION_DOWN, keyCode, 0, 0,
                deviceId, 0,
                flags,
            ),
        )
        ic.sendKeyEvent(
            KeyEvent(
                eventTime, eventTime,
                KeyEvent.ACTION_UP, keyCode, 0, 0,
                deviceId, 0,
                flags,
            ),
        )
    }
}

/** Small indirection so tests can override the clock if needed later. */
internal object SystemClockAdapter {
    fun uptime(): Long = android.os.SystemClock.uptimeMillis()
}
