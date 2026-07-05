package com.example.tact.ime

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import android.view.View

/**
 * Minimal, working MethodChannel bridge between the native IME and Dart.
 *
 * The bridge is DELIBERATELY narrow at this stage — the Dart side hosts
 * only an empty suggestion-bar container. The bridge is set up so that:
 *
 *   1. Dart can call INTO native for text mutations
 *      (`commitText`, `deleteSurrounding`, `replaceRange`, `setComposing`).
 *      For the current scope these delegate to [InputController].
 *
 *   2. Native can call INTO Dart for lifecycle notifications
 *      (`onStartInputView`, `onFinishInputView`, `onSelectionChanged`,
 *      `onWordCommitted`) — used later by the engines when they ship.
 *
 *   3. Native can push a theme snapshot into Dart so the suggestion bar
 *      background matches the key grid on first paint.
 *
 * When Pigeon lands, [BRIDGE_CHANNEL] becomes the channel of a generated,
 * typed API. Nothing above this file changes.
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
        val payload = JSONObject().apply {
            put("word", info.word)
            put("locale", locale)
            put("deleteBefore", info.deleteBefore)
            put("deleteAfter", info.deleteAfter)
            put("boundary", info.boundary)
            put("before", info.before)
            put("after", info.after)
        }.toString()
        invokeDart("onWordCommitted", payload)
    }

    fun onSelectionChanged(oldStart: Int, oldEnd: Int, newStart: Int, newEnd: Int) {
        val payload = JSONObject().apply {
            put("oldStart", oldStart); put("oldEnd", oldEnd)
            put("newStart", newStart); put("newEnd", newEnd)
        }.toString()
        invokeDart("onSelectionChanged", payload)
    }

    private fun themePayload(): String =
        JSONObject().apply {
            put("background", Theme.COLOR_KEYBOARD_BG)
            put("keyText", Theme.COLOR_KEY_TEXT)
            put("accent", Theme.COLOR_KEY_ACCENT_BG)
        }.toString()

    private fun invokeDart(method: String, arguments: Any?) {
        mainHandler.post {
            try {
                channel.invokeMethod(method, arguments)
            } catch (t: Throwable) {
                android.util.Log.w("ImeBridge", "invokeDart $method failed", t)
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
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
                    // Dart signals the bar is up. Push initial theme.
                    sendTheme()
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
    }
}
