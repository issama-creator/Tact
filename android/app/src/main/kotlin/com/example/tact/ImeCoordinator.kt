package com.example.tact

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.inputmethod.InputMethodManager

/**
 * Selects which keyboard is active (default IME).
 *
 * Multiple keyboards (Gboard, TACT, SwiftKey, …) can stay **enabled** at the
 * same time — Android picks one as default. Third-party apps cannot always
 * change the default without WRITE_SECURE_SETTINGS; we try [trySetDefault]
 * first, then fall back to the system keyboard picker.
 *
 * Important: we never disable other IMEs. [reconcileAfterSettings] only
 * attempts to select TACT when the user enabled it — it does **not**
 * auto-switch to Gboard (that caused fights when both were enabled).
 */
object ImeCoordinator {

    private const val TAG = "ImeCoordinator"
    private const val GBOARD_IME_ID =
        "com.google.android.inputmethod.latin/com.android.inputmethod.latin.LatinIME"

    private val mainHandler = Handler(Looper.getMainLooper())

    enum class Result {
        ALREADY_ACTIVE,
        SELECTED,
        PICKER_SHOWN,
        TACT_DISABLED,
        GBOARD_DISABLED,
        NONE_ENABLED,
        ERROR,
    }

    fun findTactId(context: Context): String? = runCatching {
        imeManager(context).inputMethodList
            .firstOrNull { it.packageName == context.packageName }
            ?.id
    }.getOrNull()

    fun findGboardId(context: Context): String? = runCatching {
        val imm = imeManager(context)
        val fromList = imm.inputMethodList
            .firstOrNull { ImeStatusReader.isGboardPackage(it.packageName) }
            ?.id
        if (fromList != null) return@runCatching fromList
        if (imm.inputMethodList.any { imeIdsMatch(it.id, GBOARD_IME_ID) }) {
            GBOARD_IME_ID
        } else {
            null
        }
    }.getOrNull()

    fun defaultImeId(context: Context): String = runCatching {
        Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.DEFAULT_INPUT_METHOD,
        ) ?: ""
    }.getOrDefault("")

    fun imeIdsMatch(a: String?, b: String?): Boolean {
        if (a == null || b == null) return false
        if (a == b) return true
        if (a.isEmpty() || b.isEmpty()) return false
        val aParts = a.split('/')
        val bParts = b.split('/')
        if (aParts.size != 2 || bParts.size != 2) return false
        if (aParts[0] != bParts[0]) return false
        val aClass = aParts[1].removePrefix(".")
        val bClass = bParts[1].removePrefix(".")
        return aClass == bClass || aParts[1].endsWith(bClass) || bParts[1].endsWith(aClass)
    }

    fun isDefaultIme(context: Context, imeId: String): Boolean =
        imeIdsMatch(defaultImeId(context), imeId)

    fun isEnabled(context: Context, imeId: String): Boolean = runCatching {
        val imm = imeManager(context)
        if (imm.enabledInputMethodList.any { imeIdsMatch(it.id, imeId) }) return@runCatching true
        val enabled = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.ENABLED_INPUT_METHODS,
        ) ?: return@runCatching false
        enabled.split(':').any { imeIdsMatch(it.trim(), imeId) }
    }.getOrDefault(false)

    /**
     * After the user returns from system keyboard settings, try to make TACT
     * the default **only if** TACT is enabled. Gboard and other IMEs stay
     * enabled — we never touch them here.
     */
    fun reconcileAfterSettings(
        context: Context,
        showPickerOnFailure: Boolean = false,
    ): Result = runCatching {
        val tactId = findTactId(context) ?: return@runCatching Result.TACT_DISABLED

        if (!isEnabled(context, tactId)) {
            return@runCatching Result.TACT_DISABLED
        }

        activateIme(
            context,
            tactId,
            defaultImeId(context),
            Result.TACT_DISABLED,
            showPickerOnFailure,
        )
    }.getOrElse {
        Log.e(TAG, "reconcileAfterSettings failed", it)
        Result.ERROR
    }

    fun reconcileAfterSettingsDelayed(
        context: Context,
        showPickerOnFailure: Boolean,
        delayMs: Long = 400L,
        onDone: (Result) -> Unit,
    ) {
        mainHandler.postDelayed({
            reconcileWithEnabledRetry(
                context = context,
                showPickerOnFailure = showPickerOnFailure,
                attemptsLeft = 5,
                gapMs = 200L,
                onDone = onDone,
            )
        }, delayMs)
    }

    /**
     * Re-read enabled IMEs — the system list can lag after Settings.
     * Runs on the main thread via [Handler] (no blocking sleep).
     */
    private fun reconcileWithEnabledRetry(
        context: Context,
        showPickerOnFailure: Boolean,
        attemptsLeft: Int,
        gapMs: Long,
        onDone: (Result) -> Unit,
    ) {
        val tactId = findTactId(context)
        if (tactId != null && isEnabled(context, tactId)) {
            onDone(reconcileAfterSettings(context, showPickerOnFailure))
            return
        }
        if (attemptsLeft <= 1) {
            onDone(Result.TACT_DISABLED)
            return
        }
        mainHandler.postDelayed({
            reconcileWithEnabledRetry(
                context, showPickerOnFailure, attemptsLeft - 1, gapMs, onDone,
            )
        }, gapMs)
    }

    /** User explicitly asked for TACT. */
    fun activateTact(
        context: Context,
        showPickerOnFailure: Boolean = true,
    ): Result = runCatching {
        val tactId = findTactId(context) ?: return@runCatching Result.TACT_DISABLED
        if (!isEnabled(context, tactId)) return@runCatching Result.TACT_DISABLED
        activateIme(
            context, tactId, defaultImeId(context), Result.TACT_DISABLED,
            showPickerOnFailure = showPickerOnFailure,
        )
    }.getOrElse {
        Log.e(TAG, "activateTact failed", it)
        Result.ERROR
    }

    /** User explicitly asked for Gboard. */
    fun activateGboard(
        context: Context,
        showPickerOnFailure: Boolean = true,
    ): Result = runCatching {
        val gboardId = findGboardId(context) ?: return@runCatching Result.GBOARD_DISABLED
        if (!isEnabled(context, gboardId)) return@runCatching Result.GBOARD_DISABLED
        activateIme(
            context, gboardId, defaultImeId(context), Result.GBOARD_DISABLED,
            showPickerOnFailure = showPickerOnFailure,
        )
    }.getOrElse {
        Log.e(TAG, "activateGboard failed", it)
        Result.ERROR
    }

    private fun activateIme(
        context: Context,
        imeId: String,
        currentDefaultId: String,
        disabledResult: Result,
        showPickerOnFailure: Boolean,
    ): Result {
        if (!isEnabled(context, imeId)) return disabledResult
        if (imeIdsMatch(currentDefaultId, imeId) || isDefaultIme(context, imeId)) {
            return Result.ALREADY_ACTIVE
        }
        if (trySetDefault(context, imeId)) return Result.SELECTED
        if (!showPickerOnFailure) return Result.ALREADY_ACTIVE
        runCatching { com.example.tact.ime.ImeSwitcher.showPicker(context) }
            .onFailure { Log.e(TAG, "showPicker failed", it) }
        return Result.PICKER_SHOWN
    }

    private fun trySetDefault(context: Context, imeId: String): Boolean {
        return try {
            Settings.Secure.putString(
                context.contentResolver,
                Settings.Secure.DEFAULT_INPUT_METHOD,
                imeId,
            )
            isDefaultIme(context, imeId)
        } catch (t: Throwable) {
            Log.w(TAG, "trySetDefault blocked: ${t.message}")
            false
        }
    }

    private fun imeManager(context: Context): InputMethodManager =
        context.getSystemService(Context.INPUT_METHOD_SERVICE) as InputMethodManager
}
