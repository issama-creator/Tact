package com.example.tact

import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private var channel: MethodChannel? = null
    private var pendingReconcileAfterSettings = false
    /** Skip reconcile when returning from the keyboard picker (not Settings). */
    private var suppressResumeReconcile = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).also { ch ->
            ch.setMethodCallHandler { call, result ->
                when (call.method) {
                    "openImeSettings" -> {
                        pendingReconcileAfterSettings = true
                        startActivity(Intent(Settings.ACTION_INPUT_METHOD_SETTINGS))
                        result.success(null)
                    }
                    "showInputMethodPicker" -> {
                        suppressResumeReconcile = true
                        val imm = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
                        imm.showInputMethodPicker()
                        result.success(null)
                    }
                    "getImeStatus" -> {
                        result.success(ImeStatusReader.read(this))
                    }
                    "activateTact" -> {
                        suppressResumeReconcile = true
                        result.success(ImeCoordinator.activateTact(this).name.lowercase())
                    }
                    "activateGboard" -> {
                        suppressResumeReconcile = true
                        result.success(ImeCoordinator.activateGboard(this).name.lowercase())
                    }
                    "reconcileKeyboard" -> {
                        val showPicker = call.argument<Boolean>("showPicker") ?: true
                        result.success(
                            ImeCoordinator.reconcileAfterSettings(
                                this,
                                showPickerOnFailure = showPicker,
                            ).name.lowercase(),
                        )
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()

        if (suppressResumeReconcile) {
            suppressResumeReconcile = false
            return
        }

        if (!pendingReconcileAfterSettings) return

        pendingReconcileAfterSettings = false

        // Enabled IME list can lag right after Settings — wait before reconciling.
        ImeCoordinator.reconcileAfterSettingsDelayed(
            context = this,
            showPickerOnFailure = false,
        ) { reconcileResult ->
            notifyKeyboardReconciled(reconcileResult)
        }
    }

    private fun notifyKeyboardReconciled(reconcileResult: ImeCoordinator.Result) {
        channel?.invokeMethod(
            "onKeyboardReconciled",
            mapOf(
                "result" to reconcileResult.name.lowercase(),
                "status" to ImeStatusReader.read(this),
            ),
        )
    }

    companion object {
        private const val CHANNEL = "com.example.tact/companion"
    }
}
