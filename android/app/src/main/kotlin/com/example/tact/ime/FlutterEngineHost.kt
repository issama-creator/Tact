package com.example.tact.ime

import android.content.Context
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Process-wide cache of a pre-warmed [FlutterEngine] dedicated to the IME.
 *
 * Runs `imeMain` from `lib/main.dart` — the only library URI guaranteed
 * to exist in every Flutter app kernel snapshot.
 */
object FlutterEngineHost {

    private const val TAG = "TactFlutterEngine"
    private const val ENTRYPOINT = "imeMain"

    // Do NOT pass a library path — null library resolves to Dart_RootLibrary(),
    // same as FlutterActivity's createDefault() which runs `main` on the app kernel.

    @Volatile
    private var engine: FlutterEngine? = null

    @Volatile
    private var dartReady = false

    fun isDartReady(): Boolean = dartReady

    fun markDartReady() {
        dartReady = true
        Log.i(TAG, "Dart IME isolate confirmed ready")
    }

    fun tryPrewarm(context: Context): FlutterEngine? {
        synchronized(this) {
            val existing = engine
            if (existing != null) {
                if (dartReady) return existing
                Log.w(TAG, "Recreating FlutterEngine — previous boot never reached Dart ready")
                destroyLocked()
            }
            return createEngineLocked(context)
        }
    }

    fun getOrNull(): FlutterEngine? = engine

    fun release() {
        synchronized(this) {
            destroyLocked()
        }
    }

    private fun createEngineLocked(context: Context): FlutterEngine? {
        return try {
            ensureFlutterInitialized(context)
            dartReady = false
            val e = FlutterEngine(context.applicationContext)
            val bundlePath =
                FlutterInjector.instance().flutterLoader().findAppBundlePath()
            val entrypoint = DartExecutor.DartEntrypoint(bundlePath, ENTRYPOINT)
            e.dartExecutor.executeDartEntrypoint(entrypoint)
            engine = e
            Log.i(TAG, "IME FlutterEngine started (root library, entrypoint=$ENTRYPOINT)")
            e
        } catch (t: Throwable) {
            Log.e(TAG, "IME FlutterEngine failed to start — keys still work", t)
            destroyLocked()
            null
        }
    }

    private fun destroyLocked() {
        try {
            engine?.destroy()
        } catch (_: Throwable) { }
        engine = null
        dartReady = false
    }

    private fun ensureFlutterInitialized(context: Context) {
        val loader = FlutterInjector.instance().flutterLoader()
        val appContext = context.applicationContext
        loader.startInitialization(appContext)
        loader.ensureInitializationComplete(appContext, null)
    }
}
