package com.example.tact.ime

import android.content.Context
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Process-wide cache of a pre-warmed [FlutterEngine] dedicated to the IME.
 *
 * The engine runs the Dart top-level function `imeMain`. If engine boot
 * fails for any reason, [tryPrewarm] returns null and the keyboard still
 * renders — the native key grid does not depend on Flutter.
 */
object FlutterEngineHost {

    private const val TAG = "TactFlutterEngine"
    private const val ENTRYPOINT = "imeMain"

    @Volatile
    private var engine: FlutterEngine? = null

    /** Warm the engine. Returns null on failure instead of crashing the IME. */
    fun tryPrewarm(context: Context): FlutterEngine? {
        engine?.let { return it }
        synchronized(this) {
            engine?.let { return it }
            return try {
                ensureFlutterInitialized(context)
                val e = FlutterEngine(context.applicationContext)
                val bundlePath =
                    FlutterInjector.instance().flutterLoader().findAppBundlePath()
                val entrypoint = DartExecutor.DartEntrypoint(bundlePath, ENTRYPOINT)
                e.dartExecutor.executeDartEntrypoint(entrypoint)
                engine = e
                Log.i(TAG, "IME FlutterEngine ready (entrypoint=$ENTRYPOINT)")
                e
            } catch (t: Throwable) {
                Log.e(TAG, "IME FlutterEngine failed to start — keys still work", t)
                null
            }
        }
    }

    fun getOrNull(): FlutterEngine? = engine

    fun release() {
        synchronized(this) {
            engine?.destroy()
            engine = null
        }
    }

    private fun ensureFlutterInitialized(context: Context) {
        val loader = FlutterInjector.instance().flutterLoader()
        val appContext = context.applicationContext
        loader.startInitialization(appContext)
        loader.ensureInitializationComplete(appContext, null)
    }
}
