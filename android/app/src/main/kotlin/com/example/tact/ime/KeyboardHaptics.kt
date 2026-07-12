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
 * Enabled flags are driven by companion toggles via [setEnabled].
 */
class KeyboardHaptics(context: Context) {

    private val audioManager: AudioManager =
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager

    @Volatile
    var vibrationEnabled: Boolean = true

    @Volatile
    var matVibrationEnabled: Boolean = true

    @Volatile
    var soundEnabled: Boolean = false

    fun setEnabled(
        vibration: Boolean,
        sound: Boolean,
        matVibration: Boolean = matVibrationEnabled,
    ) {
        vibrationEnabled = vibration
        soundEnabled = sound
        matVibrationEnabled = matVibration
    }

    /**
     * Play a subtle haptic tick for a key press. Non-blocking; if the
     * device disables key haptics globally, this is a no-op.
     */
    fun keyTap(view: View) {
        if (!vibrationEnabled) return
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
        if (!vibrationEnabled) return
        view.performHapticFeedback(
            HapticFeedbackConstants.LONG_PRESS,
            HapticFeedbackConstants.FLAG_IGNORE_VIEW_SETTING,
        )
    }

    /**
     * Warning pulse when mat is detected — independent of key-tap vibration.
     */
    fun matWarning(view: View) {
        if (!matVibrationEnabled) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            view.performHapticFeedback(
                HapticFeedbackConstants.REJECT,
                HapticFeedbackConstants.FLAG_IGNORE_VIEW_SETTING,
            )
        } else {
            view.performHapticFeedback(
                HapticFeedbackConstants.LONG_PRESS,
                HapticFeedbackConstants.FLAG_IGNORE_VIEW_SETTING,
            )
        }
    }

    /**
     * A softer feedback for a modifier action (shift, layer switch,
     * language switch) — distinguishable from a character tap.
     */
    fun modifier(view: View) {
        if (!vibrationEnabled) return
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
     * System key-click sound — only when companion sound toggle is on.
     */
    fun keyClickSound() {
        if (!soundEnabled) return
        audioManager.playSoundEffect(AudioManager.FX_KEYPRESS_STANDARD, 0.35f)
    }

    fun spaceClickSound() {
        if (!soundEnabled) return
        audioManager.playSoundEffect(AudioManager.FX_KEYPRESS_SPACEBAR, 0.35f)
    }

    fun deleteClickSound() {
        if (!soundEnabled) return
        audioManager.playSoundEffect(AudioManager.FX_KEYPRESS_DELETE, 0.35f)
    }

    fun enterClickSound() {
        if (!soundEnabled) return
        audioManager.playSoundEffect(AudioManager.FX_KEYPRESS_RETURN, 0.35f)
    }

    /** Subtle confirmation after a successful suggestion-bar action. */
    fun actionSuccess(view: View) {
        if (!vibrationEnabled) return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            view.performHapticFeedback(
                HapticFeedbackConstants.CONFIRM,
                HapticFeedbackConstants.FLAG_IGNORE_VIEW_SETTING,
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            view.performHapticFeedback(
                HapticFeedbackConstants.KEYBOARD_TAP,
                HapticFeedbackConstants.FLAG_IGNORE_VIEW_SETTING,
            )
        } else {
            @Suppress("DEPRECATION")
            view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
        }
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
