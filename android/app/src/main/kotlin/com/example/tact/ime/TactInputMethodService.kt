package com.example.tact.ime

import android.content.res.Configuration
import android.inputmethodservice.InputMethodService
import android.util.Log
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.EditorInfo

/**
 * TACT — Android InputMethodService.
 *
 * onCreate stays lightweight (no Flutter). The Flutter engine is warmed
 * lazily when [KeyboardRootView] attaches — if it fails, native keys
 * still render.
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
        Log.i(TAG, "IME service created")
    }

    override fun onCreateInputView(): View {
        Log.i(TAG, "onCreateInputView")
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
        bridge?.dispose()
        bridge = null
        rootView = null
        super.onDestroy()
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
        rootView?.onSelectionChanged(oldSelStart, oldSelEnd, newSelStart, newSelEnd)
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean =
        super.onKeyDown(keyCode, event)

    override fun onKeyUp(keyCode: Int, event: KeyEvent?): Boolean =
        super.onKeyUp(keyCode, event)
}
