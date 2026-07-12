package com.example.tact.ime

import android.content.res.Configuration
import android.graphics.Color
import android.util.DisplayMetrics
import android.util.TypedValue
import android.view.View

/**
 * TACT keyboard surface theme — distinct from stock Material / Gboard:
 * cooler charcoal field, soft key stroke, teal enter (not Material purple).
 *
 * **Sizing** (gaps, heights, content width) lives in [KeyboardSizing].
 * Base dp/sp constants below are the scale=1.0 reference values.
 */
object Theme {

    // --- Palette (ARGB) -----------------------------------------------------

    /** Deep cool charcoal — not pure Gboard near-black. */
    const val COLOR_KEYBOARD_BG: Int = 0xFF12141A.toInt()
    const val COLOR_PANEL_BAR_BG: Int = 0xFF161920.toInt()
    const val COLOR_KEY_LETTER_BG: Int = 0xFF2A2E36.toInt()
    const val COLOR_KEY_LETTER_BG_PRESSED: Int = 0xFF3A3F49.toInt()
    const val COLOR_KEY_FUNCTION_BG: Int = 0xFF1C2028.toInt()
    const val COLOR_KEY_FUNCTION_BG_PRESSED: Int = 0xFF2A2F38.toInt()
    /** Brand enter — muted teal, not Material purple. */
    const val COLOR_KEY_ACCENT_BG: Int = 0xFF2A9B8F.toInt()
    const val COLOR_KEY_ACCENT_BG_PRESSED: Int = 0xFF34B3A5.toInt()
    const val COLOR_KEY_TEXT: Int = 0xFFF2F3F5.toInt()
    const val COLOR_KEY_TEXT_MUTED: Int = 0xFF8B929C.toInt()
    const val COLOR_KEY_TEXT_ACCENT: Int = 0xFFFFFFFF.toInt()
    const val COLOR_KEY_PREVIEW_BG: Int = 0xFF363B45.toInt()
    const val COLOR_KEY_PREVIEW_STROKE: Int = 0x40FFFFFF
    /** Hairline on letter/function keys — separates from flat Gboard look. */
    const val COLOR_KEY_STROKE: Int = 0x28FFFFFF
    const val COLOR_RIPPLE: Int = 0x28FFFFFF
    const val COLOR_DIVIDER: Int = 0x24FFFFFF
    const val COLOR_LONGPRESS_POPUP_BG: Int = 0xFF2A2F38.toInt()
    const val COLOR_LONGPRESS_POPUP_HIGHLIGHT: Int = COLOR_KEY_ACCENT_BG
    const val COLOR_TRANSPARENT: Int = Color.TRANSPARENT

    // --- Dimensions (dp) ----------------------------------------------------

    const val SUGGESTION_BAR_HEIGHT_DP_PHONE: Float = 36f
    const val SUGGESTION_BAR_HEIGHT_DP_PHONE_LAND: Float = 30f
    const val SUGGESTION_BAR_HEIGHT_DP_TABLET: Float = 40f

    // Key area height is computed adaptively from the current screen height
    // (see [keyAreaHeightDp]); these are only the clamp bounds so the
    // keyboard never becomes unusably small or absurdly tall.
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

    const val KEYBOARD_BOTTOM_PADDING_DP_PHONE: Float = 14f
    const val KEYBOARD_BOTTOM_PADDING_DP_PHONE_LAND: Float = 8f
    const val KEYBOARD_BOTTOM_PADDING_DP_TABLET: Float = 14f

    /**
     * Outer breathing room from screen edges (left/right). Keys stay
     * distinct islands — not flush to the bezel.
     */
    const val KEYBOARD_EDGE_INSET_DP: Float = 5f

    // Match Samsung/Yandex RU geometry: modest gutters, taller keys, soft radius.
    const val KEY_GRID_PADDING_X_DP: Float = 4f
    const val KEY_GRID_PADDING_Y_DP: Float = 4f
    const val KEY_HORIZONTAL_GAP_DP: Float = 5.5f
    const val KEY_VERTICAL_GAP_DP: Float = 6.5f
    /** Letter-row cap ≈ reference key height on phone. */
    const val KEY_MAX_ROW_HEIGHT_DP: Float = 54f
    /** Tiny paint inset only — gaps come from KEY_*_GAP, not from shrinking faces. */
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

    // --- Device-class heuristics (delegates to KeyboardSizing) -------------

    fun isTablet(configuration: Configuration): Boolean =
        KeyboardSizing.isTablet(configuration)

    fun isLandscape(configuration: Configuration): Boolean =
        KeyboardSizing.isLandscape(configuration)

    fun suggestionBarHeightDp(configuration: Configuration): Float =
        KeyboardSizing.suggestionBarHeightDp(configuration)

    /**
     * Adaptive key-grid height — see [KeyboardSizing.keyAreaHeightDp].
     */
    fun keyAreaHeightDp(configuration: Configuration): Float =
        KeyboardSizing.keyAreaHeightDp(configuration)

    fun keyboardBottomPaddingDp(configuration: Configuration): Float =
        KeyboardSizing.keyboardBottomPaddingDp(configuration)

    fun keyLabelTextSizeSp(configuration: Configuration): Float =
        KeyboardSizing.keyLabelTextSizeSp(configuration)
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
