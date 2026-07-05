package com.example.tact.ime

import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

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

    /** Native repaint hook — IME FlutterView may not paint after Dart setState alone. */
    var onRequestRepaint: (() -> Unit)? = null

    init {
        channel.setMethodCallHandler(this)
    }

    // ── Native → Dart ─────────────────────────────────────────────────

    fun sendTheme() = invokeDart("setTheme", themePayload())

    fun onStartInputView(packageName: String?, inputType: Int, imeOptions: Int, locale: String?) {
        val payload = JSONObject().apply {
            put("packageName", packageName)
            put("inputType", inputType)
            put("imeOptions", imeOptions)
            put("locale", locale)
        }.toString()
        invokeDart("onStartInputView", payload)
    }

    fun onFinishInputView() = invokeDart("onFinishInputView", null)

    fun onWordCommitted(info: WordCommitInfo, locale: String) {
        val payload = wordPayload(info, locale, partial = false)
        Log.d(TAG, "word committed: '${info.word}' locale=$locale")
        invokeDart("onWordCommitted", payload)
    }

    fun onPartialWordCommitted(info: WordCommitInfo?, locale: String) {
        if (info == null) {
            invokeDart("onPartialWordClear", null)
            return
        }
        val payload = wordPayload(info, locale, partial = true)
        invokeDart("onPartialWord", payload)
    }

    fun onTextEdited() = invokeDart("onTextEdited", null)

    fun onSelectionChanged(oldStart: Int, oldEnd: Int, newStart: Int, newEnd: Int) {
        val payload = JSONObject().apply {
            put("oldStart", oldStart); put("oldEnd", oldEnd)
            put("newStart", newStart); put("newEnd", newEnd)
        }.toString()
        invokeDart("onSelectionChanged", payload)
    }

    private fun wordPayload(info: WordCommitInfo, locale: String, partial: Boolean): String =
        JSONObject().apply {
            put("word", info.word)
            put("locale", locale)
            put("deleteBefore", info.deleteBefore)
            put("deleteAfter", info.deleteAfter)
            put("boundary", info.boundary)
            put("before", info.before)
            put("after", info.after)
            put("partial", partial)
        }.toString()

    private fun themePayload(): String =
        JSONObject().apply {
            put("background", Theme.COLOR_KEYBOARD_BG)
            put("keyText", Theme.COLOR_KEY_TEXT)
            put("accent", Theme.COLOR_KEY_ACCENT_BG)
        }.toString()

    private fun invokeDart(method: String, arguments: Any?) {
        mainHandler.post {
            if (!FlutterEngineHost.isDartReady()) {
                pending.addLast(method to arguments)
                if (pending.size > MAX_PENDING) pending.removeFirst()
                Log.d(TAG, "queued $method (pending=${pending.size})")
                return@post
            }
            dispatchDart(method, arguments)
        }
    }

    private fun dispatchDart(method: String, arguments: Any?) {
        try {
            channel.invokeMethod(method, arguments)
            if (method == "onWordCommitted" || method == "onPartialWord" || method == "onTextEdited") {
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

    fun dispose() {
        channel.setMethodCallHandler(null)
        pending.clear()
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
                            JSONObject().apply {
                                put("selectionStart", outcome.selectionStart)
                                put("selectionEnd", outcome.selectionEnd)
                                put("replacedText", outcome.replacedText)
                                put("insertedLength", outcome.insertedLength)
                                put("previousSelectionStart", outcome.previousSelectionStart)
                                put("previousSelectionEnd", outcome.previousSelectionEnd)
                            }.toString(),
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
                            JSONObject().apply {
                                put("before", snap.before)
                                put("after", snap.after)
                                put("selectionStart", snap.selectionStart)
                                put("selectionEnd", snap.selectionEnd)
                                put("isPassword", snap.isPassword)
                            }.toString(),
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

