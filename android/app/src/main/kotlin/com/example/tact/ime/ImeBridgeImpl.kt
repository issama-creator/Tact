package com.example.tact.ime

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

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
) : MethodChannel.MethodCallHandler {

    private val channel: MethodChannel =
        MethodChannel(engine.dartExecutor.binaryMessenger, BRIDGE_CHANNEL)

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

    fun onWordCommitted(word: String, locale: String) {
        val payload = JSONObject().apply {
            put("word", word)
            put("locale", locale)
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
        try {
            channel.invokeMethod(method, arguments)
        } catch (t: Throwable) {
            android.util.Log.w("ImeBridge", "invokeDart $method failed", t)
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
                    // The controller only exposes 1-char backward delete for the
                    // MVP. When richer edits are needed, extend InputController.
                    repeat(before) { inputController.deleteBackward() }
                    if (after > 0) {
                        // Best-effort forward delete via keycode.
                        // Kept minimal: current MVP does not use it.
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
