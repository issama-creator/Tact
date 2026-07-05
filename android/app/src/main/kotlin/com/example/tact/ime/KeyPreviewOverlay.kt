package com.example.tact.ime

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Typeface
import android.util.AttributeSet
import android.view.View
import android.view.animation.DecelerateInterpolator

/**
 * Transparent overlay that draws the key-press preview and the long-press
 * alternatives popup.
 *
 * Sits on top of the [KeyGridView] inside the same FrameLayout. Its
 * `onDraw` runs only when there is something to show — otherwise the
 * View is invisible-to-draw (early return).
 *
 * All Paint / RectF / Rect instances are created once and reused; the
 * overlay never allocates on the hot path.
 */
class KeyPreviewOverlay @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
) : View(context, attrs, defStyleAttr) {

    // ── State ─────────────────────────────────────────────────────────

    private val metrics = Metrics(this)

    private var previewVisible = false
    private var previewLabel: String = ""
    private val previewKeyRect = RectF()
    private var previewAlpha: Float = 1f

    private var altsVisible = false
    private var altsLabels: List<String> = emptyList()
    private var altsSelectedIndex: Int = -1
    private val altsAnchorRect = RectF()
    private var altsAlpha: Float = 1f
    private val altsItemRect = RectF()
    private val altsPopupRect = RectF()

    // ── Paints (allocated once) ───────────────────────────────────────

    private val backgroundPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_PREVIEW_BG
        style = Paint.Style.FILL
    }

    private val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_PREVIEW_STROKE
        style = Paint.Style.STROKE
        strokeWidth = metrics.dp(Theme.KEY_PREVIEW_STROKE_WIDTH_DP)
    }

    private val previewTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_TEXT
        textSize = metrics.sp(Theme.KEY_PREVIEW_TEXT_SIZE_SP)
        textAlign = Paint.Align.CENTER
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
    }

    private val altsPopupPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_LONGPRESS_POPUP_BG
        style = Paint.Style.FILL
    }

    private val altsHighlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_LONGPRESS_POPUP_HIGHLIGHT
        style = Paint.Style.FILL
    }

    private val altsTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_TEXT
        textSize = metrics.sp(Theme.LONGPRESS_POPUP_TEXT_SIZE_SP)
        textAlign = Paint.Align.CENTER
    }

    private val textBounds = Rect()

    // ── Animators ─────────────────────────────────────────────────────

    private var previewAnim: ValueAnimator? = null
    private var altsAnim: ValueAnimator? = null

    init {
        setWillNotDraw(false)
        isClickable = false
        isFocusable = false
    }

    // ── Public API ────────────────────────────────────────────────────

    /** Show or update the single-key preview above [keyRect]. */
    fun showPreview(keyRect: RectF, label: String) {
        // If alternatives are visible, don't show the plain preview.
        if (altsVisible) return
        previewLabel = label
        previewKeyRect.set(keyRect)
        if (!previewVisible) {
            previewVisible = true
            animatePreview(from = 0f, to = 1f, durationMs = Theme.PREVIEW_FADE_IN_MS)
        }
        invalidate(previewInvalidateRect())
    }

    fun hidePreview() {
        if (!previewVisible) return
        animatePreview(from = previewAlpha, to = 0f, durationMs = Theme.PREVIEW_FADE_OUT_MS) {
            previewVisible = false
            invalidate()
        }
    }

    fun showAlternatives(
        keyRect: RectF,
        alternatives: List<String>,
        selectedIndex: Int = 0,
    ) {
        if (alternatives.isEmpty()) return
        altsLabels = alternatives
        altsSelectedIndex = selectedIndex.coerceIn(0, alternatives.size - 1)
        altsAnchorRect.set(keyRect)
        // Cancel the plain preview when alternatives take over.
        previewVisible = false
        if (!altsVisible) {
            altsVisible = true
            animateAlts(from = 0f, to = 1f, durationMs = Theme.PREVIEW_FADE_IN_MS)
        }
        computeAltsGeometry()
        invalidate(altsInvalidateRect())
    }

    fun updateAlternativesSelection(selectedIndex: Int) {
        if (!altsVisible) return
        val bounded = selectedIndex.coerceIn(0, altsLabels.size - 1)
        if (bounded == altsSelectedIndex) return
        altsSelectedIndex = bounded
        invalidate(altsInvalidateRect())
    }

    fun hideAlternatives() {
        if (!altsVisible) return
        animateAlts(from = altsAlpha, to = 0f, durationMs = Theme.PREVIEW_FADE_OUT_MS) {
            altsVisible = false
            altsLabels = emptyList()
            altsSelectedIndex = -1
            invalidate()
        }
    }

    /** Convert an (x, y) inside this view into a selected alternative index,
     *  or -1 when the pointer is outside the alternatives popup. */
    fun hitTestAlternatives(x: Float, y: Float): Int {
        if (!altsVisible || altsLabels.isEmpty()) return -1
        if (!altsPopupRect.contains(x, y)) return -1
        val itemWidth = altsPopupRect.width() / altsLabels.size
        val index = ((x - altsPopupRect.left) / itemWidth).toInt()
        return index.coerceIn(0, altsLabels.size - 1)
    }

    fun currentAlternatives(): List<String> = altsLabels

    // ── Drawing ───────────────────────────────────────────────────────

    override fun onDraw(canvas: Canvas) {
        if (previewVisible) {
            drawPreview(canvas)
        }
        if (altsVisible) {
            drawAlternatives(canvas)
        }
    }

    private fun drawPreview(canvas: Canvas) {
        val height = metrics.dp(Theme.KEY_PREVIEW_HEIGHT_DP)
        val lift = metrics.dp(Theme.KEY_PREVIEW_LIFT_DP)
        val width = maxOf(previewKeyRect.width() * 1.15f, metrics.dp(48f))
        val cx = previewKeyRect.centerX()
        val top = previewKeyRect.top - height - lift
        val left = cx - width / 2f
        val rect = tmpRectF.also { it.set(left, top, left + width, top + height) }
        val radius = metrics.dp(Theme.KEY_PREVIEW_CORNER_RADIUS_DP)

        val saved = canvas.saveLayerAlpha(rect, (previewAlpha * 255).toInt())
        canvas.drawRoundRect(rect, radius, radius, backgroundPaint)
        canvas.drawRoundRect(rect, radius, radius, strokePaint)
        val textY = rect.centerY() - (previewTextPaint.descent() + previewTextPaint.ascent()) / 2f
        canvas.drawText(previewLabel, rect.centerX(), textY, previewTextPaint)
        canvas.restoreToCount(saved)
    }

    private fun drawAlternatives(canvas: Canvas) {
        val radius = metrics.dp(Theme.LONGPRESS_POPUP_CORNER_RADIUS_DP)
        val saved = canvas.saveLayerAlpha(altsPopupRect, (altsAlpha * 255).toInt())
        canvas.drawRoundRect(altsPopupRect, radius, radius, altsPopupPaint)

        val itemWidth = altsPopupRect.width() / altsLabels.size
        val itemPadding = metrics.dp(Theme.LONGPRESS_POPUP_PADDING_DP)
        for (i in altsLabels.indices) {
            val itemLeft = altsPopupRect.left + i * itemWidth
            altsItemRect.set(
                itemLeft + itemPadding,
                altsPopupRect.top + itemPadding,
                itemLeft + itemWidth - itemPadding,
                altsPopupRect.bottom - itemPadding,
            )
            if (i == altsSelectedIndex) {
                canvas.drawRoundRect(altsItemRect, radius, radius, altsHighlightPaint)
            }
            val textY = altsItemRect.centerY() -
                (altsTextPaint.descent() + altsTextPaint.ascent()) / 2f
            canvas.drawText(altsLabels[i], altsItemRect.centerX(), textY, altsTextPaint)
        }

        canvas.restoreToCount(saved)
    }

    // ── Geometry ──────────────────────────────────────────────────────

    private fun computeAltsGeometry() {
        val itemW = metrics.dp(Theme.LONGPRESS_POPUP_ITEM_WIDTH_DP)
        val itemH = metrics.dp(Theme.LONGPRESS_POPUP_ITEM_HEIGHT_DP)
        val padding = metrics.dp(Theme.LONGPRESS_POPUP_PADDING_DP)
        val count = altsLabels.size
        val totalW = itemW * count + padding * 2f
        val totalH = itemH + padding * 2f

        val cx = altsAnchorRect.centerX()
        var left = cx - totalW / 2f
        var right = left + totalW

        // Clamp horizontally to the view's bounds.
        val viewWidth = width.toFloat()
        if (left < 0f) {
            left = 0f
            right = totalW
        } else if (right > viewWidth) {
            right = viewWidth
            left = viewWidth - totalW
        }

        val bottom = altsAnchorRect.top - metrics.dp(Theme.KEY_PREVIEW_LIFT_DP)
        val top = bottom - totalH

        altsPopupRect.set(left, top, right, bottom)
    }

    private fun previewInvalidateRect(): Rect {
        val height = metrics.dp(Theme.KEY_PREVIEW_HEIGHT_DP)
        val lift = metrics.dp(Theme.KEY_PREVIEW_LIFT_DP)
        val width = maxOf(previewKeyRect.width() * 1.15f, metrics.dp(48f))
        val cx = previewKeyRect.centerX()
        val top = previewKeyRect.top - height - lift
        val left = cx - width / 2f
        tmpInvalidateRect.set(
            (left - 4).toInt(),
            (top - 4).toInt(),
            (left + width + 4).toInt(),
            (top + height + 4).toInt(),
        )
        return tmpInvalidateRect
    }

    private fun altsInvalidateRect(): Rect {
        tmpInvalidateRect.set(
            (altsPopupRect.left - 4).toInt(),
            (altsPopupRect.top - 4).toInt(),
            (altsPopupRect.right + 4).toInt(),
            (altsPopupRect.bottom + 4).toInt(),
        )
        return tmpInvalidateRect
    }

    // ── Animation helpers ─────────────────────────────────────────────

    private fun animatePreview(
        from: Float,
        to: Float,
        durationMs: Long,
        onEnd: (() -> Unit)? = null,
    ) {
        previewAnim?.cancel()
        val a = ValueAnimator.ofFloat(from, to).apply {
            duration = durationMs
            interpolator = decelerate
            addUpdateListener {
                previewAlpha = it.animatedValue as Float
                invalidate(previewInvalidateRect())
            }
        }
        previewAnim = a
        if (onEnd != null) {
            a.addListener(object : android.animation.AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: android.animation.Animator) {
                    onEnd()
                }
            })
        }
        a.start()
    }

    private fun animateAlts(
        from: Float,
        to: Float,
        durationMs: Long,
        onEnd: (() -> Unit)? = null,
    ) {
        altsAnim?.cancel()
        val a = ValueAnimator.ofFloat(from, to).apply {
            duration = durationMs
            interpolator = decelerate
            addUpdateListener {
                altsAlpha = it.animatedValue as Float
                invalidate(altsInvalidateRect())
            }
        }
        altsAnim = a
        if (onEnd != null) {
            a.addListener(object : android.animation.AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: android.animation.Animator) {
                    onEnd()
                }
            })
        }
        a.start()
    }

    // ── Reused temporaries (avoid allocations in onDraw / invalidate) ─

    private val tmpRectF = RectF()
    private val tmpInvalidateRect = Rect()
    private val decelerate = DecelerateInterpolator()
}
