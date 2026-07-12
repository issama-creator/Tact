package com.example.tact.ime

import android.content.res.Configuration

/**
 * Continuous adaptive sizing for the IME surface.
 *
 * Goals:
 * - Same finger feel on small phones, large phones, folds, and tablets.
 * - Wide screens: content capped and centered (Gboard-style), keys do not
 *   stretch across the full tablet width.
 * - Scale is continuous from [screenWidthDp], not a binary phone/tablet switch.
 */
object KeyboardSizing {

    enum class DeviceClass {
        PHONE,
        LARGE_PHONE,
        TABLET,
    }

    /** Reference width for scale = 1.0 (typical phone). */
    private const val REF_WIDTH_DP = 360f

    private const val SCALE_MIN = 0.92f
    private const val SCALE_MAX = 1.12f

    /** Gboard-like content ceiling on tablets. */
    const val CONTENT_MAX_WIDTH_DP = 640f

    fun deviceClass(configuration: Configuration): DeviceClass {
        val sw = configuration.smallestScreenWidthDp
        return when {
            sw >= 600 -> DeviceClass.TABLET
            sw >= 480 -> DeviceClass.LARGE_PHONE
            else -> DeviceClass.PHONE
        }
    }

    fun isTablet(configuration: Configuration): Boolean =
        deviceClass(configuration) == DeviceClass.TABLET

    fun isLandscape(configuration: Configuration): Boolean =
        configuration.orientation == Configuration.ORIENTATION_LANDSCAPE

    /**
     * Continuous scale from screen width. Uses the shorter of width/height
     * so landscape phones don't inflate gaps just because width jumped.
     */
    fun keyboardScale(configuration: Configuration): Float {
        val w = configuration.screenWidthDp.toFloat().coerceAtLeast(1f)
        val h = configuration.screenHeightDp.toFloat().coerceAtLeast(1f)
        // Content-effective width: after max-width cap on large screens.
        val effective = minOf(w, contentMaxWidthDp(configuration))
        val raw = effective / REF_WIDTH_DP
        return raw.coerceIn(SCALE_MIN, SCALE_MAX)
    }

    /**
     * Max width of the key grid + suggestion bar in dp.
     * Phones (incl. landscape): always full width — edge-to-edge.
     * Tablets only: cap and center so keys don't stretch across the slab.
     */
    fun contentMaxWidthDp(configuration: Configuration): Float {
        val screenW = configuration.screenWidthDp.toFloat().coerceAtLeast(1f)
        return if (isTablet(configuration)) {
            minOf(screenW, CONTENT_MAX_WIDTH_DP)
        } else {
            screenW
        }
    }

    /** Horizontal inset (each side) so content is centered in the IME window. */
    fun contentSideInsetDp(configuration: Configuration): Float {
        val screenW = configuration.screenWidthDp.toFloat().coerceAtLeast(1f)
        val content = contentMaxWidthDp(configuration)
        return ((screenW - content) / 2f).coerceAtLeast(0f)
    }

    fun suggestionBarHeightDp(configuration: Configuration): Float {
        val scale = keyboardScale(configuration)
        val base = when {
            isTablet(configuration) -> Theme.SUGGESTION_BAR_HEIGHT_DP_TABLET
            isLandscape(configuration) -> Theme.SUGGESTION_BAR_HEIGHT_DP_PHONE_LAND
            else -> Theme.SUGGESTION_BAR_HEIGHT_DP_PHONE
        }
        return (base * scale).coerceIn(28f, 48f)
    }

    /**
     * Key-grid height sized to fit 4 capped rows + gutters — avoids an empty
     * dark band under the suggestion bar that looks like a broken panel.
     */
    fun keyAreaHeightDp(configuration: Configuration): Float {
        val land = isLandscape(configuration)
        val tablet = isTablet(configuration)
        val large = deviceClass(configuration) == DeviceClass.LARGE_PHONE

        // 4×44 + 3×6.5 + 2×4 ≈ 203.5dp — keep phone band tight around that.
        when {
            tablet && land -> return 240f
            tablet -> return 260f
            land -> return 160f
            large -> return 210f
            else -> return 204f
        }
    }

    fun keyboardBottomPaddingDp(configuration: Configuration): Float {
        val scale = keyboardScale(configuration)
        val base = when {
            isTablet(configuration) -> Theme.KEYBOARD_BOTTOM_PADDING_DP_TABLET
            isLandscape(configuration) -> Theme.KEYBOARD_BOTTOM_PADDING_DP_PHONE_LAND
            else -> Theme.KEYBOARD_BOTTOM_PADDING_DP_PHONE
        }
        return base * scale
    }

    /** Left/right inset so the key block breathes from the bezel. */
    fun edgeInsetDp(configuration: Configuration): Float {
        val scale = keyboardScale(configuration)
        val base = if (isTablet(configuration)) {
            Theme.KEYBOARD_EDGE_INSET_DP + 4f
        } else {
            Theme.KEYBOARD_EDGE_INSET_DP
        }
        return base * scale
    }

    // ── Scaled chrome (dp / sp) ──────────────────────────────────────────

    fun keyGridPaddingXDp(configuration: Configuration): Float =
        Theme.KEY_GRID_PADDING_X_DP

    fun keyGridPaddingYDp(configuration: Configuration): Float =
        Theme.KEY_GRID_PADDING_Y_DP * keyboardScale(configuration)

    fun keyHorizontalGapDp(configuration: Configuration): Float =
        Theme.KEY_HORIZONTAL_GAP_DP * keyboardScale(configuration)

    fun keyVerticalGapDp(configuration: Configuration): Float =
        Theme.KEY_VERTICAL_GAP_DP * keyboardScale(configuration)

    fun keyMaxRowHeightDp(configuration: Configuration): Float =
        // Don't scale this up on large phones — tall rows are the bug.
        Theme.KEY_MAX_ROW_HEIGHT_DP.coerceAtMost(44f)

    fun keyDrawInsetHDp(configuration: Configuration): Float =
        Theme.KEY_DRAW_INSET_H_DP

    fun keyDrawInsetVDp(configuration: Configuration): Float =
        Theme.KEY_DRAW_INSET_V_DP * keyboardScale(configuration)

    fun keyStrokeWidthDp(configuration: Configuration): Float =
        Theme.KEY_STROKE_WIDTH_DP

    fun keyCornerRadiusDp(configuration: Configuration): Float =
        Theme.KEY_CORNER_RADIUS_DP * keyboardScale(configuration)

    fun keyLabelTextSizeSp(configuration: Configuration): Float {
        val base = if (isTablet(configuration)) {
            Theme.KEY_LABEL_TEXT_SIZE_SP_TABLET
        } else {
            Theme.KEY_LABEL_TEXT_SIZE_SP
        }
        return (base * keyboardScale(configuration)).coerceIn(18f, 26f)
    }

    fun keySubLabelTextSizeSp(configuration: Configuration): Float =
        (Theme.KEY_SUB_LABEL_TEXT_SIZE_SP * keyboardScale(configuration)).coerceIn(8f, 12f)

    fun keyFunctionTextSizeSp(configuration: Configuration): Float =
        (Theme.KEY_FUNCTION_TEXT_SIZE_SP * keyboardScale(configuration)).coerceIn(12f, 17f)

    fun keyPreviewHeightDp(configuration: Configuration): Float =
        Theme.KEY_PREVIEW_HEIGHT_DP * keyboardScale(configuration)

    fun keyPreviewLiftDp(configuration: Configuration): Float =
        Theme.KEY_PREVIEW_LIFT_DP * keyboardScale(configuration)

    fun keyPreviewCornerRadiusDp(configuration: Configuration): Float =
        Theme.KEY_PREVIEW_CORNER_RADIUS_DP * keyboardScale(configuration)

    fun keyPreviewTextSizeSp(configuration: Configuration): Float =
        Theme.KEY_PREVIEW_TEXT_SIZE_SP * keyboardScale(configuration)

    fun keyPreviewStrokeWidthDp(configuration: Configuration): Float =
        Theme.KEY_PREVIEW_STROKE_WIDTH_DP * keyboardScale(configuration)

    fun longPressPopupItemWidthDp(configuration: Configuration): Float =
        Theme.LONGPRESS_POPUP_ITEM_WIDTH_DP * keyboardScale(configuration)

    fun longPressPopupItemHeightDp(configuration: Configuration): Float =
        Theme.LONGPRESS_POPUP_ITEM_HEIGHT_DP * keyboardScale(configuration)

    fun longPressPopupCornerRadiusDp(configuration: Configuration): Float =
        Theme.LONGPRESS_POPUP_CORNER_RADIUS_DP * keyboardScale(configuration)

    fun longPressPopupTextSizeSp(configuration: Configuration): Float =
        Theme.LONGPRESS_POPUP_TEXT_SIZE_SP * keyboardScale(configuration)

    fun longPressPopupPaddingDp(configuration: Configuration): Float =
        Theme.LONGPRESS_POPUP_PADDING_DP * keyboardScale(configuration)

    fun estimatedLetterKeyWidthDp(configuration: Configuration): Float {
        val content = contentMaxWidthDp(configuration)
        val pad = keyGridPaddingXDp(configuration) * 2f
        // Always estimate against the 12-slot RU row (canonical letter size).
        val gaps = keyHorizontalGapDp(configuration) * 11f
        return ((content - pad - gaps) / 12f).coerceAtLeast(1f)
    }

    fun contentWidthPx(configuration: Configuration, metrics: Metrics): Int =
        metrics.dpInt(contentMaxWidthDp(configuration))

    fun contentSideInsetPx(configuration: Configuration, metrics: Metrics): Int =
        metrics.dpInt(contentSideInsetDp(configuration)).coerceAtLeast(0)
}
