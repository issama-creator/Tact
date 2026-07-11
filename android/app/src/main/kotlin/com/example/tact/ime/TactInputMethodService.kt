package com.example.tact.ime

import android.content.ComponentCallbacks2
import android.content.res.Configuration
import android.inputmethodservice.InputMethodService
import android.util.Log
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.EditorInfo

/**
 * TACT — Android InputMethodService.
 *
 * onCreate stays lightweight. Release builds may already have a warm IME
 * engine from [TactApplication]; debug warms on first input view (or via
 * delayed companion prewarm). If Flutter fails, native keys still render.
 */
class TactInputMethodService : InputMethodService() {

    companion object {
        private const val TAG = "TactIME"
    }

    private lateinit var inputController: InputController
    private lateinit var haptics: KeyboardHaptics
    private var bridge: ImeBridgeImpl? = null
    private var rootView: KeyboardRootView? = null

    override fun onCreate() {
        super.onCreate()
        inputController = InputController(this)
        haptics = KeyboardHaptics(this)
        // Release only — mirrors Application prewarm when the IME process
        // path is the first thing the user hits after install.
        FlutterEngineHost.tryEagerPrewarm(applicationContext)
        Log.i(TAG, "IME service created")
    }

    override fun onCreateInputView(): View {
        Log.i(TAG, "onCreateInputView")
        rootView?.teardown()
        bridge?.dispose()
        bridge = null
        val root = KeyboardRootView(
            context = this,
            inputController = inputController,
            haptics = haptics,
            onBridgeReady = { bridge = it },
            onShowImePicker = { showInputMethodPicker() },
            onSwitchToNextIme = { switchToNextInputMethod() },
        )
        rootView = root
        return root
    }

    /** Opens the system keyboard chooser (Gboard, TACT, …). */
    fun showInputMethodPicker() {
        ImeSwitcher.showPicker(this)
    }

    /** Quick-switch to the next enabled IME without opening Settings. */
    fun switchToNextInputMethod() {
        val windowToken = window?.window?.attributes?.token
        if (windowToken != null) {
            ImeSwitcher.switchToNext(this, windowToken)
        } else {
            showInputMethodPicker()
        }
    }

    override fun onStartInput(attribute: EditorInfo?, restarting: Boolean) {
        super.onStartInput(attribute, restarting)
        inputController.restart(attribute)
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        Log.i(TAG, "onStartInputView package=${info?.packageName}")
        rootView?.configureFor(info)
        bridge?.onStartInputView(
            packageName = info?.packageName,
            inputType = info?.inputType ?: 0,
            imeOptions = info?.imeOptions ?: 0,
            locale = rootView?.keyboardState?.language?.tag,
        )
    }

    override fun onFinishInputView(finishingInput: Boolean) {
        rootView?.onFinishInputView()
        super.onFinishInputView(finishingInput)
    }

    override fun onFinishInput() {
        super.onFinishInput()
        inputController.finish()
    }

    override fun onDestroy() {
        rootView?.teardown()
        bridge?.dispose()
        bridge = null
        rootView = null
        // Keep FlutterEngine warm across IME service restarts — cuts reopen latency.
        // Process death reclaims memory; explicit release only under memory pressure.
        super.onDestroy()
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        if (rootView != null) return
        when (level) {
            ComponentCallbacks2.TRIM_MEMORY_RUNNING_CRITICAL,
            ComponentCallbacks2.TRIM_MEMORY_COMPLETE,
            ComponentCallbacks2.TRIM_MEMORY_MODERATE,
            -> FlutterEngineHost.release()
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        rootView?.onConfigurationChanged()
    }

    /** Always show the soft keyboard when a field is focused. */
    override fun onEvaluateInputViewShown(): Boolean = true

    override fun onEvaluateFullscreenMode(): Boolean = false

    override fun onUpdateSelection(
        oldSelStart: Int,
        oldSelEnd: Int,
        newSelStart: Int,
        newSelEnd: Int,
        candidatesStart: Int,
        candidatesEnd: Int,
    ) {
        super.onUpdateSelection(
            oldSelStart, oldSelEnd, newSelStart, newSelEnd,
            candidatesStart, candidatesEnd,
        )
        inputController.onSelectionChanged(newSelStart, newSelEnd)
        rootView?.onSelectionChanged(oldSelStart, oldSelEnd, newSelStart, newSelEnd)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean =
        super.onKeyDown(keyCode, event)

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean =
        super.onKeyUp(keyCode, event)
}
