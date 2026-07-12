package com.example.tact.ime

import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.util.DisplayMetrics
import android.util.TypedValue
import android.view.View
import org.json.JSONObject

/**
 * TACT keyboard surface theme — runtime palette from companion selection.
 *
 * **Sizing** lives in [KeyboardSizing]. Color fields are mutable so
 * [applyIndex] can swap Dark / Light / Midnight / Graphite.
 */
object Theme {

    // --- Active palette (ARGB) — defaults = Тёмная ─────────────────────

    @JvmField var COLOR_KEYBOARD_BG: Int = 0xFF12141A.toInt()
    @JvmField var COLOR_PANEL_BAR_BG: Int = 0xFF161920.toInt()
    @JvmField var COLOR_KEY_LETTER_BG: Int = 0xFF2A2E36.toInt()
    @JvmField var COLOR_KEY_LETTER_BG_PRESSED: Int = 0xFF3A3F49.toInt()
    @JvmField var COLOR_KEY_FUNCTION_BG: Int = 0xFF1C2028.toInt()
    @JvmField var COLOR_KEY_FUNCTION_BG_PRESSED: Int = 0xFF2A2F38.toInt()
    @JvmField var COLOR_KEY_ACCENT_BG: Int = 0xFF2A9B8F.toInt()
    @JvmField var COLOR_KEY_ACCENT_BG_PRESSED: Int = 0xFF34B3A5.toInt()
    @JvmField var COLOR_KEY_TEXT: Int = 0xFFF2F3F5.toInt()
    @JvmField var COLOR_KEY_TEXT_MUTED: Int = 0xFF8B929C.toInt()
    @JvmField var COLOR_KEY_TEXT_ACCENT: Int = 0xFFFFFFFF.toInt()
    @JvmField var COLOR_KEY_PREVIEW_BG: Int = 0xFF363B45.toInt()
    @JvmField var COLOR_KEY_PREVIEW_STROKE: Int = 0x40FFFFFF
    @JvmField var COLOR_KEY_STROKE: Int = 0x28FFFFFF
    @JvmField var COLOR_RIPPLE: Int = 0x28FFFFFF
    @JvmField var COLOR_DIVIDER: Int = 0x24FFFFFF
    @JvmField var COLOR_LONGPRESS_POPUP_BG: Int = 0xFF2A2F38.toInt()
    @JvmField var COLOR_LONGPRESS_POPUP_HIGHLIGHT: Int = COLOR_KEY_ACCENT_BG
    const val COLOR_TRANSPARENT: Int = Color.TRANSPARENT

    @JvmField var activeIndex: Int = -1
    @JvmField var colorsApplied: Boolean = false

    /** Matches companion KeyboardThemeStyle.all order. */
    fun applyIndex(index: Int) {
        val next = index.coerceIn(0, 3)
        if (next == activeIndex && colorsApplied) return
        activeIndex = next
        colorsApplied = true
        when (activeIndex) {
            0 -> applyPalette(
                keyboardBg = 0xFF12141A.toInt(),
                panelBg = 0xFF12141A.toInt(),
                letter = 0xFF2A2E36.toInt(),
                function = 0xFF1C2028.toInt(),
                accent = 0xFF2A9B8F.toInt(),
                keyText = 0xFFF2F3F5.toInt(),
                keyTextMuted = 0xFF8B929C.toInt(),
                stroke = 0x28FFFFFF,
                lightKeys = false,
            )
            1 -> applyPalette(
                keyboardBg = 0xFFF3F4F6.toInt(),
                panelBg = 0xFFF3F4F6.toInt(),
                letter = 0xFFFFFFFF.toInt(),
                function = 0xFFE5E7EB.toInt(),
                accent = 0xFF2A9B8F.toInt(),
                keyText = 0xFF1F2937.toInt(),
                keyTextMuted = 0xFF6B7280.toInt(),
                stroke = 0x22000000,
                lightKeys = true,
            )
            2 -> applyPalette(
                keyboardBg = 0xFF1E1B4B.toInt(),
                panelBg = 0xFF1E1B4B.toInt(),
                letter = 0xFF3730A3.toInt(),
                function = 0xFF15132F.toInt(),
                accent = 0xFF8B5CF6.toInt(),
                keyText = 0xFFF5F3FF.toInt(),
                keyTextMuted = 0xFFA5B4FC.toInt(),
                stroke = 0x30FFFFFF,
                lightKeys = false,
            )
            else -> applyPalette(
                keyboardBg = 0xFF27272A.toInt(),
                panelBg = 0xFF27272A.toInt(),
                letter = 0xFF3F3F46.toInt(),
                function = 0xFF1F1F23.toInt(),
                accent = 0xFF2A9B8F.toInt(),
                keyText = 0xFFF4F4F5.toInt(),
                keyTextMuted = 0xFFA1A1AA.toInt(),
                stroke = 0x28FFFFFF,
                lightKeys = false,
            )
        }
    }

    private fun applyPalette(
        keyboardBg: Int,
        panelBg: Int,
        letter: Int,
        function: Int,
        accent: Int,
        keyText: Int,
        keyTextMuted: Int,
        stroke: Int,
        lightKeys: Boolean,
    ) {
        COLOR_KEYBOARD_BG = keyboardBg
        COLOR_PANEL_BAR_BG = panelBg
        COLOR_KEY_LETTER_BG = letter
        COLOR_KEY_LETTER_BG_PRESSED = shiftValue(letter, if (lightKeys) -0.08f else 0.10f)
        COLOR_KEY_FUNCTION_BG = function
        COLOR_KEY_FUNCTION_BG_PRESSED = shiftValue(function, if (lightKeys) -0.08f else 0.10f)
        COLOR_KEY_ACCENT_BG = accent
        COLOR_KEY_ACCENT_BG_PRESSED = shiftValue(accent, 0.08f)
        COLOR_KEY_TEXT = keyText
        COLOR_KEY_TEXT_MUTED = keyTextMuted
        COLOR_KEY_TEXT_ACCENT = 0xFFFFFFFF.toInt()
        COLOR_KEY_PREVIEW_BG = shiftValue(letter, if (lightKeys) -0.05f else 0.12f)
        COLOR_KEY_PREVIEW_STROKE = stroke
        COLOR_KEY_STROKE = stroke
        COLOR_RIPPLE = if (lightKeys) 0x22000000 else 0x28FFFFFF
        COLOR_DIVIDER = if (lightKeys) 0x18000000 else 0x24FFFFFF
        COLOR_LONGPRESS_POPUP_BG = function
        COLOR_LONGPRESS_POPUP_HIGHLIGHT = accent
    }

    private fun shiftValue(color: Int, delta: Float): Int {
        val hsv = FloatArray(3)
        Color.colorToHSV(color, hsv)
        hsv[2] = (hsv[2] + delta).coerceIn(0f, 1f)
        return Color.HSVToColor(Color.alpha(color), hsv)
    }

    // --- Dimensions (dp) ----------------------------------------------------

    const val SUGGESTION_BAR_HEIGHT_DP_PHONE: Float = 34f
    const val SUGGESTION_BAR_HEIGHT_DP_PHONE_LAND: Float = 28f
    const val SUGGESTION_BAR_HEIGHT_DP_TABLET: Float = 38f

    const val KEY_AREA_MIN_DP_PHONE: Float = 188f
    const val KEY_AREA_MAX_DP_PHONE: Float = 248f
    const val KEY_AREA_MIN_DP_PHONE_LAND: Float = 140f
    const val KEY_AREA_MAX_DP_PHONE_LAND: Float = 200f
    const val KEY_AREA_MIN_DP_TABLET: Float = 240f
    const val KEY_AREA_MAX_DP_TABLET: Float = 320f
    const val KEY_AREA_MIN_DP_TABLET_LAND: Float = 190f
    const val KEY_AREA_MAX_DP_TABLET_LAND: Float = 280f

    const val KEY_AREA_FRACTION_PHONE: Float = 0.265f
    const val KEY_AREA_FRACTION_PHONE_LAND: Float = 0.48f
    const val KEY_AREA_FRACTION_TABLET: Float = 0.28f
    const val KEY_AREA_FRACTION_TABLET_LAND: Float = 0.38f

    const val KEYBOARD_BOTTOM_PADDING_DP_PHONE: Float = 28f
    const val KEYBOARD_BOTTOM_PADDING_DP_PHONE_LAND: Float = 12f
    const val KEYBOARD_BOTTOM_PADDING_DP_TABLET: Float = 20f

    const val KEYBOARD_EDGE_INSET_DP: Float = 6f

    const val KEY_GRID_PADDING_X_DP: Float = 4f
    const val KEY_GRID_PADDING_Y_DP: Float = 4f
    const val KEY_HORIZONTAL_GAP_DP: Float = 5.5f
    const val KEY_VERTICAL_GAP_DP: Float = 6.5f
    const val KEY_MAX_ROW_HEIGHT_DP: Float = 44f
    const val KEY_DRAW_INSET_H_DP: Float = 0.5f
    const val KEY_DRAW_INSET_V_DP: Float = 0.75f
    const val KEY_CORNER_RADIUS_DP: Float = 5.5f
    const val KEY_STROKE_WIDTH_DP: Float = 0f
    const val KEY_BOTTOM_ROW_HEIGHT_WEIGHT: Float = 1f

    const val KEY_LABEL_TEXT_SIZE_SP: Float = 21f
    const val KEY_LABEL_TEXT_SIZE_SP_TABLET: Float = 23f
    const val KEY_SUB_LABEL_TEXT_SIZE_SP: Float = 9.5f
    const val KEY_FUNCTION_TEXT_SIZE_SP: Float = 14f

    const val KEY_PREVIEW_TEXT_SIZE_SP: Float = 30f
    const val KEY_PREVIEW_HEIGHT_DP: Float = 64f
    const val KEY_PREVIEW_LIFT_DP: Float = 6f
    const val KEY_PREVIEW_CORNER_RADIUS_DP: Float = 8f
    const val KEY_PREVIEW_STROKE_WIDTH_DP: Float = 1f

    const val LONGPRESS_POPUP_ITEM_WIDTH_DP: Float = 44f
    const val LONGPRESS_POPUP_ITEM_HEIGHT_DP: Float = 52f
    const val LONGPRESS_POPUP_CORNER_RADIUS_DP: Float = 8f
    const val LONGPRESS_POPUP_TEXT_SIZE_SP: Float = 22f
    const val LONGPRESS_POPUP_PADDING_DP: Float = 6f

    const val PRESS_ANIM_MS: Long = 60L
    const val RELEASE_ANIM_MS: Long = 100L
    const val PREVIEW_FADE_IN_MS: Long = 30L
    const val PREVIEW_FADE_OUT_MS: Long = 100L
    const val RIPPLE_ANIM_MS: Long = 260L

    const val LONG_PRESS_TRIGGER_MS: Long = 300L
    const val BACKSPACE_INITIAL_DELAY_MS: Long = 380L
    const val BACKSPACE_REPEAT_INTERVAL_MS: Long = 50L
    const val BACKSPACE_WORD_DELETE_AFTER_MS: Long = 1800L
    const val SHIFT_DOUBLE_TAP_WINDOW_MS: Long = 300L
    const val SPACE_CURSOR_SLIDE_THRESHOLD_DP: Float = 10f

    fun isTablet(configuration: Configuration): Boolean =
        KeyboardSizing.isTablet(configuration)

    fun isLandscape(configuration: Configuration): Boolean =
        KeyboardSizing.isLandscape(configuration)

    fun suggestionBarHeightDp(configuration: Configuration): Float =
        KeyboardSizing.suggestionBarHeightDp(configuration)

    fun keyAreaHeightDp(configuration: Configuration): Float =
        KeyboardSizing.keyAreaHeightDp(configuration)

    fun keyboardBottomPaddingDp(configuration: Configuration): Float =
        KeyboardSizing.keyboardBottomPaddingDp(configuration)

    fun keyLabelTextSizeSp(configuration: Configuration): Float =
        KeyboardSizing.keyLabelTextSizeSp(configuration)
}

/** Companion → IME theme refresh without refocusing the text field. */
object ThemeChangeBus {
    const val ACTION = "com.example.tact.action.THEME_CHANGED"

    fun notify(context: Context) {
        context.sendBroadcast(
            Intent(ACTION).setPackage(context.packageName),
        )
    }
}

/** Reads companion theme index from Flutter SharedPreferences. */
object ThemePrefs {
    private const val FLUTTER_PREFS = "FlutterSharedPreferences"
    private const val COMPANION_KEY = "flutter.tact.companion_prefs"
    private const val SETTINGS_KEY = "flutter.tact.keyboard_settings"

    fun applyFromStorage(context: Context) {
        val prefs = context.getSharedPreferences(FLUTTER_PREFS, Context.MODE_PRIVATE)
        // Companion default is Midnight (index 2).
        val index = readThemeIndex(prefs) ?: 2
        Theme.applyIndex(index)
    }

    private fun readThemeIndex(prefs: android.content.SharedPreferences): Int? {
        readIndexFromJson(prefs.getString(COMPANION_KEY, null), "selectedThemeIndex")
            ?.let { return it }
        readIndexFromJson(prefs.getString(SETTINGS_KEY, null), "themeIndex")
            ?.let { return it }
        return null
    }

    private fun readIndexFromJson(raw: String?, field: String): Int? {
        if (raw.isNullOrBlank()) return null
        return try {
            val obj = JSONObject(raw)
            if (!obj.has(field)) null else obj.getInt(field).coerceIn(0, 3)
        } catch (_: Throwable) {
            null
        }
    }
}

class Metrics(view: View) {
    private val displayMetrics: DisplayMetrics = view.resources.displayMetrics

    fun dp(value: Float): Float =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, displayMetrics)

    fun sp(value: Float): Float =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, value, displayMetrics)

    fun dpInt(value: Float): Int = (dp(value) + 0.5f).toInt()
}
