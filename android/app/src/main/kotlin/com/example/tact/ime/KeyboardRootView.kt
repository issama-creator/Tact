package com.example.tact.ime

import android.content.Context
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.widget.FrameLayout
import android.widget.LinearLayout
import io.flutter.embedding.android.FlutterTextureView
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.renderer.FlutterUiDisplayListener
import java.util.Locale
import kotlin.math.roundToInt

/**
 * Root IME view: suggestion bar (Flutter or native fallback) + key grid.
 *
 * Flutter is optional at runtime. If [FlutterEngineHost.tryPrewarm] fails,
 * a solid-color native View replaces the suggestion bar so the keyboard
 * still appears and typing works.
 */
class KeyboardRootView(
    context: Context,
    private val inputController: InputController,
    private val haptics: KeyboardHaptics,
    private val onBridgeReady: (ImeBridgeImpl) -> Unit,
    private val onShowImePicker: () -> Unit,
    private val onSwitchToNextIme: () -> Unit,
) : LinearLayout(context) {

    companion object {
        private const val TAG = "TactKeyboardRoot"
    }

    private val metrics = Metrics(this)

    val keyboardState = KeyboardState()
    val keyGridView: KeyGridView
    val previewOverlay: KeyPreviewOverlay

    private var flutterView: FlutterView? = null
    private var flutterEngine: FlutterEngine? = null
    private var bridge: ImeBridgeImpl? = null
    private var engineAttached = false

    private var suggestionBarContainer: FrameLayout? = null
    private var keyAreaContainer: FrameLayout? = null
    private var flutterLayoutListener: View.OnLayoutChangeListener? = null

    private val flutterUiListener = object : FlutterUiDisplayListener {
        override fun onFlutterUiDisplayed() {
            Log.i(TAG, "Flutter suggestion bar displayed first frame")
        }

        override fun onFlutterUiNoLongerDisplayed() {
            Log.w(TAG, "Flutter suggestion bar UI hidden")
        }
    }

    init {
        orientation = VERTICAL
        clipChildren = false
        clipToPadding = false

        val cfg = context.resources.configuration
        val barHeight = metrics.dpInt(Theme.suggestionBarHeightDp(cfg))

        // Apply theme before building children so paints pick correct colors.
        ThemePrefs.applyFromStorage(context)
        setBackgroundColor(Theme.COLOR_KEYBOARD_BG)

        val barContainer = FrameLayout(context).apply {
            setBackgroundColor(Theme.COLOR_PANEL_BAR_BG)
        }
        suggestionBarContainer = barContainer
        val suggestionBar = createSuggestionBar(context)
        barContainer.addView(
            suggestionBar,
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        addView(
            barContainer,
            LayoutParams(LayoutParams.MATCH_PARENT, barHeight),
        )

        val keyContainer = FrameLayout(context).apply {
            clipChildren = false
            clipToPadding = false
        }
        keyAreaContainer = keyContainer
        val keyAreaHeight = metrics.dpInt(Theme.keyAreaHeightDp(cfg))
        addView(
            keyContainer,
            LayoutParams(LayoutParams.MATCH_PARENT, keyAreaHeight),
        )

        keyGridView = KeyGridView(context).apply {
            state = keyboardState
            inputController = this@KeyboardRootView.inputController
            haptics = this@KeyboardRootView.haptics
            onShowImePicker = onShowImePicker
            onSwitchToNextIme = onSwitchToNextIme
        }
        previewOverlay = KeyPreviewOverlay(context)
        keyGridView.previewOverlay = previewOverlay

        val fill = FrameLayout.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
            Gravity.FILL,
        )
        keyContainer.addView(keyGridView, fill)
        keyContainer.addView(previewOverlay, fill)

        keyGridView.onWordCommitted = { info ->
            bridge?.onWordCommitted(info, keyboardState.language.tag)
        }
        keyGridView.onPartialWord = { info ->
            bridge?.onPartialWordCommitted(info, keyboardState.language.tag)
        }
        keyGridView.onTextEdited = {
            bridge?.onTextEdited()
        }

        applyAdaptiveChrome(forceLog = true)
        // Colors already applied above; only push theme to Flutter bridge.
        bridge?.sendTheme()
        Log.i(TAG, "KeyboardRootView built (flutter=${flutterView != null})")
    }

    /** Reload companion theme only when the stored index changed. */
    fun applyPersistedTheme() {
        val before = Theme.activeIndex
        ThemePrefs.applyFromStorage(context)
        if (before == Theme.activeIndex && Theme.colorsApplied) {
            // Still refresh Flutter once if bridge attached late.
            bridge?.sendTheme()
            return
        }
        setBackgroundColor(Theme.COLOR_KEYBOARD_BG)
        suggestionBarContainer?.setBackgroundColor(Theme.COLOR_PANEL_BAR_BG)
        keyGridView.refreshColors()
        previewOverlay.refreshColors()
        bridge?.sendTheme()
        bumpFlutterRender()
    }

    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        if (w != oldw) applyAdaptiveChrome()
    }

    /**
     * Centers content on wide screens (max [KeyboardSizing.CONTENT_MAX_WIDTH_DP])
     * and refreshes bar / key-area heights from [KeyboardSizing].
     */
    private fun applyAdaptiveChrome(forceLog: Boolean = false) {
        val cfg = resources.configuration
        val bottom = metrics.dpInt(Theme.keyboardBottomPaddingDp(cfg))
        val edge = metrics.dpInt(KeyboardSizing.edgeInsetDp(cfg))
        val side = if (KeyboardSizing.isTablet(cfg)) {
            val contentPx = if (width > 0) {
                metrics.dpInt(KeyboardSizing.contentMaxWidthDp(cfg))
            } else {
                metrics.dpInt(KeyboardSizing.contentMaxWidthDp(cfg))
            }
            val available = if (width > 0) width else metrics.dpInt(cfg.screenWidthDp.toFloat())
            maxOf(edge, ((available - contentPx) / 2).coerceAtLeast(0))
        } else {
            edge
        }
        setPadding(side, 0, side, bottom)

        val barHeight = metrics.dpInt(Theme.suggestionBarHeightDp(cfg))
        suggestionBarContainer?.let { bar ->
            val lp = bar.layoutParams as LayoutParams
            if (lp.height != barHeight) {
                lp.height = barHeight
                bar.layoutParams = lp
            }
        }

        val keyAreaHeight = metrics.dpInt(Theme.keyAreaHeightDp(cfg))
        keyAreaContainer?.let { keys ->
            val lp = keys.layoutParams as LayoutParams
            if (lp.height != keyAreaHeight) {
                lp.height = keyAreaHeight
                keys.layoutParams = lp
            }
        }

        if (forceLog) {
            Log.i(
                TAG,
                "adaptive class=${KeyboardSizing.deviceClass(cfg)} " +
                    "scale=${String.format(Locale.US, "%.2f", KeyboardSizing.keyboardScale(cfg))} " +
                    "content=${KeyboardSizing.contentMaxWidthDp(cfg).roundToInt()}dp " +
                    "keyH=${keyAreaHeight}px " +
                    "letter≈${String.format(Locale.US, "%.1f", KeyboardSizing.estimatedLetterKeyWidthDp(cfg))}dp",
            )
        }
    }

    /**
     * TextureView composites inside the IME window hierarchy.
     * SurfaceView often stays an empty black hole in InputMethodService.
     */
    private fun createSuggestionBar(context: Context): View {
        val engine = FlutterEngineHost.tryPrewarm(context)
        if (engine == null) {
            return nativeSuggestionBar(context)
        }

        return try {
            val textureView = FlutterTextureView(context).apply {
                isOpaque = true
            }
            val view = FlutterView(context, textureView).apply {
                setBackgroundColor(Theme.COLOR_PANEL_BAR_BG)
                isFocusable = true
                isFocusableInTouchMode = true
            }
            flutterView = view
            flutterEngine = engine

            val impl = ImeBridgeImpl(engine, inputController, haptics, this@KeyboardRootView)
            impl.onRequestRepaint = { bumpFlutterRender() }
            bridge = impl
            onBridgeReady(impl)

            val layoutListener = View.OnLayoutChangeListener { v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom ->
                if (v.width <= 0 || v.height <= 0) return@OnLayoutChangeListener
                if (!engineAttached) {
                    // First real layout after attach-to-window — bind engine now.
                    attachFlutterEngineIfNeeded()
                } else if (right - left != oldRight - oldLeft ||
                    bottom - top != oldBottom - oldTop
                ) {
                    bumpFlutterRender()
                }
            }
            flutterLayoutListener = layoutListener
            view.addOnLayoutChangeListener(layoutListener)
            view
        } catch (t: Throwable) {
            Log.e(TAG, "FlutterView creation failed — using native fallback", t)
            nativeSuggestionBar(context)
        }
    }

    private fun attachFlutterEngineIfNeeded() {
        val view = flutterView ?: return
        val engine = flutterEngine ?: return
        if (engineAttached) {
            bumpFlutterRender()
            return
        }
        // Attaching at 0x0 makes the suggestion bar dead until a full restart —
        // wait for the first non-zero layout (see layout listener).
        if (view.width <= 0 || view.height <= 0) {
            if (view.isAttachedToWindow) {
                view.post { attachFlutterEngineIfNeeded() }
            }
            return
        }
        try {
            engine.lifecycleChannel.appIsResumed()
            view.attachToFlutterEngine(engine)
            engine.renderer.addIsDisplayingFlutterUiListener(flutterUiListener)
            engineAttached = true
            // Theme + pending events + repaint (covers late attach after Dart ready).
            if (FlutterEngineHost.isDartReady()) {
                bridge?.resendReadyState()
            } else {
                bridge?.sendTheme()
                bumpFlutterRender()
            }
            Log.i(
                TAG,
                "FlutterView attached (texture) size=${view.width}x${view.height}",
            )
        } catch (t: Throwable) {
            Log.e(TAG, "FlutterView attach failed", t)
            fallbackSuggestionBarToNative()
        }
    }

    /** Force a raster pass — Dart setState alone is not enough in IME windows. */
    private var bumpPosted = false

    fun bumpFlutterRender() {
        val view = flutterView ?: return
        if (!engineAttached) return
        if (bumpPosted) return
        bumpPosted = true
        view.post {
            bumpPosted = false
            flutterView?.invalidate()
        }
    }

    private fun nativeSuggestionBar(context: Context): View =
        View(context).apply {
            setBackgroundColor(Theme.COLOR_PANEL_BAR_BG)
        }

    private fun fallbackSuggestionBarToNative() {
        val container = suggestionBarContainer ?: return
        if (container.childCount == 0 || container.getChildAt(0) !is FlutterView) return
        try {
            flutterEngine?.renderer?.removeIsDisplayingFlutterUiListener(flutterUiListener)
            flutterView?.detachFromFlutterEngine()
        } catch (_: Throwable) { }
        engineAttached = false
        flutterView = null
        container.removeAllViews()
        container.addView(
            nativeSuggestionBar(context),
            FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        Log.w(TAG, "Suggestion bar fell back to native view")
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        val view = flutterView ?: return
        // Listener may have been cleared on detach — restore so size→attach works.
        if (flutterLayoutListener == null) {
            val layoutListener = View.OnLayoutChangeListener { v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom ->
                if (v.width <= 0 || v.height <= 0) return@OnLayoutChangeListener
                if (!engineAttached) {
                    attachFlutterEngineIfNeeded()
                } else if (right - left != oldRight - oldLeft ||
                    bottom - top != oldBottom - oldTop
                ) {
                    bumpFlutterRender()
                }
            }
            flutterLayoutListener = layoutListener
            view.addOnLayoutChangeListener(layoutListener)
        }
        // Post so the first layout pass can assign a real bar size first.
        view.post { attachFlutterEngineIfNeeded() }
    }

    override fun onDetachedFromWindow() {
        detachFlutterSuggestionBar()
        super.onDetachedFromWindow()
    }

    /** Tears down bridge, listeners, and Flutter lifecycle before the view is replaced. */
    fun teardown() {
        onFinishInputView()
        keyGridView.onWordCommitted = null
        keyGridView.onPartialWord = null
        keyGridView.onTextEdited = null
        bridge?.dispose()
        bridge = null
        detachFlutterSuggestionBar()
    }

    private fun detachFlutterSuggestionBar() {
        flutterView?.let { view ->
            flutterLayoutListener?.let { view.removeOnLayoutChangeListener(it) }
            flutterLayoutListener = null
            if (engineAttached) {
                try {
                    flutterEngine?.lifecycleChannel?.appIsPaused()
                    flutterEngine?.renderer?.removeIsDisplayingFlutterUiListener(flutterUiListener)
                    view.detachFromFlutterEngine()
                } catch (t: Throwable) {
                    Log.e(TAG, "FlutterView detach failed", t)
                }
                engineAttached = false
            }
        }
    }

    fun configureFor(info: EditorInfo?) {
        info ?: return

        // Don't carry caps lock / symbols layer into the next field.
        keyboardState.resetForNewField()

        val cls = info.inputType and android.text.InputType.TYPE_MASK_CLASS
        if (cls == android.text.InputType.TYPE_CLASS_NUMBER ||
            cls == android.text.InputType.TYPE_CLASS_PHONE ||
            cls == android.text.InputType.TYPE_CLASS_DATETIME
        ) {
            keyboardState.setLayer(LayerKind.NUMBERS)
        }

        val autoCapMask = android.text.InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS or
            android.text.InputType.TYPE_TEXT_FLAG_CAP_SENTENCES or
            android.text.InputType.TYPE_TEXT_FLAG_CAP_WORDS
        val requestsAutoCap = (info.inputType and autoCapMask) != 0
        if (requestsAutoCap && !inputController.isPasswordField) {
            keyboardState.tapShift()
        }

        keyGridView.refreshFromState()
        applyPersistedTheme()
    }

    fun onSelectionChanged(oldStart: Int, oldEnd: Int, newStart: Int, newEnd: Int) {
        bridge?.onSelectionChanged(oldStart, oldEnd, newStart, newEnd)
    }

    fun onFinishInputView() {
        bridge?.onFinishInputView()
    }

    fun onConfigurationChanged() {
        applyAdaptiveChrome(forceLog = true)
        requestLayout()
        keyGridView.onAdaptiveMetricsChanged()
        previewOverlay.onAdaptiveMetricsChanged()
        keyGridView.refreshFromState()
        flutterView?.post { bumpFlutterRender() }
    }
}
