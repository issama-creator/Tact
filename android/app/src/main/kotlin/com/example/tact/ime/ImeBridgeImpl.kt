package com.example.tact.ime

import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Minimal, working MethodChannel bridge between the native IME and Dart.
 */
class ImeBridgeImpl(
    engine: FlutterEngine,
    private val inputController: InputController,
    private val haptics: KeyboardHaptics? = null,
    private val hapticView: View? = null,
) : MethodChannel.MethodCallHandler {

    private val channel: MethodChannel =
        MethodChannel(engine.dartExecutor.binaryMessenger, BRIDGE_CHANNEL)

    private val mainHandler = Handler(Looper.getMainLooper())
    private val pending = ArrayDeque<Pair<String, Any?>>()

    /** Skips duplicate partial-word / clear events on the typing hot path. */
    private var lastPartialSignature: String? = null

    /** Coalesces rapid selection updates (space-bar cursor slide). */
    private var pendingSelection: Map<String, Any?>? = null
    private var selectionFlushPosted = false

    /** Native repaint hook — IME FlutterView may not paint after Dart setState alone. */
    var onRequestRepaint: (() -> Unit)? = null

    init {
        channel.setMethodCallHandler(this)
        // Dart may have called ready() while no native handler existed
        // (engine prewarmed before KeyboardRootView). Nudge a resend —
        // bypasses dartReady gate because that flag is exactly what is stuck.
        mainHandler.post { nudgeDartHostAttached() }
    }

    private fun nudgeDartHostAttached() {
        try {
            channel.invokeMethod("hostAttached", null)
        } catch (t: Throwable) {
            Log.w(TAG, "hostAttached nudge failed", t)
        }
    }

    // ── Native → Dart ─────────────────────────────────────────────────

    fun sendTheme() = invokeDart("setTheme", themePayload())

    fun onStartInputView(packageName: String?, inputType: Int, imeOptions: Int, locale: String?) {
        lastPartialSignature = null
        invokeDart(
            "onStartInputView",
            mapOf(
                "packageName" to packageName,
                "inputType" to inputType,
                "imeOptions" to imeOptions,
                "locale" to locale,
                "isPassword" to inputController.isPasswordField,
            ),
        )
    }

    fun onFinishInputView() = invokeDart("onFinishInputView", null)

    fun onWordCommitted(info: WordCommitInfo, locale: String) {
        lastPartialSignature = null
        if (Log.isLoggable(TAG, Log.DEBUG)) {
            Log.d(TAG, "word committed: '${info.word}' locale=$locale")
        }
        invokeDart("onWordCommitted", wordPayloadMap(info, locale, partial = false))
    }

    fun onPartialWordCommitted(info: WordCommitInfo?, locale: String) {
        val signature = if (info == null) {
            "__clear__"
        } else {
            partialSignature(info, locale)
        }
        if (signature == lastPartialSignature) return
        lastPartialSignature = signature
        if (info == null) {
            invokeDart("onPartialWordClear", null)
            return
        }
        invokeDart("onPartialWord", wordPayloadMap(info, locale, partial = true))
    }

    /** Dedupes identical consecutive partials. Cleared on commit / clear. */
    private fun partialSignature(info: WordCommitInfo, locale: String): String {
        return "${info.word}|$locale|${info.deleteBefore}"
    }

    fun onTextEdited() = invokeDart("onTextEdited", null)

    fun onSelectionChanged(oldStart: Int, oldEnd: Int, newStart: Int, newEnd: Int) {
        pendingSelection = mapOf(
            "oldStart" to oldStart,
            "oldEnd" to oldEnd,
            "newStart" to newStart,
            "newEnd" to newEnd,
        )
        if (selectionFlushPosted) return
        selectionFlushPosted = true
        mainHandler.post {
            selectionFlushPosted = false
            val payload = pendingSelection ?: return@post
            pendingSelection = null
            invokeDart("onSelectionChanged", payload)
        }
    }

    private fun wordPayloadMap(
        info: WordCommitInfo,
        locale: String,
        partial: Boolean,
    ): Map<String, Any?> = mapOf(
        "word" to info.word,
        "locale" to locale,
        "deleteBefore" to info.deleteBefore,
        "deleteAfter" to info.deleteAfter,
        "boundary" to info.boundary,
        "before" to info.before,
        "after" to info.after,
        "partial" to partial,
    )

    private fun themePayload(): Map<String, Any?> = mapOf(
        "background" to Theme.COLOR_PANEL_BAR_BG,
        "keyText" to Theme.COLOR_KEY_TEXT,
        "keyTextMuted" to Theme.COLOR_KEY_TEXT_MUTED,
        "accent" to Theme.COLOR_KEY_ACCENT_BG,
    )

    private fun invokeDart(method: String, arguments: Any?) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            if (!FlutterEngineHost.isDartReady()) {
                enqueuePending(method, arguments)
                return
            }
            dispatchDart(method, arguments)
            return
        }
        mainHandler.post {
            if (!FlutterEngineHost.isDartReady()) {
                enqueuePending(method, arguments)
                return@post
            }
            dispatchDart(method, arguments)
        }
    }

    private fun enqueuePending(method: String, arguments: Any?) {
        if (pending.size >= MAX_PENDING) {
            val dropIdx = pending.indexOfFirst { (m, _) ->
                m == "onPartialWord" || m == "onPartialWordClear" ||
                    m == "onTextEdited" || m == "onSelectionChanged"
            }
            if (dropIdx >= 0) {
                pending.removeAt(dropIdx)
            } else {
                pending.removeFirst()
            }
        }
        pending.addLast(method to arguments)
    }

    private fun dispatchDart(method: String, arguments: Any?) {
        try {
            channel.invokeMethod(method, arguments)
            // Only force a raster on committed words — partial keystrokes are
            // too frequent; Dart already debounces requestRepaint on panel change.
            if (method == "onWordCommitted") {
                onRequestRepaint?.invoke()
            }
        } catch (t: Throwable) {
            Log.w(TAG, "invokeDart $method failed", t)
        }
    }

    private fun flushPending() {
        mainHandler.post {
            if (!FlutterEngineHost.isDartReady()) return@post
            while (pending.isNotEmpty()) {
                val (method, args) = pending.removeFirst()
                dispatchDart(method, args)
            }
        }
    }

    /**
     * After a late FlutterView attach (first layout with real size), push theme
     * and any queued native→Dart events again so the bar is live without a
     * manual Hot Restart.
     */
    fun resendReadyState() {
        if (!FlutterEngineHost.isDartReady()) return
        sendTheme()
        flushPending()
        onRequestRepaint?.invoke()
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        pending.clear()
        pendingSelection = null
        selectionFlushPosted = false
        mainHandler.removeCallbacksAndMessages(null)
    }

    // ── Dart → Native ─────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "commitText" -> {
                    val text = call.argument<String>("text") ?: ""
                    inputController.commitText(text)
                    result.success(null)
                }
                "deleteSurrounding" -> {
                    val before = call.argument<Int>("before") ?: 0
                    val after = call.argument<Int>("after") ?: 0
                    inputController.deleteSurroundingText(before, after)
                    result.success(null)
                }
                "replaceSurrounding" -> {
                    val before = call.argument<Int>("deleteBefore") ?: 0
                    val after = call.argument<Int>("deleteAfter") ?: 0
                    val replacement = call.argument<String>("replacement") ?: ""
                    val outcome = inputController.replaceSurrounding(before, after, replacement)
                    if (outcome == null) {
                        result.success(null)
                    } else {
                        result.success(
                            mapOf(
                                "selectionStart" to outcome.selectionStart,
                                "selectionEnd" to outcome.selectionEnd,
                                "replacedText" to outcome.replacedText,
                                "insertedLength" to outcome.insertedLength,
                                "previousSelectionStart" to outcome.previousSelectionStart,
                                "previousSelectionEnd" to outcome.previousSelectionEnd,
                            ),
                        )
                    }
                }
                "getSurroundingText" -> {
                    val before = call.argument<Int>("before") ?: 256
                    val after = call.argument<Int>("after") ?: 64
                    val snap = inputController.getSurroundingText(before, after)
                    if (snap == null) {
                        result.success(null)
                    } else {
                        result.success(
                            mapOf(
                                "before" to snap.before,
                                "after" to snap.after,
                                "selectionStart" to snap.selectionStart,
                                "selectionEnd" to snap.selectionEnd,
                                "isPassword" to snap.isPassword,
                            ),
                        )
                    }
                }
                "actionHaptic" -> {
                    val view = hapticView
                    if (view != null && haptics != null) {
                        haptics.actionSuccess(view)
                    }
                    result.success(null)
                }
                "matWarningHaptic" -> {
                    val view = hapticView
                    if (view != null && haptics != null) {
                        haptics.matWarning(view)
                    }
                    result.success(null)
                }
                "setFeedback" -> {
                    val vibration = call.argument<Boolean>("vibration") ?: true
                    val sound = call.argument<Boolean>("sound") ?: false
                    val matVibration = call.argument<Boolean>("matVibration") ?: true
                    haptics?.setEnabled(vibration, sound, matVibration)
                    result.success(null)
                }
                "setSelection" -> {
                    val start = call.argument<Int>("start") ?: 0
                    val end = call.argument<Int>("end") ?: start
                    inputController.setSelection(start, end)
                    result.success(null)
                }
                "moveCursor" -> {
                    val delta = call.argument<Int>("delta") ?: 0
                    inputController.moveCursorBy(delta)
                    result.success(null)
                }
                "ready" -> {
                    FlutterEngineHost.markDartReady()
                    sendTheme()
                    flushPending()
                    onRequestRepaint?.invoke()
                    result.success(null)
                }
                "requestRepaint" -> {
                    onRequestRepaint?.invoke()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (t: Throwable) {
            result.error("bridge_error", t.message, null)
        }
    }

    companion object {
        const val BRIDGE_CHANNEL: String = "com.example.tact.ime/bridge"
        private const val TAG = "ImeBridge"
        private const val MAX_PENDING = 32
    }
}

