package com.example.tact.ime

import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.Typeface
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.AttributeSet
import android.util.SparseArray
import android.view.MotionEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import java.util.Locale
import kotlin.math.abs

/**
 * The keyboard's key grid.
 *
 * All rendering is native (Canvas) and all input goes straight to
 * [InputController] — the Flutter/Dart layer is not on the keypress path.
 *
 * Responsibilities:
 *   • Compute key rectangles for the current [layer] on every size change
 *     or layer swap.
 *   • Render keys, labels, sub-labels, and function-key icons.
 *   • Handle multi-touch: track each active pointer, run long-press timers,
 *     coordinate the [KeyPreviewOverlay], commit or cancel on release.
 *   • Space-bar horizontal slide → cursor movement.
 *   • Backspace long-press → accelerating repeat, then word-delete.
 *   • Shift double-tap → caps lock.
 *   • Long-press alternatives via [KeyPreviewOverlay.showAlternatives].
 *
 * Zero allocations on the drawing path; a few on ACTION_DOWN (a
 * [PointerState]) which is not the mid-typing hot path.
 */
class KeyGridView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0,
) : View(context, attrs, defStyleAttr) {

    // ── Injected collaborators (set by KeyboardRootView) ──────────────

    lateinit var state: KeyboardState
    lateinit var inputController: InputController
    lateinit var haptics: KeyboardHaptics
    var previewOverlay: KeyPreviewOverlay? = null

    /** Emitted after a word boundary is committed. Wired to the bridge. */
    var onWordCommitted: ((String) -> Unit)? = null

    /** Opens the system keyboard chooser (long-press 🌐). */
    var onShowImePicker: (() -> Unit)? = null

    /** Cycles to the next enabled IME (tap 🌐). */
    var onSwitchToNextIme: (() -> Unit)? = null

    // ── Layout ────────────────────────────────────────────────────────

    private var layer: KeyboardLayer = Layouts.qwertyEn
    private val keyRects = ArrayList<KeyRect>(64)
    private val metrics = Metrics(this)

    // Reused temporaries.
    private val tmpRectF = RectF()
    private val tmpRect = Rect()
    private val iconPath = Path()

    // ── Paints (allocated once) ───────────────────────────────────────

    private val letterKeyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_LETTER_BG; style = Paint.Style.FILL
    }
    private val letterKeyPressedPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_LETTER_BG_PRESSED; style = Paint.Style.FILL
    }
    private val functionKeyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_FUNCTION_BG; style = Paint.Style.FILL
    }
    private val functionKeyPressedPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_FUNCTION_BG_PRESSED; style = Paint.Style.FILL
    }
    private val accentKeyPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_ACCENT_BG; style = Paint.Style.FILL
    }
    private val accentKeyPressedPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_ACCENT_BG_PRESSED; style = Paint.Style.FILL
    }
    private val labelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_TEXT
        textAlign = Paint.Align.CENTER
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.NORMAL)
    }
    private val subLabelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_TEXT_MUTED
        textAlign = Paint.Align.CENTER
    }
    private val functionLabelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_TEXT_MUTED
        textAlign = Paint.Align.CENTER
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
    }
    private val accentLabelPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_TEXT_ACCENT
        textAlign = Paint.Align.CENTER
        typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
    }
    private val iconPaintStroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_TEXT
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
        strokeJoin = Paint.Join.ROUND
    }
    private val iconPaintFill = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_KEY_TEXT; style = Paint.Style.FILL
    }
    private val ripplePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Theme.COLOR_RIPPLE; style = Paint.Style.FILL
    }

    // Set at first size-change.
    private var keyLabelTextSize: Float = 0f
    private var subLabelTextSize: Float = 0f
    private var functionLabelTextSize: Float = 0f
    private var cornerRadius: Float = 0f

    // ── Touch tracking ────────────────────────────────────────────────

    private val pointers = SparseArray<PointerState>()
    private val handler = Handler(Looper.getMainLooper())
    private val spaceSlideThresholdPx by lazy { metrics.dp(Theme.SPACE_CURSOR_SLIDE_THRESHOLD_DP) }
    private val spaceStepPx by lazy { metrics.dp(9f) }

    // ── Ripples ───────────────────────────────────────────────────────

    private data class Ripple(
        val cx: Float,
        val cy: Float,
        val clip: RectF,
        var radius: Float,
        var alpha: Int,
        val maxRadius: Float,
        val animator: ValueAnimator,
    )

    private val ripples = ArrayList<Ripple>(4)

    // ── Configuration hint ────────────────────────────────────────────

    init {
        setWillNotDraw(false)
        isClickable = true
        isFocusable = false
        setBackgroundColor(Theme.COLOR_KEYBOARD_BG)
    }

    // ── Public API (called by KeyboardRootView) ───────────────────────

    fun setLayer(newLayer: KeyboardLayer) {
        if (layer === newLayer) return
        // Cancel any active gestures when the layer changes under the finger.
        clearAllPointers()
        layer = newLayer
        if (width > 0 && height > 0) {
            computeKeyRects()
            invalidate()
        }
    }

    fun refreshFromState() {
        // Called after state.shift / layer / language change. The pure-shift
        // case leaves the layer identical — setLayer would short-circuit —
        // so we always force a full redraw here to reflect casing and the
        // shift-key icon state.
        val target = Layouts.layerFor(state)
        if (target !== layer) {
            setLayer(target)
        } else {
            invalidate()
        }
    }

    // ── Sizing ────────────────────────────────────────────────────────

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        val cfg = resources.configuration
        keyLabelTextSize = metrics.sp(Theme.keyLabelTextSizeSp(cfg))
        subLabelTextSize = metrics.sp(Theme.KEY_SUB_LABEL_TEXT_SIZE_SP)
        functionLabelTextSize = metrics.sp(Theme.KEY_FUNCTION_TEXT_SIZE_SP)
        cornerRadius = metrics.dp(Theme.KEY_CORNER_RADIUS_DP)
        labelPaint.textSize = keyLabelTextSize
        subLabelPaint.textSize = subLabelTextSize
        functionLabelPaint.textSize = functionLabelTextSize
        accentLabelPaint.textSize = functionLabelTextSize
        iconPaintStroke.strokeWidth = metrics.dp(2f)
        computeKeyRects()
    }

    private fun computeKeyRects() {
        keyRects.clear()
        val rows = layer.rows
        if (rows.isEmpty() || width <= 0 || height <= 0) return

        val hGap = metrics.dp(Theme.KEY_HORIZONTAL_GAP_DP)
        val vGap = metrics.dp(Theme.KEY_VERTICAL_GAP_DP)
        val paddingX = metrics.dp(Theme.KEY_GRID_PADDING_X_DP)
        val paddingY = metrics.dp(Theme.KEY_GRID_PADDING_Y_DP)

        val totalHeightWeight = rows.sumOf { it.heightWeight.toDouble() }.toFloat()
        val usableHeight = (height - paddingY * 2) - vGap * (rows.size - 1)
        val rowUnitHeight = usableHeight / totalHeightWeight

        var y = paddingY
        for (rowIndex in rows.indices) {
            val row = rows[rowIndex]
            val rowHeight = rowUnitHeight * row.heightWeight
            val totalKeyWeight = row.keys.sumOf { it.weight.toDouble() }.toFloat()
            val usableWidth = (width - paddingX * 2) - hGap * (row.keys.size - 1)
            val keyUnitWidth = usableWidth / totalKeyWeight

            var x = paddingX
            for (keyIndex in row.keys.indices) {
                val key = row.keys[keyIndex]
                val keyW = keyUnitWidth * key.weight
                val rect = RectF(x, y, x + keyW, y + rowHeight)
                keyRects.add(KeyRect(key, rect, rowIndex, keyIndex))
                x += keyW + hGap
            }
            y += rowHeight + vGap
        }
    }

    // ── Drawing ───────────────────────────────────────────────────────

    override fun onDraw(canvas: Canvas) {
        // Canvas is already colored by the background; the key backgrounds
        // are opaque so there's no need to fill again.
        for (i in keyRects.indices) {
            drawKey(canvas, keyRects[i])
        }
        if (ripples.isNotEmpty()) {
            for (i in ripples.indices) {
                drawRipple(canvas, ripples[i])
            }
        }
    }

    private fun drawKey(canvas: Canvas, kr: KeyRect) {
        val key = kr.key
        val rect = kr.rect

        val (bg, pressedBg, isAccent) = paletteFor(key)
        val paint = if (kr.pressed) pressedBg else bg
        canvas.drawRoundRect(rect, cornerRadius, cornerRadius, paint)

        when (val action = key.action) {
            is KeyAction.Character -> drawCharacterKey(canvas, kr, action)
            KeyAction.Shift -> drawShiftIcon(canvas, rect)
            KeyAction.Backspace -> drawBackspaceIcon(canvas, rect)
            KeyAction.Space -> drawSpaceLabel(canvas, rect)
            KeyAction.Enter -> drawEnterKey(canvas, rect, isAccent)
            KeyAction.LanguageSwitch -> drawGlobeIcon(canvas, rect)
            is KeyAction.LayerSwitch -> drawLayerLabel(canvas, rect, action)
            KeyAction.Emoji -> drawEmojiIcon(canvas, rect)
        }
    }

    private data class KeyPalette(
        val normal: Paint,
        val pressed: Paint,
        val isAccent: Boolean,
    )

    private val paletteLetter = KeyPalette(letterKeyPaint, letterKeyPressedPaint, false)
    private val paletteFunction = KeyPalette(functionKeyPaint, functionKeyPressedPaint, false)
    private val paletteAccent = KeyPalette(accentKeyPaint, accentKeyPressedPaint, true)

    private fun paletteFor(key: Key): KeyPalette = when (key.action) {
        is KeyAction.Character -> paletteLetter
        KeyAction.Space -> paletteFunction
        KeyAction.Enter -> paletteAccent
        else -> paletteFunction
    }

    private fun drawCharacterKey(canvas: Canvas, kr: KeyRect, action: KeyAction.Character) {
        val rect = kr.rect
        val label = if (state.isUpperCase) {
            (action.labelUpper ?: action.label.uppercase(Locale.forLanguageTag(state.language.tag)))
        } else {
            action.label
        }
        val cy = rect.centerY() - (labelPaint.descent() + labelPaint.ascent()) / 2f
        canvas.drawText(label, rect.centerX(), cy, labelPaint)

        val sub = kr.key.subLabel
        if (sub != null) {
            val padX = rect.width() * 0.16f
            val padY = subLabelPaint.textSize * 1.2f
            canvas.drawText(sub, rect.right - padX, rect.top + padY, subLabelPaint)
        }
    }

    private fun drawShiftIcon(canvas: Canvas, rect: RectF) {
        val size = minOf(rect.width(), rect.height()) * 0.42f
        val cx = rect.centerX()
        val cy = rect.centerY()
        iconPath.rewind()
        iconPath.moveTo(cx, cy - size * 0.55f)
        iconPath.lineTo(cx - size * 0.55f, cy)
        iconPath.lineTo(cx - size * 0.28f, cy)
        iconPath.lineTo(cx - size * 0.28f, cy + size * 0.42f)
        iconPath.lineTo(cx + size * 0.28f, cy + size * 0.42f)
        iconPath.lineTo(cx + size * 0.28f, cy)
        iconPath.lineTo(cx + size * 0.55f, cy)
        iconPath.close()

        when (state.shift) {
            ShiftState.OFF -> {
                iconPaintStroke.color = Theme.COLOR_KEY_TEXT_MUTED
                canvas.drawPath(iconPath, iconPaintStroke)
            }
            ShiftState.ON -> {
                iconPaintFill.color = Theme.COLOR_KEY_TEXT
                canvas.drawPath(iconPath, iconPaintFill)
            }
            ShiftState.LOCKED -> {
                iconPaintFill.color = Theme.COLOR_KEY_TEXT
                canvas.drawPath(iconPath, iconPaintFill)
                val underlineY = cy + size * 0.62f
                canvas.drawRect(
                    cx - size * 0.5f, underlineY,
                    cx + size * 0.5f, underlineY + metrics.dp(2f),
                    iconPaintFill,
                )
            }
        }
    }

    private fun drawBackspaceIcon(canvas: Canvas, rect: RectF) {
        val size = minOf(rect.width(), rect.height()) * 0.45f
        val cx = rect.centerX()
        val cy = rect.centerY()
        iconPaintStroke.color = Theme.COLOR_KEY_TEXT
        // Outline shape:  ⌫
        iconPath.rewind()
        iconPath.moveTo(cx - size * 0.6f, cy)
        iconPath.lineTo(cx - size * 0.25f, cy - size * 0.42f)
        iconPath.lineTo(cx + size * 0.55f, cy - size * 0.42f)
        iconPath.lineTo(cx + size * 0.55f, cy + size * 0.42f)
        iconPath.lineTo(cx - size * 0.25f, cy + size * 0.42f)
        iconPath.close()
        canvas.drawPath(iconPath, iconPaintStroke)
        // Inner X.
        canvas.drawLine(
            cx - size * 0.05f, cy - size * 0.22f,
            cx + size * 0.35f, cy + size * 0.22f,
            iconPaintStroke,
        )
        canvas.drawLine(
            cx + size * 0.35f, cy - size * 0.22f,
            cx - size * 0.05f, cy + size * 0.22f,
            iconPaintStroke,
        )
    }

    private fun drawGlobeIcon(canvas: Canvas, rect: RectF) {
        val r = minOf(rect.width(), rect.height()) * 0.28f
        val cx = rect.centerX()
        val cy = rect.centerY()
        iconPaintStroke.color = Theme.COLOR_KEY_TEXT
        canvas.drawCircle(cx, cy, r, iconPaintStroke)
        // Vertical meridian.
        canvas.drawLine(cx, cy - r, cx, cy + r, iconPaintStroke)
        // Curved horizontal.
        tmpRectF.set(cx - r, cy - r * 0.5f, cx + r, cy + r * 0.5f)
        canvas.drawOval(tmpRectF, iconPaintStroke)
    }

    private fun drawEnterKey(canvas: Canvas, rect: RectF, isAccent: Boolean) {
        val label = inputController.effectiveImeAction()?.let { enterLabelFor(it) }
        if (label != null) {
            val paint = if (isAccent) accentLabelPaint else functionLabelPaint
            val originalSize = paint.textSize
            // Auto-fit the label to the key width so "Отправить" / "Search"
            // never overflow on narrow keys.
            val maxWidth = rect.width() * 0.86f
            var size = originalSize
            while (size > 9f && paint.measureText(label) > maxWidth) {
                size -= 1f
                paint.textSize = size
            }
            val cy = rect.centerY() - (paint.descent() + paint.ascent()) / 2f
            canvas.drawText(label, rect.centerX(), cy, paint)
            paint.textSize = originalSize
        } else {
            drawReturnArrow(canvas, rect, isAccent)
        }
    }

    private fun drawReturnArrow(canvas: Canvas, rect: RectF, isAccent: Boolean) {
        val size = minOf(rect.width(), rect.height()) * 0.35f
        val cx = rect.centerX()
        val cy = rect.centerY()
        iconPaintStroke.color = if (isAccent) Theme.COLOR_KEY_TEXT_ACCENT else Theme.COLOR_KEY_TEXT
        // Vertical stem down + horizontal to left arrowhead.
        canvas.drawLine(cx + size * 0.7f, cy - size * 0.55f, cx + size * 0.7f, cy, iconPaintStroke)
        canvas.drawLine(cx + size * 0.7f, cy, cx - size * 0.6f, cy, iconPaintStroke)
        // Arrowhead.
        canvas.drawLine(cx - size * 0.6f, cy, cx - size * 0.25f, cy - size * 0.3f, iconPaintStroke)
        canvas.drawLine(cx - size * 0.6f, cy, cx - size * 0.25f, cy + size * 0.3f, iconPaintStroke)
    }

    private fun drawSpaceLabel(canvas: Canvas, rect: RectF) {
        // A subtle language indicator centered on the space bar.
        val text = state.language.label
        val paint = subLabelPaint
        paint.textSize = functionLabelTextSize
        val cy = rect.centerY() - (paint.descent() + paint.ascent()) / 2f
        canvas.drawText(text, rect.centerX(), cy, paint)
        paint.textSize = subLabelTextSize
    }

    private fun drawLayerLabel(canvas: Canvas, rect: RectF, action: KeyAction.LayerSwitch) {
        val label = when (action.target) {
            LayerKind.ALPHA -> "ABC"
            LayerKind.SYMBOLS -> "?123"
            LayerKind.SYMBOLS_ALT -> "=\\<"
            LayerKind.NUMBERS -> "123"
        }
        val paint = functionLabelPaint
        val cy = rect.centerY() - (paint.descent() + paint.ascent()) / 2f
        canvas.drawText(label, rect.centerX(), cy, paint)
    }

    private fun drawEmojiIcon(canvas: Canvas, rect: RectF) {
        val r = minOf(rect.width(), rect.height()) * 0.28f
        val cx = rect.centerX()
        val cy = rect.centerY()
        iconPaintStroke.color = Theme.COLOR_KEY_TEXT
        canvas.drawCircle(cx, cy, r, iconPaintStroke)
        canvas.drawCircle(cx - r * 0.35f, cy - r * 0.1f, r * 0.1f, iconPaintFill.apply {
            color = Theme.COLOR_KEY_TEXT
        })
        canvas.drawCircle(cx + r * 0.35f, cy - r * 0.1f, r * 0.1f, iconPaintFill)
        tmpRectF.set(cx - r * 0.45f, cy - r * 0.2f, cx + r * 0.45f, cy + r * 0.5f)
        canvas.drawArc(tmpRectF, 20f, 140f, false, iconPaintStroke)
    }

    private fun drawRipple(canvas: Canvas, ripple: Ripple) {
        val saved = canvas.save()
        canvas.clipRect(ripple.clip)
        ripplePaint.alpha = ripple.alpha
        canvas.drawCircle(ripple.cx, ripple.cy, ripple.radius, ripplePaint)
        canvas.restoreToCount(saved)
    }

    private fun enterLabelFor(actionId: Int): String? {
        val ru = state.language == LanguageKind.RU
        return when (actionId) {
            EditorInfo.IME_ACTION_GO -> if (ru) "Перейти" else "Go"
            EditorInfo.IME_ACTION_SEND -> if (ru) "Отправить" else "Send"
            EditorInfo.IME_ACTION_DONE -> if (ru) "Готово" else "Done"
            EditorInfo.IME_ACTION_SEARCH -> if (ru) "Поиск" else "Search"
            EditorInfo.IME_ACTION_NEXT -> if (ru) "Далее" else "Next"
            EditorInfo.IME_ACTION_PREVIOUS -> if (ru) "Назад" else "Prev"
            else -> null
        }
    }

    // ── Touch handling ────────────────────────────────────────────────

    override fun onTouchEvent(event: MotionEvent): Boolean {
        val action = event.actionMasked
        when (action) {
            MotionEvent.ACTION_DOWN,
            MotionEvent.ACTION_POINTER_DOWN -> {
                val idx = event.actionIndex
                val pid = event.getPointerId(idx)
                onPointerDown(pid, event.getX(idx), event.getY(idx))
            }
            MotionEvent.ACTION_MOVE -> {
                var i = 0
                while (i < event.pointerCount) {
                    val pid = event.getPointerId(i)
                    onPointerMove(pid, event.getX(i), event.getY(i))
                    i++
                }
            }
            MotionEvent.ACTION_UP,
            MotionEvent.ACTION_POINTER_UP -> {
                val idx = event.actionIndex
                val pid = event.getPointerId(idx)
                onPointerUp(pid, event.getX(idx), event.getY(idx))
            }
            MotionEvent.ACTION_CANCEL -> {
                clearAllPointers()
            }
        }
        return true
    }

    private fun onPointerDown(pid: Int, x: Float, y: Float) {
        val kr = keyAt(x, y) ?: return

        kr.pressed = true
        val ps = PointerState(
            keyRect = kr,
            downX = x,
            downY = y,
            downTime = SystemClock.uptimeMillis(),
            lastX = x,
            lastY = y,
        )
        pointers.put(pid, ps)

        // Immediate feedback. Sound is played on RELEASE (see commitCharacter)
        // so that a slide-off does not produce a beep.
        haptics.keyTap(this)
        startRippleAt(kr, x, y)
        maybeShowPreview(kr)
        invalidateRect(kr.rect)

        // Long-press / repeat scheduling.
        val longPressRun = Runnable { onLongPress(pid) }
        ps.longPressRunnable = longPressRun
        val delay = when (kr.key.action) {
            KeyAction.Backspace -> Theme.BACKSPACE_INITIAL_DELAY_MS
            else -> Theme.LONG_PRESS_TRIGGER_MS
        }
        handler.postDelayed(longPressRun, delay)
    }

    private fun onPointerMove(pid: Int, x: Float, y: Float) {
        val ps = pointers[pid] ?: return
        val prevKr = ps.keyRect
        ps.lastX = x
        ps.lastY = y

        // If alternatives are open on this pointer, update the selection
        // by hit-testing inside the overlay. KeyGridView and
        // KeyPreviewOverlay share the same parent FrameLayout with matching
        // size and origin, so (x, y) is directly usable in the overlay.
        if (ps.altsActive) {
            val overlay = previewOverlay ?: return
            val idxInOverlay = overlay.hitTestAlternatives(x, y)
            if (idxInOverlay >= 0) {
                overlay.updateAlternativesSelection(idxInOverlay)
                ps.altsSelectedIndex = idxInOverlay
            }
            return
        }

        // Space-bar horizontal slide → cursor movement.
        if (prevKr.key.action == KeyAction.Space) {
            val dx = x - ps.downX
            if (!ps.spaceCursorActive && abs(dx) > spaceSlideThresholdPx) {
                ps.spaceCursorActive = true
                ps.spaceAccum = 0f
                // Anchor the step baseline to the current point so the first
                // cursor move isn't a jump of `threshold` worth of steps.
                ps.spaceLastX = x
                cancelLongPress(ps)
                hidePreviewFor(ps)
            }
            if (ps.spaceCursorActive) {
                val stepDx = x - ps.spaceLastX
                ps.spaceLastX = x
                ps.spaceAccum += stepDx
                while (ps.spaceAccum >= spaceStepPx) {
                    inputController.moveCursorBy(1)
                    ps.spaceAccum -= spaceStepPx
                }
                while (ps.spaceAccum <= -spaceStepPx) {
                    inputController.moveCursorBy(-1)
                    ps.spaceAccum += spaceStepPx
                }
                return
            }
        }

        // If the finger has drifted onto a different key, update the preview
        // and cancel timers for the previous key.
        val nowKr = keyAt(x, y)
        if (nowKr != null && nowKr !== prevKr) {
            // Cancel state on the previous key.
            prevKr.pressed = false
            cancelLongPress(ps)
            invalidateRect(prevKr.rect)
            // Adopt the new key only for pure letter/symbol keys — Gboard-like
            // sliding on function keys is disallowed (never accidentally
            // switch layers via slide).
            if (nowKr.key.action is KeyAction.Character) {
                ps.keyRect = nowKr
                nowKr.pressed = true
                invalidateRect(nowKr.rect)
                maybeShowPreview(nowKr)
                // Reschedule a long-press timer for the new key.
                val newRun = Runnable { onLongPress(pid) }
                ps.longPressRunnable = newRun
                handler.postDelayed(newRun, Theme.LONG_PRESS_TRIGGER_MS)
            } else {
                // Moved onto a function key: cancel this pointer visually.
                hidePreviewFor(ps)
                pointers.remove(pid)
            }
        } else if (nowKr == null) {
            // Off the grid — hide the preview but don't commit.
            if (prevKr.pressed) {
                prevKr.pressed = false
                invalidateRect(prevKr.rect)
            }
            hidePreviewFor(ps)
        }
    }

    private fun onPointerUp(pid: Int, x: Float, y: Float) {
        val ps = pointers[pid] ?: return
        pointers.remove(pid)
        cancelLongPress(ps)

        val kr = ps.keyRect
        kr.pressed = false
        invalidateRect(kr.rect)

        // Alternatives popup: commit the selected alt.
        if (ps.altsActive) {
            val overlay = previewOverlay
            val alts = overlay?.currentAlternatives().orEmpty()
            if (alts.isNotEmpty()) {
                val idx = ps.altsSelectedIndex.coerceIn(0, alts.size - 1)
                commitCharacter(alts[idx])
            }
            overlay?.hideAlternatives()
            ps.altsActive = false
            return
        }

        hidePreviewFor(ps)

        // Backspace was in repeat mode: end here without another delete.
        if (ps.repeating) {
            ps.repeating = false
            return
        }

        // Space slide consumed the gesture — no space char.
        if (ps.spaceCursorActive) {
            return
        }

        // The pointer might have drifted onto a key that isn't a character.
        // Guard: only commit when the release is within the original key.
        val underFinger = keyAt(x, y)
        if (underFinger !== kr) {
            // Special-case: releasing outside a function key cancels.
            return
        }

        commitKeyAction(kr.key.action)
    }

    private fun onLongPress(pid: Int) {
        val ps = pointers[pid] ?: return
        val kr = ps.keyRect
        val key = kr.key
        ps.longPressFired = true

        when (key.action) {
            KeyAction.Backspace -> {
                ps.repeating = true
                haptics.longPress(this)
                // Start repeat cadence.
                startBackspaceRepeat(ps)
            }
            KeyAction.Space -> {
                // Long-press on space → cycle language (Gboard-parity).
                haptics.modifier(this)
                state.cycleLanguage()
                refreshFromState()
                hidePreviewFor(ps)
                pointers.remove(pid)
            }
            KeyAction.Shift -> {
                // Long-press → caps lock.
                haptics.modifier(this)
                if (state.shift != ShiftState.LOCKED) {
                    // Force caps lock by tapping twice programmatically.
                    state.tapShift()
                    if (state.shift != ShiftState.LOCKED) state.tapShift()
                }
                refreshFromState()
                hidePreviewFor(ps)
                pointers.remove(pid)
            }
            KeyAction.LanguageSwitch -> {
                // Long-press 🌐 → full keyboard chooser (Gboard, TACT, …).
                haptics.longPress(this)
                onShowImePicker?.invoke()
                hidePreviewFor(ps)
                pointers.remove(pid)
            }
            is KeyAction.Character -> {
                val alts = if (key.longPressAlternatives.isNotEmpty()) {
                    // Uppercase alternatives when shift is engaged.
                    if (state.isUpperCase) key.longPressAlternatives.map { it.uppercase(Locale.forLanguageTag(state.language.tag)) }
                    else key.longPressAlternatives
                } else emptyList()

                if (alts.isNotEmpty()) {
                    haptics.longPress(this)
                    ps.altsActive = true
                    ps.altsSelectedIndex = 0
                    previewOverlay?.showAlternatives(kr.rect, alts, selectedIndex = 0)
                } else if (key.longPress != null) {
                    // Single long-press replacement char.
                    haptics.longPress(this)
                    commitCharacter(key.longPress)
                    hidePreviewFor(ps)
                    pointers.remove(pid)
                }
            }
            else -> {
                // No long-press behavior for other keys.
            }
        }
    }

    private fun startBackspaceRepeat(ps: PointerState) {
        val startTime = SystemClock.uptimeMillis()
        val runnable = object : Runnable {
            override fun run() {
                if (!isPointerActive(ps)) return
                val elapsed = SystemClock.uptimeMillis() - startTime
                if (elapsed >= Theme.BACKSPACE_WORD_DELETE_AFTER_MS) {
                    inputController.deleteBackwardWord()
                } else {
                    inputController.deleteBackward()
                }
                handler.postDelayed(this, Theme.BACKSPACE_REPEAT_INTERVAL_MS)
            }
        }
        ps.repeatRunnable = runnable
        handler.postDelayed(runnable, Theme.BACKSPACE_REPEAT_INTERVAL_MS)
        // First delete (the visible one at long-press moment).
        inputController.deleteBackward()
    }

    private fun isPointerActive(ps: PointerState): Boolean {
        var i = 0
        while (i < pointers.size()) {
            if (pointers.valueAt(i) === ps) return true
            i++
        }
        return false
    }

    // ── Commit ────────────────────────────────────────────────────────

    private fun commitKeyAction(action: KeyAction) {
        when (action) {
            is KeyAction.Character -> {
                val chr = if (state.isUpperCase) {
                    action.labelUpper ?: action.label.uppercase(Locale.forLanguageTag(state.language.tag))
                } else {
                    action.label
                }
                commitCharacter(chr)
            }
            KeyAction.Space -> {
                haptics.spaceClickSound()
                inputController.commitSpace()
                notifyMaybeWordCommitted(" ")
                val wasUpper = state.isUpperCase
                state.consumeShiftAfterChar()
                if (wasUpper && !state.isUpperCase) invalidate()
            }
            KeyAction.Backspace -> {
                haptics.deleteClickSound()
                inputController.deleteBackward()
            }
            KeyAction.Enter -> {
                haptics.enterClickSound()
                inputController.performEnter()
                notifyMaybeWordCommitted("\n")
                val wasUpper = state.isUpperCase
                state.consumeShiftAfterChar()
                if (wasUpper && !state.isUpperCase) invalidate()
            }
            KeyAction.Shift -> {
                haptics.modifier(this)
                state.tapShift()
                refreshFromState()
            }
            KeyAction.LanguageSwitch -> {
                haptics.modifier(this)
                // Tap 🌐 → cycle TACT languages (EN ↔ RU). If only one language
                // is enabled, fall back to switching to the next system IME.
                // Long-press 🌐 always opens the full IME picker (see onLongPress).
                if (state.enabledLanguages.size > 1) {
                    state.cycleLanguage()
                    refreshFromState()
                } else {
                    onSwitchToNextIme?.invoke()
                }
            }
            is KeyAction.LayerSwitch -> {
                haptics.modifier(this)
                state.switchLayer(action.target)
                refreshFromState()
            }
            KeyAction.Emoji -> {
                // Emoji panel is out of scope for MVP; a subtle no-op keeps
                // the surface valid without producing accidental input.
                haptics.modifier(this)
            }
        }
    }

    private fun commitCharacter(chr: String) {
        haptics.keyClickSound()
        inputController.commitText(chr)
        notifyMaybeWordCommitted(chr)
        val wasUpper = state.isUpperCase
        state.consumeShiftAfterChar()
        // If shift auto-released, the visible casing of every letter key
        // changes — full invalidate. Otherwise nothing changes and per-key
        // invalidation (already scheduled in onPointerUp) is enough.
        if (wasUpper && !state.isUpperCase) {
            invalidate()
        }
    }

    private fun notifyMaybeWordCommitted(justCommitted: CharSequence) {
        val cb = onWordCommitted ?: return
        val word = inputController.lastCompletedWord(justCommitted) ?: return
        cb(word)
    }

    // ── Preview & ripple helpers ──────────────────────────────────────

    private fun maybeShowPreview(kr: KeyRect) {
        val key = kr.key
        // Show preview only for character keys.
        if (key.action !is KeyAction.Character) return
        val overlay = previewOverlay ?: return
        val label = if (state.isUpperCase) {
            key.action.labelUpper ?: key.action.label.uppercase(Locale.forLanguageTag(state.language.tag))
        } else {
            key.action.label
        }
        overlay.showPreview(kr.rect, label)
    }

    private fun hidePreviewFor(@Suppress("UNUSED_PARAMETER") ps: PointerState) {
        // The overlay is shared across all pointers; hiding it is idempotent.
        // The parameter documents that this call belongs to a specific pointer
        // being cleaned up. Future evolution (per-pointer previews) will use it.
        previewOverlay?.hidePreview()
    }

    private fun startRippleAt(kr: KeyRect, x: Float, y: Float) {
        val maxRadius = kotlin.math.hypot(kr.rect.width().toDouble(), kr.rect.height().toDouble()).toFloat()
        val animator = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = Theme.RIPPLE_ANIM_MS
            interpolator = android.view.animation.DecelerateInterpolator()
        }
        val ripple = Ripple(
            cx = x,
            cy = y,
            clip = RectF(kr.rect),
            radius = 0f,
            alpha = 0x33,
            maxRadius = maxRadius,
            animator = animator,
        )
        animator.addUpdateListener { va ->
            val t = va.animatedValue as Float
            ripple.radius = maxRadius * t
            ripple.alpha = (0x33 * (1f - t)).toInt().coerceIn(0, 0xFF)
            invalidateRect(kr.rect)
        }
        animator.addListener(object : android.animation.AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: android.animation.Animator) {
                ripples.remove(ripple)
                invalidateRect(kr.rect)
            }
        })
        ripples.add(ripple)
        animator.start()
    }

    // ── Utility ───────────────────────────────────────────────────────

    private fun keyAt(x: Float, y: Float): KeyRect? {
        for (i in keyRects.indices) {
            val kr = keyRects[i]
            if (kr.rect.contains(x, y)) return kr
        }
        // Nothing hit exactly; find nearest key on the same row (helps the
        // user hit small keys with fat thumbs). Distance in Y first.
        var best: KeyRect? = null
        var bestDy = Float.MAX_VALUE
        for (i in keyRects.indices) {
            val kr = keyRects[i]
            if (y < kr.rect.top || y > kr.rect.bottom) continue
            val dx = when {
                x < kr.rect.left -> kr.rect.left - x
                x > kr.rect.right -> x - kr.rect.right
                else -> 0f
            }
            if (dx < bestDy) {
                bestDy = dx
                best = kr
            }
        }
        // Only forgive up to ~8dp of overshoot.
        return if (best != null && bestDy < metrics.dp(8f)) best else null
    }

    private fun cancelLongPress(ps: PointerState) {
        ps.longPressRunnable?.let { handler.removeCallbacks(it) }
        ps.longPressRunnable = null
        ps.repeatRunnable?.let { handler.removeCallbacks(it) }
        ps.repeatRunnable = null
    }

    private fun clearAllPointers() {
        var i = 0
        while (i < pointers.size()) {
            val ps = pointers.valueAt(i)
            cancelLongPress(ps)
            ps.keyRect.pressed = false
            i++
        }
        pointers.clear()
        previewOverlay?.hidePreview()
        previewOverlay?.hideAlternatives()
        invalidate()
    }

    private fun invalidateRect(r: RectF) {
        tmpRect.set(
            (r.left - 4).toInt(),
            (r.top - 4).toInt(),
            (r.right + 4).toInt(),
            (r.bottom + 4).toInt(),
        )
        invalidate(tmpRect)
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        handler.removeCallbacksAndMessages(null)
    }

    // ── Internal types ────────────────────────────────────────────────

    private class KeyRect(
        val key: Key,
        val rect: RectF,
        val rowIndex: Int,
        val keyIndex: Int,
    ) {
        var pressed: Boolean = false
    }

    private class PointerState(
        var keyRect: KeyRect,
        val downX: Float,
        val downY: Float,
        val downTime: Long,
        var lastX: Float,
        var lastY: Float,
    ) {
        var longPressFired: Boolean = false
        var repeating: Boolean = false
        var altsActive: Boolean = false
        var altsSelectedIndex: Int = -1
        var spaceCursorActive: Boolean = false
        var spaceLastX: Float = downX
        var spaceAccum: Float = 0f
        var longPressRunnable: Runnable? = null
        var repeatRunnable: Runnable? = null
    }
}
