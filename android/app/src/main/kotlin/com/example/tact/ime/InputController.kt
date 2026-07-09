package com.example.tact.ime

import android.inputmethodservice.InputMethodService
import android.text.InputType
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

    /** Tracks characters committed through this IME when [InputConnection]
     *  does not expose surrounding text (Chrome, Google Search, etc.). */
    private val commitBuffer = StringBuilder(512)

    /** Reused for [getExtractedText] — avoids per-call allocation. */
    private val extractedRequest = android.view.inputmethod.ExtractedTextRequest()

    /** Cached from [onSelectionChanged] — avoids [getSelectedText] IPC per backspace. */
    private var cachedSelStart = -1
    private var cachedSelEnd = -1

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
        commitBuffer.setLength(0)
        cachedSelStart = -1
        cachedSelEnd = -1
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
        commitBuffer.setLength(0)
        cachedSelStart = -1
        cachedSelEnd = -1
        editorInfo = null
    }

    /** Called from [TactInputMethodService.onUpdateSelection]. */
    fun onSelectionChanged(start: Int, end: Int) {
        cachedSelStart = start
        cachedSelEnd = end
    }

    // ── Text mutations ────────────────────────────────────────────────

    fun commitChar(char: CharSequence) = commitText(char)

    fun commitText(text: CharSequence) {
        val ic = ime.currentInputConnection ?: return
        ic.commitText(text, 1)
        trackCommitted(text)
        if (cachedSelStart >= 0) {
            cachedSelStart += text.length
            cachedSelEnd = cachedSelStart
        }
    }

    private fun trackCommitted(text: CharSequence) {
        commitBuffer.append(text)
        if (commitBuffer.length > 512) {
            commitBuffer.delete(0, commitBuffer.length - 384)
        }
    }

    private fun trackDeleted(count: Int) {
        if (count <= 0 || commitBuffer.isEmpty()) return
        val keep = (commitBuffer.length - count).coerceAtLeast(0)
        commitBuffer.setLength(keep)
    }

    fun deleteBackward() {
        val ic = ime.currentInputConnection ?: return
        val selectedLength = cachedSelectionLength()
        if (selectedLength > 0) {
            ic.commitText("", 1)
            trackDeleted(selectedLength.coerceAtMost(commitBuffer.length))
            cachedSelEnd = cachedSelStart
        } else {
            ic.deleteSurroundingText(1, 0)
            trackDeleted(1)
            if (cachedSelEnd > 0) {
                cachedSelStart--
                cachedSelEnd--
            }
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
            trackDeleted(toDelete.coerceAtMost(commitBuffer.length))
        } else {
            ic.deleteSurroundingText(1, 0)
            trackDeleted(1)
        }
        invalidateSelectionCache()
    }

    /**
     * Insert space. The IME service’s [InputConnection] handles caret
     * placement (the underlying editor may adjust).
     */
    fun commitSpace() {
        commitText(" ")
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
        if (delta == 1 || delta == -1) {
            moveCursorOneStep(ic, delta)
            return
        }
        val info = ic.getExtractedText(extractedRequest, 0) ?: return
        val text = info.text ?: return
        val currentEnd = info.selectionEnd
        if (currentEnd < 0) return
        val length = text.length
        val target = (currentEnd + delta).coerceIn(0, length)
        if (target == currentEnd && target == info.selectionStart) return
        ic.setSelection(target, target)
        cachedSelStart = target
        cachedSelEnd = target
    }

    /**
     * Space-bar slide: prefer [setSelection] from warm cache (one IPC, all editors).
     * Cold cache: seed position once via [getExtractedText], then [setSelection].
     * DPAD only when the host exposes no selection index.
     */
    private fun moveCursorOneStep(ic: InputConnection, delta: Int) {
        var current = cachedSelEnd
        if (current < 0) {
            val info = ic.getExtractedText(extractedRequest, 0) ?: return
            current = info.selectionEnd
            if (current < 0) {
                sendDownUpKeyEvent(
                    if (delta > 0) KeyEvent.KEYCODE_DPAD_RIGHT else KeyEvent.KEYCODE_DPAD_LEFT,
                )
                return
            }
            val max = info.text?.length ?: current
            val target = (current + delta).coerceIn(0, max)
            ic.setSelection(target, target)
            cachedSelStart = target
            cachedSelEnd = target
            return
        }
        val target = (current + delta).coerceAtLeast(0)
        ic.setSelection(target, target)
        cachedSelStart = target
        cachedSelEnd = target
    }

    fun setSelection(start: Int, end: Int) {
        val ic = ime.currentInputConnection ?: return
        val s = start.coerceAtLeast(0)
        val e = end.coerceAtLeast(0)
        ic.setSelection(s, e)
        cachedSelStart = s
        cachedSelEnd = e
    }

    /**
     * Atomically replaces text around the cursor. Returns metadata for undo,
     * or null when the connection is gone or the edit is invalid.
     */
    fun replaceSurrounding(
        deleteBefore: Int,
        deleteAfter: Int,
        replacement: CharSequence,
    ): ReplaceOutcome? {
        if (deleteBefore < 0 || deleteAfter < 0) return null
        val ic = ime.currentInputConnection ?: return null

        val extractedBefore = ic.getExtractedText(extractedRequest, 0)
        val prevStart = extractedBefore?.selectionStart ?: 0
        val prevEnd = extractedBefore?.selectionEnd ?: prevStart

        val replacedText = buildString {
            if (deleteBefore > 0) {
                append(ic.getTextBeforeCursor(deleteBefore, 0) ?: return null)
            }
            if (deleteAfter > 0) {
                append(ic.getTextAfterCursor(deleteAfter, 0) ?: return null)
            }
        }

        ic.beginBatchEdit()
        try {
            ic.finishComposingText()
            if (deleteBefore > 0 || deleteAfter > 0) {
                ic.deleteSurroundingText(deleteBefore, deleteAfter)
            }
            ic.commitText(replacement, 1)
        } finally {
            ic.endBatchEdit()
        }

        val extracted = ic.getExtractedText(extractedRequest, 0)
        val selStart = extracted?.selectionStart ?: -1
        val selEnd = extracted?.selectionEnd ?: selStart
        syncBufferReplace(deleteBefore, replacement)
        cachedSelStart = selStart
        cachedSelEnd = selEnd
        return ReplaceOutcome(
            ok = true,
            selectionStart = selStart,
            selectionEnd = selEnd,
            replacedText = replacedText,
            insertedLength = replacement.length,
            previousSelectionStart = prevStart,
            previousSelectionEnd = prevEnd,
        )
    }

    /** Snapshot of text around the cursor for improve / undo planning. */
    fun getSurroundingText(beforeChars: Int, afterChars: Int): SurroundingSnapshot? {
        val ic = ime.currentInputConnection
        val limitBefore = beforeChars.coerceAtLeast(0)
        val limitAfter = afterChars.coerceAtLeast(0)

        var before = ic?.getTextBeforeCursor(limitBefore, 0)?.toString() ?: ""
        var after = ic?.getTextAfterCursor(limitAfter, 0)?.toString() ?: ""

        if (before.isEmpty() && commitBuffer.isNotEmpty()) {
            val start = (commitBuffer.length - limitBefore).coerceAtLeast(0)
            before = commitBuffer.substring(start, commitBuffer.length)
        }

        var selStart = cachedSelStart
        var selEnd = cachedSelEnd

        if (before.isEmpty() && ic != null) {
            val extracted = ic.getExtractedText(extractedRequest, 0)
            val text = extracted?.text?.toString()
            val sel = extracted?.selectionStart ?: -1
            if (!text.isNullOrEmpty() && sel > 0) {
                before = text.substring(0, sel.coerceAtMost(text.length))
                    .takeLast(limitBefore.coerceAtMost(sel))
            }
            if (sel >= 0) {
                selStart = sel
                selEnd = extracted?.selectionEnd ?: sel
            }
        } else if (selStart < 0 && ic != null) {
            val extracted = ic.getExtractedText(extractedRequest, 0)
            selStart = extracted?.selectionStart ?: before.length
            selEnd = extracted?.selectionEnd ?: selStart
        }

        if (selStart < 0) selStart = before.length
        if (selEnd < 0) selEnd = selStart

        return SurroundingSnapshot(
            before = before,
            after = after,
            selectionStart = selStart,
            selectionEnd = selEnd,
            isPassword = isPasswordField,
        )
    }

    fun deleteSurroundingText(before: Int, after: Int) {
        if (before <= 0 && after <= 0) return
        val ic = ime.currentInputConnection ?: return
        ic.beginBatchEdit()
        try {
            ic.finishComposingText()
            ic.deleteSurroundingText(before, after)
            if (before > 0) trackDeleted(before)
        } finally {
            ic.endBatchEdit()
        }
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
        parseLastWordFromBuffer()?.word?.let { return it }
        return parseLastWordFromConnection()
    }

    /**
     * Word-boundary metadata for the suggestion-bar action pipeline.
     * [deleteBefore] includes the just-committed boundary character(s).
     */
    fun lastCompletedWordInfo(justCommitted: CharSequence): WordCommitInfo? {
        val ch = justCommitted.firstOrNull() ?: return null
        if (!isWordBoundary(ch)) return null
        val fromBuffer = parseLastWordFromBuffer()
        val parsed = fromBuffer ?: parseLastWordFromConnectionParsed() ?: return null
        val boundary = justCommitted.toString()
        val beforeCtx = when {
            fromBuffer != null && fromBuffer.start > 0 ->
                commitBuffer.substring(0, fromBuffer.start)
            fromBuffer == null -> {
                val icBefore = ime.currentInputConnection
                    ?.getTextBeforeCursor(256, 0)?.toString() ?: ""
                if (parsed.start > 0 && parsed.start <= icBefore.length) {
                    icBefore.substring(0, parsed.start)
                } else {
                    ""
                }
            }
            else -> ""
        }
        return WordCommitInfo(
            word = parsed.word,
            deleteBefore = parsed.word.length + boundary.length,
            deleteAfter = 0,
            boundary = boundary,
            before = beforeCtx,
            after = "",
        )
    }

    /**
     * Trailing word at the cursor without a terminating boundary — used for
     * live shortcut chips (e.g. «др» before space).
     */
    fun trailingWordFragment(): WordCommitInfo? {
        val parsed = parseTrailingWordFromBuffer() ?: return null
        val beforeCtx = if (parsed.start > 0) {
            commitBuffer.substring(0, parsed.start)
        } else {
            ""
        }
        return WordCommitInfo(
            word = parsed.word,
            deleteBefore = parsed.word.length,
            deleteAfter = 0,
            boundary = "",
            before = beforeCtx,
            after = "",
        )
    }

    private data class ParsedWord(val word: String, val start: Int, val end: Int)

    private fun parseTrailingWordFromBuffer(): ParsedWord? {
        if (commitBuffer.isEmpty()) return null
        var end = commitBuffer.length
        while (end > 0 && isWordBoundary(commitBuffer[end - 1])) end--
        if (end <= 0) return null
        var start = end
        while (start > 0 && !isWordBoundary(commitBuffer[start - 1])) start--
        if (end - start < 2) return null
        return ParsedWord(commitBuffer.substring(start, end), start, end)
    }

    private fun parseLastWordFromBuffer(): ParsedWord? {
        if (commitBuffer.isEmpty()) return null
        var end = commitBuffer.length
        while (end > 0 && isWordBoundary(commitBuffer[end - 1])) end--
        if (end <= 0) return null
        var start = end
        while (start > 0 && !isWordBoundary(commitBuffer[start - 1])) start--
        if (end - start < 2) return null
        return ParsedWord(commitBuffer.substring(start, end), start, end)
    }

    private fun parseLastWordFromConnection(): String? =
        parseLastWordFromConnectionParsed()?.word

    private fun parseLastWordFromConnectionParsed(): ParsedWord? {
        val ic = ime.currentInputConnection ?: return null
        var before = ic.getTextBeforeCursor(96, 0)?.toString()
        if (before.isNullOrEmpty()) {
            val extracted = ic.getExtractedText(extractedRequest, 0)
            val text = extracted?.text?.toString()
            val sel = extracted?.selectionStart ?: -1
            if (!text.isNullOrEmpty() && sel > 0) {
                before = text.substring(0, sel.coerceAtMost(text.length))
            }
        }
        if (before.isNullOrEmpty()) return null
        var end = before.length - 1
        while (end >= 0 && isWordBoundary(before[end])) end--
        if (end < 0) return null
        var start = end
        while (start > 0 && !isWordBoundary(before[start - 1])) start--
        if (end - start < 2) return null
        return ParsedWord(before.substring(start, end + 1), start, end + 1)
    }

    private fun syncBufferReplace(deleteBefore: Int, replacement: CharSequence) {
        val delete = deleteBefore.coerceIn(0, commitBuffer.length)
        if (delete > 0) {
            commitBuffer.delete(commitBuffer.length - delete, commitBuffer.length)
        }
        trackCommitted(replacement)
    }

    private fun isWordBoundary(ch: Char): Boolean =
        ch.isWhitespace() || ch == '.' || ch == ',' || ch == '!' || ch == '?' ||
            ch == ';' || ch == ':' || ch == '\n' || ch == '\t' ||
            ch == '…' || ch == '—' || ch == '-' || ch == ')' || ch == '(' ||
            ch == '"' || ch == '\''

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

    private fun invalidateSelectionCache() {
        cachedSelStart = -1
        cachedSelEnd = -1
    }

    private fun cachedSelectionLength(): Int {
        if (cachedSelStart >= 0 && cachedSelEnd > cachedSelStart) {
            return cachedSelEnd - cachedSelStart
        }
        return 0
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

/** Result of a batched surrounding-text replacement. */
data class ReplaceOutcome(
    val ok: Boolean,
    val selectionStart: Int,
    val selectionEnd: Int,
    val replacedText: String,
    val insertedLength: Int,
    val previousSelectionStart: Int,
    val previousSelectionEnd: Int,
)

/** Text around the cursor returned to Dart. */
data class SurroundingSnapshot(
    val before: String,
    val after: String,
    val selectionStart: Int,
    val selectionEnd: Int,
    val isPassword: Boolean,
)

/** Metadata for a completed word at the cursor. */
data class WordCommitInfo(
    val word: String,
    val deleteBefore: Int,
    val deleteAfter: Int,
    val boundary: String,
    val before: String = "",
    val after: String = "",
)

/** Small indirection so tests can override the clock if needed later. */
internal object SystemClockAdapter {
    fun uptime(): Long = android.os.SystemClock.uptimeMillis()
}
