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
        setBackgroundColor(Theme.COLOR_KEYBOARD_BG)
        clipChildren = false
        clipToPadding = false

        val cfg = context.resources.configuration
        setPadding(0, 0, 0, metrics.dpInt(Theme.keyboardBottomPaddingDp(cfg)))
        val barHeight = metrics.dpInt(Theme.suggestionBarHeightDp(cfg))

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

        Log.i(TAG, "KeyboardRootView built (flutter=${flutterView != null})")
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

            val layoutListener = View.OnLayoutChangeListener { v, _, _, _, _, _, _, _, _ ->
                if (engineAttached && v.width > 0 && v.height > 0) {
                    bumpFlutterRender()
                }
            }
            flutterLayoutListener = layoutListener
            view.addOnLayoutChangeListener(layoutListener)

            view.post { attachFlutterEngineIfNeeded() }
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
        try {
            engine.lifecycleChannel.appIsResumed()
            view.attachToFlutterEngine(engine)
            engine.renderer.addIsDisplayingFlutterUiListener(flutterUiListener)
            engineAttached = true
            bridge?.sendTheme()
            bumpFlutterRender()
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
    fun bumpFlutterRender() {
        val view = flutterView ?: return
        if (!engineAttached) return
        view.invalidate()
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
        flutterView?.post { attachFlutterEngineIfNeeded() }
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

        val cls = info.inputType and android.text.InputType.TYPE_MASK_CLASS
        if (cls == android.text.InputType.TYPE_CLASS_NUMBER ||
            cls == android.text.InputType.TYPE_CLASS_PHONE ||
            cls == android.text.InputType.TYPE_CLASS_DATETIME
        ) {
            keyboardState.setLayer(LayerKind.NUMBERS)
        } else if (keyboardState.layer == LayerKind.NUMBERS) {
            keyboardState.setLayer(LayerKind.ALPHA)
        }

        val autoCapMask = android.text.InputType.TYPE_TEXT_FLAG_CAP_CHARACTERS or
            android.text.InputType.TYPE_TEXT_FLAG_CAP_SENTENCES or
            android.text.InputType.TYPE_TEXT_FLAG_CAP_WORDS
        val requestsAutoCap = (info.inputType and autoCapMask) != 0
        if (requestsAutoCap && keyboardState.shift == ShiftState.OFF) {
            keyboardState.tapShift()
        }

        keyGridView.refreshFromState()
    }

    fun onSelectionChanged(oldStart: Int, oldEnd: Int, newStart: Int, newEnd: Int) {
        bridge?.onSelectionChanged(oldStart, oldEnd, newStart, newEnd)
    }

    fun onFinishInputView() {
        bridge?.onFinishInputView()
    }

    fun onConfigurationChanged() {
        val cfg = resources.configuration
        setPadding(0, 0, 0, metrics.dpInt(Theme.keyboardBottomPaddingDp(cfg)))
        val barHeight = metrics.dpInt(Theme.suggestionBarHeightDp(cfg))
        val bar = getChildAt(0)
        bar.layoutParams = (bar.layoutParams as LayoutParams).also { it.height = barHeight }

        val keyContainer = getChildAt(1) as ViewGroup
        val keyAreaHeight = metrics.dpInt(Theme.keyAreaHeightDp(cfg))
        keyContainer.layoutParams =
            (keyContainer.layoutParams as LayoutParams).also { it.height = keyAreaHeight }

        requestLayout()
        keyGridView.refreshFromState()
        flutterView?.post { bumpFlutterRender() }
    }
}
