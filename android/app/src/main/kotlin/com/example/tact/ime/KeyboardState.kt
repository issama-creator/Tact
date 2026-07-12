package com.example.tact.ime

import android.os.SystemClock

/**
 * Mutable UI state of the keyboard: current language, layer, and shift.
 *
 * This class is single-threaded; every mutation happens on the Android
 * main thread inside touch or lifecycle callbacks. There is no concurrency
 * to protect against, and no allocation on any state change.
 *
 * State transitions are the union of:
 *   • Shift tap logic (off → on → locked → off, with double-tap window).
 *   • Consuming shift after typing a character (unless locked).
 *   • Layer switch (letters ↔ symbols ↔ symbols-alt), also resets shift.
 *   • Language cycle across [enabledLanguages].
 *
 * The state does not know about layouts or [KeyGridView]. Callers are
 * expected to invalidate the view after a mutation.
 */
class KeyboardState(
    initialLanguage: LanguageKind = LanguageKind.EN,
    val enabledLanguages: List<LanguageKind> = listOf(LanguageKind.EN, LanguageKind.RU),
) {

    var language: LanguageKind = initialLanguage
        private set

    var layer: LayerKind = LayerKind.ALPHA
        private set

    var shift: ShiftState = ShiftState.OFF
        private set

    private var shiftLastTapUptimeMs: Long = 0L

    // -----------------------------------------------------------------

    fun tapShift() {
        val now = SystemClock.uptimeMillis()
        shift = when (shift) {
            ShiftState.OFF -> ShiftState.ON
            ShiftState.ON -> {
                if (now - shiftLastTapUptimeMs <= Theme.SHIFT_DOUBLE_TAP_WINDOW_MS) {
                    ShiftState.LOCKED
                } else {
                    ShiftState.OFF
                }
            }
            ShiftState.LOCKED -> ShiftState.OFF
        }
        shiftLastTapUptimeMs = now
    }

    /**
     * Called after a character has been committed. Shift auto-releases
     * unless the user activated caps lock.
     */
    fun consumeShiftAfterChar() {
        if (shift == ShiftState.ON) {
            shift = ShiftState.OFF
        }
    }

    fun switchLayer(target: LayerKind) {
        layer = target
        shift = ShiftState.OFF
    }

    /**
     * Cycle through [enabledLanguages]. If only one language is enabled
     * this is a no-op. Layer resets to ALPHA and shift is cleared.
     */
    fun cycleLanguage() {
        if (enabledLanguages.size <= 1) return
        val idx = enabledLanguages.indexOf(language)
        val next = enabledLanguages[(idx + 1) % enabledLanguages.size]
        language = next
        layer = LayerKind.ALPHA
        shift = ShiftState.OFF
    }

    /**
     * Reset layer/shift for a new input field. Language is kept (user preference).
     */
    fun resetForNewField() {
        layer = LayerKind.ALPHA
        shift = ShiftState.OFF
        shiftLastTapUptimeMs = 0L
    }

    /**
     * Force a specific language (used when the app requests a numeric-only
     * field: we switch to NUMBERS layer regardless of language).
     */
    fun setLayer(target: LayerKind) {
        layer = target
    }

    /** True if the next character key should render / commit in uppercase. */
    val isUpperCase: Boolean
        get() = shift != ShiftState.OFF
}
