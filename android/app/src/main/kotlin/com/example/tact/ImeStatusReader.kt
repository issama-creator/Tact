package com.example.tact

import android.content.Context
import android.provider.Settings
import android.view.inputmethod.InputMethodInfo
import android.view.inputmethod.InputMethodManager
import org.json.JSONArray
import org.json.JSONObject

/** Reads which IMEs are enabled / selected — TACT never modifies other keyboards. */
object ImeStatusReader {

    private const val GBOARD_PACKAGE = "com.google.android.inputmethod.latin"

    fun read(context: Context): String {
        val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE)
            as InputMethodManager
        val pm = context.packageManager
        val defaultId = Settings.Secure.getString(
            context.contentResolver,
            Settings.Secure.DEFAULT_INPUT_METHOD,
        ) ?: ""

        val enabledIds = imm.enabledInputMethodList.map { it.id }.toSet()
        val installed = imm.inputMethodList

        val keyboards = JSONArray()
        var tactEnabled = false
        var gboardEnabled = false
        var gboardInstalled = false

        for (imi in installed) {
            if (!shouldInclude(imi, context.packageName, pm)) continue
            val id = imi.id
            val label = safeLabel(imi, pm).ifEmpty { id }
            val pkg = imi.packageName
            val enabled = enabledIds.contains(id)
            val isGboard = isGboardPackage(pkg)
            val isTact = pkg == context.packageName

            if (isTact && enabled) tactEnabled = true
            if (isGboard) {
                gboardInstalled = true
                if (enabled) gboardEnabled = true
            }

            keyboards.put(
                JSONObject().apply {
                    put("id", id)
                    put("package", pkg)
                    put("label", label)
                    put("enabled", enabled)
                    put("isDefault", ImeCoordinator.imeIdsMatch(id, defaultId))
                    put("isTact", isTact)
                    put("isGboard", isGboard)
                },
            )
        }

        // Gboard can be in the list under a secondary service id — scan again.
        if (!gboardInstalled) {
            for (imi in installed) {
                if (isGboardPackage(imi.packageName)) {
                    gboardInstalled = true
                    gboardEnabled = enabledIds.contains(imi.id)
                    break
                }
            }
        }

        val tactId = ImeCoordinator.findTactId(context) ?: ""
        val gboardId = ImeCoordinator.findGboardId(context) ?: ""
        val tactIsDefault = tactId.isNotEmpty() &&
            ImeCoordinator.imeIdsMatch(defaultId, tactId)
        val gboardIsDefault = gboardId.isNotEmpty() &&
            ImeCoordinator.imeIdsMatch(defaultId, gboardId)

        val activeLabel = when {
            tactIsDefault -> "TACT"
            gboardIsDefault -> "Gboard"
            defaultId.isNotEmpty() -> "other"
            else -> "none"
        }

        val allSoftDisabled = gboardInstalled && !gboardEnabled && !tactEnabled

        return JSONObject().apply {
            put("defaultImeId", defaultId)
            put("keyboards", keyboards)
            put("gboardInstalled", gboardInstalled)
            put("gboardEnabled", gboardEnabled)
            put("tactEnabled", tactEnabled)
            put("tactIsDefault", tactIsDefault)
            put("gboardIsDefault", gboardIsDefault)
            put("tactId", tactId)
            put("gboardId", gboardId)
            put("activeKeyboard", activeLabel)
            put("allSoftKeyboardsDisabled", allSoftDisabled)
        }.toString()
    }

    fun isGboardPackage(pkg: String): Boolean =
        pkg == GBOARD_PACKAGE || pkg.contains("inputmethod.latin")

    /**
     * Include soft keyboards. Gboard and TACT are always included when present.
     * Voice-only IMEs (Google voice typing) are excluded.
     */
    private fun shouldInclude(
        imi: InputMethodInfo,
        selfPackage: String,
        pm: android.content.pm.PackageManager,
    ): Boolean {
        val pkg = imi.packageName
        if (pkg == selfPackage || isGboardPackage(pkg)) return true
        if (isVoiceOnly(imi, pm)) return false
        return isSoftKeyboard(imi)
    }

    private fun isVoiceOnly(imi: InputMethodInfo, pm: android.content.pm.PackageManager): Boolean {
        val id = imi.id.lowercase()
        if (id.contains("voice")) return true
        val label = safeLabel(imi, pm).lowercase()
        if (label.contains("голосов") || label.contains("voice")) return true
        if (imi.subtypeCount == 0) return false
        var hasKeyboard = false
        for (i in 0 until imi.subtypeCount) {
            val mode = imi.getSubtypeAt(i).mode
            if (mode == "keyboard" || mode == "email" || mode == "url") {
                hasKeyboard = true
                break
            }
        }
        return !hasKeyboard
    }

    private fun isSoftKeyboard(imi: InputMethodInfo): Boolean {
        if (imi.subtypeCount == 0) return true
        for (i in 0 until imi.subtypeCount) {
            if (imi.getSubtypeAt(i).mode == "keyboard") return true
        }
        return false
    }

    private fun safeLabel(imi: InputMethodInfo, pm: android.content.pm.PackageManager): String {
        return try {
            imi.loadLabel(pm)?.toString() ?: ""
        } catch (_: Exception) {
            ""
        }
    }
}
