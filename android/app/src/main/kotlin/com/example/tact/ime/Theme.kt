package com.example.tact.ime

import android.content.res.Configuration
import android.graphics.Color
import android.util.DisplayMetrics
import android.util.TypedValue
import android.view.View

/**
 * Static Material 3 dark theme for the TACT keyboard surface.
 *
 * A deliberately fixed dark palette for MVP. Theme switching is a companion-app
 * concern that is out of scope for this deliverable. Colors were chosen for
 * calm contrast, clear letter/function separation, and OLED-friendliness
 * (near-black background).
 *
 * All measurements are density-independent. Concrete pixel values are computed
 * at layout time by [Metrics] from the current [Configuration] and
 * [DisplayMetrics].
 */
object Theme {

    // --- Palette (ARGB) -----------------------------------------------------

    const val COLOR_KEYBOARD_BG: Int = 0xFF171719.toInt()
    /** Same family as keyboard bg — empty strip must not look like a purple void. */
    const val COLOR_PANEL_BAR_BG: Int = 0xFF1C1C1F.toInt()
    const val COLOR_KEY_LETTER_BG: Int = 0xFF2E2E33.toInt()
    const val COLOR_KEY_LETTER_BG_PRESSED: Int = 0xFF3E3E45.toInt()
    const val COLOR_KEY_FUNCTION_BG: Int = 0xFF232328.toInt()
    const val COLOR_KEY_FUNCTION_BG_PRESSED: Int = 0xFF303036.toInt()
    const val COLOR_KEY_ACCENT_BG: Int = 0xFF6750A4.toInt()
    const val COLOR_KEY_ACCENT_BG_PRESSED: Int = 0xFF7B62BE.toInt()
    const val COLOR_KEY_TEXT: Int = 0xFFFFFFFF.toInt()
    const val COLOR_KEY_TEXT_MUTED: Int = 0xFF8B9098.toInt()
    const val COLOR_KEY_TEXT_ACCENT: Int = 0xFFFFFFFF.toInt()
    const val COLOR_KEY_PREVIEW_BG: Int = 0xFF3A3A40.toInt()
    const val COLOR_KEY_PREVIEW_STROKE: Int = 0x33FFFFFF
    const val COLOR_RIPPLE: Int = 0x33FFFFFF
    const val COLOR_DIVIDER: Int = 0x1FFFFFFF
    const val COLOR_LONGPRESS_POPUP_BG: Int = 0xFF2C2C31.toInt()
    const val COLOR_LONGPRESS_POPUP_HIGHLIGHT: Int = COLOR_KEY_ACCENT_BG
    const val COLOR_TRANSPARENT: Int = Color.TRANSPARENT

    // --- Dimensions (dp) ----------------------------------------------------

    const val SUGGESTION_BAR_HEIGHT_DP_PHONE: Float = 36f
    const val SUGGESTION_BAR_HEIGHT_DP_PHONE_LAND: Float = 30f
    const val SUGGESTION_BAR_HEIGHT_DP_TABLET: Float = 40f

    // Key area height is computed adaptively from the current screen height
    // (see [keyAreaHeightDp]); these are only the clamp bounds so the
    // keyboard never becomes unusably small or absurdly tall.
    // Gboard-like proportions — compact rows, not oversized keys.
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

    const val KEYBOARD_BOTTOM_PADDING_DP_PHONE: Float = 6f
    const val KEYBOARD_BOTTOM_PADDING_DP_PHONE_LAND: Float = 4f
    const val KEYBOARD_BOTTOM_PADDING_DP_TABLET: Float = 10f

    const val KEY_GRID_PADDING_X_DP: Float = 3f
    const val KEY_GRID_PADDING_Y_DP: Float = 2f
    const val KEY_HORIZONTAL_GAP_DP: Float = 3.5f
    const val KEY_VERTICAL_GAP_DP: Float = 4f
    const val KEY_CORNER_RADIUS_DP: Float = 6f
    const val KEY_BOTTOM_ROW_HEIGHT_WEIGHT: Float = 0.88f

    const val KEY_LABEL_TEXT_SIZE_SP: Float = 21f
    const val KEY_LABEL_TEXT_SIZE_SP_TABLET: Float = 23f
    const val KEY_SUB_LABEL_TEXT_SIZE_SP: Float = 9.5f
    const val KEY_FUNCTION_TEXT_SIZE_SP: Float = 14f

    const val KEY_PREVIEW_TEXT_SIZE_SP: Float = 30f
    const val KEY_PREVIEW_HEIGHT_DP: Float = 64f
    const val KEY_PREVIEW_LIFT_DP: Float = 6f
    const val KEY_PREVIEW_CORNER_RADIUS_DP: Float = 10f
    const val KEY_PREVIEW_STROKE_WIDTH_DP: Float = 1f

    const val LONGPRESS_POPUP_ITEM_WIDTH_DP: Float = 44f
    const val LONGPRESS_POPUP_ITEM_HEIGHT_DP: Float = 52f
    const val LONGPRESS_POPUP_CORNER_RADIUS_DP: Float = 10f
    const val LONGPRESS_POPUP_TEXT_SIZE_SP: Float = 22f
    const val LONGPRESS_POPUP_PADDING_DP: Float = 6f

    // --- Timings (ms) -------------------------------------------------------

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

    // --- Device-class heuristics --------------------------------------------

    fun isTablet(configuration: Configuration): Boolean {
        return configuration.smallestScreenWidthDp >= 600
    }

    fun isLandscape(configuration: Configuration): Boolean {
        return configuration.orientation == Configuration.ORIENTATION_LANDSCAPE
    }

    fun suggestionBarHeightDp(configuration: Configuration): Float {
        val tablet = isTablet(configuration)
        val land = isLandscape(configuration)
        return when {
            tablet -> SUGGESTION_BAR_HEIGHT_DP_TABLET
            land -> SUGGESTION_BAR_HEIGHT_DP_PHONE_LAND
            else -> SUGGESTION_BAR_HEIGHT_DP_PHONE
        }
    }

    /**
     * Adaptive key-grid height: a fraction of the current screen height,
     * clamped per device class so it scales across phones, foldables and
     * tablets, in both orientations, at any density.
     */
    fun keyAreaHeightDp(configuration: Configuration): Float {
        val tablet = isTablet(configuration)
        val land = isLandscape(configuration)
        // screenHeightDp is orientation-aware (short side in landscape).
        val screenH = configuration.screenHeightDp.toFloat().coerceAtLeast(1f)
        val fraction: Float
        val min: Float
        val max: Float
        when {
            tablet && land -> {
                fraction = KEY_AREA_FRACTION_TABLET_LAND
                min = KEY_AREA_MIN_DP_TABLET_LAND; max = KEY_AREA_MAX_DP_TABLET_LAND
            }
            tablet -> {
                fraction = KEY_AREA_FRACTION_TABLET
                min = KEY_AREA_MIN_DP_TABLET; max = KEY_AREA_MAX_DP_TABLET
            }
            land -> {
                fraction = KEY_AREA_FRACTION_PHONE_LAND
                min = KEY_AREA_MIN_DP_PHONE_LAND; max = KEY_AREA_MAX_DP_PHONE_LAND
            }
            else -> {
                fraction = KEY_AREA_FRACTION_PHONE
                min = KEY_AREA_MIN_DP_PHONE; max = KEY_AREA_MAX_DP_PHONE
            }
        }
        return (screenH * fraction).coerceIn(min, max)
    }

    fun keyboardBottomPaddingDp(configuration: Configuration): Float = when {
        isTablet(configuration) -> KEYBOARD_BOTTOM_PADDING_DP_TABLET
        isLandscape(configuration) -> KEYBOARD_BOTTOM_PADDING_DP_PHONE_LAND
        else -> KEYBOARD_BOTTOM_PADDING_DP_PHONE
    }

    fun keyLabelTextSizeSp(configuration: Configuration): Float =
        if (isTablet(configuration)) KEY_LABEL_TEXT_SIZE_SP_TABLET else KEY_LABEL_TEXT_SIZE_SP
}

/**
 * Density conversion helpers, bound to a [View] so they cache the current
 * [DisplayMetrics] without repeated look-ups on the hot path.
 */
class Metrics(view: View) {
    private val displayMetrics: DisplayMetrics = view.resources.displayMetrics

    fun dp(value: Float): Float =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, displayMetrics)

    fun sp(value: Float): Float =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_SP, value, displayMetrics)

    fun dpInt(value: Float): Int = (dp(value) + 0.5f).toInt()
}
