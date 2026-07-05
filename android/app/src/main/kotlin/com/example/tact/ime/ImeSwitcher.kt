package com.example.tact.ime

import android.content.Context
import android.view.inputmethod.InputMethodManager

/**
 * System IME switching — lets the user return to Gboard or any other
 * keyboard without digging through Settings.
 */
object ImeSwitcher {

    fun showPicker(context: Context) {
        val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE)
            as InputMethodManager
        imm.showInputMethodPicker()
    }

    /**
     * Cycle to the next enabled IME (Gboard → TACT → …). Requires a
     * window token from the active [android.inputmethodservice.InputMethodService].
     */
    fun switchToNext(context: Context, windowToken: android.os.IBinder) {
        val imm = context.getSystemService(Context.INPUT_METHOD_SERVICE)
            as InputMethodManager
        imm.switchToNextInputMethod(windowToken, false)
    }
}
