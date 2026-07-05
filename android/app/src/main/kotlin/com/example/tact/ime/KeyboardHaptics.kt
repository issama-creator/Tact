package com.example.tact.ime

import android.content.ClipboardManager
import android.content.Context
import android.media.AudioManager
import android.os.Build
import android.view.HapticFeedbackConstants
import android.view.View

/**
 * Feedback controller — one place for haptic and sound cues + a clipboard
 * accessor for future features.
 *
 * The [Sound] and [Clipboard] hooks are wired but intentionally minimal per
 * the current scope. They exist so that when a caller (suggestion bar
 * clipboard chip, sound-on-tap setting, etc.) needs them, it doesn't have
 * to hunt for the correct system API — everything is here.
 */
class KeyboardHaptics(context: Context) {

    private val audioManager: AudioManager =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    /**
     * Play a subtle haptic tick for a key press. Non-blocking; if the
     * device disables key haptics globally, this is a no-op.
     */
    fun keyTap(view: View) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            view.performHapticFeedback(
                HapticFeedbackConstants.KEYBOARD_TAP,
                HapticFeedbackConstants.FLAG_IGNORE_VIEW_SETTING,
            )
        } else {
            @Suppress("DEPRECATION")
            view.performHapticFeedback(HapticFeedbackConstants.KEYBOARD_TAP)
        }
    }

    /** A slightly stronger tick for a long-press trigger. */
    fun longPress(view: View) {
        view.performHapticFeedback(
            HapticFeedbackConstants.LONG_PRESS,
            HapticFeedbackConstants.FLAG_IGNORE_VIEW_SETTING,
        )
    }

    /**
     * A softer feedback for a modifier action (shift, layer switch,
     * language switch) — distinguishable from a character tap.
     */
    fun modifier(view: View) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            view.performHapticFeedback(
                HapticFeedbackConstants.CLOCK_TICK,
                HapticFeedbackConstants.FLAG_IGNORE_VIEW_SETTING,
            )
        } else {
            keyTap(view)
        }
    }

    /**
     * System key-click sound.
     *
     * Kept as an architecture hook: currently plays a soft system click on
     * key tap only when the device's system-wide "keyboard sound on" toggle
     * is enabled. A user-facing preference is a companion-app concern (out
     * of scope for this deliverable).
     */
    fun keyClickSound() {
        audioManager.playSoundEffect(AudioManager.FX_KEYPRESS_STANDARD, 0.35f)
    }

    fun spaceClickSound() {
        audioManager.playSoundEffect(AudioManager.FX_KEYPRESS_SPACEBAR, 0.35f)
    }

    fun deleteClickSound() {
        audioManager.playSoundEffect(AudioManager.FX_KEYPRESS_DELETE, 0.35f)
    }

    fun enterClickSound() {
        audioManager.playSoundEffect(AudioManager.FX_KEYPRESS_RETURN, 0.35f)
    }
}

/**
 * Clipboard accessor — a hook only, not a UI.
 *
 * Kept behind a small facade so a future clipboard chip in the suggestion
 * bar can consume it without importing android.content.* directly.
 */
class ClipboardAccess(context: Context) {

    private val manager: ClipboardManager =
        context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager

    /**
     * Best-effort read of the last non-sensitive text on the clipboard.
     * Returns null when the clipboard is empty, contains non-text, or when
     * the current field is a password field (caller-enforced).
     */
    fun peekText(): CharSequence? {
        if (!manager.hasPrimaryClip()) return null
        val clip = manager.primaryClip ?: return null
        if (clip.itemCount == 0) return null
        return clip.getItemAt(0).coerceToText(null)
    }
}
