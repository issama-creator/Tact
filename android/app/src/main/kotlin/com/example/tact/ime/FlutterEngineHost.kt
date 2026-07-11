package com.example.tact.ime

import android.content.Context
import android.content.pm.ApplicationInfo
import android.os.SystemClock
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Process-wide cache of a pre-warmed [FlutterEngine] dedicated to the IME.
 *
 * Runs `imeMain` from `lib/main.dart` — the only library URI guaranteed
 * to exist in every Flutter app kernel snapshot.
 *
 * Boot policy:
 * - **Release / non-debuggable:** [tryEagerPrewarm] from Application so the
 *   first keyboard open is warm.
 * - **Debug (`flutter run`):** never eager-prewarm at process start — a second
 *   isolate races the companion VM service (Lost connection / DevFSException).
 *   Warm from [KeyboardRootView] on first open, or via delayed debug prewarm
 *   after the companion engine is already attached.
 *
 * Never destroy an engine that is still booting (mid-boot recreate → jank).
 */
object FlutterEngineHost {

    private const val TAG = "TactFlutterEngine"
    private const val ENTRYPOINT = "imeMain"

    /** Only recreate if Dart never signals ready within this window. */
    private const val STUCK_BOOT_MS = 12_000L

    /**
     * After companion VM Service is up, debug builds may warm the IME isolate
     * without stealing the initial DDS handshake.
     */
    const val DEBUG_PREWARM_DELAY_MS = 2_500L

    @Volatile
    private var engine: FlutterEngine? = null

    @Volatile
    private var dartReady = false

    @Volatile
    private var bootStartedAtMs = 0L

    fun isDartReady(): Boolean = dartReady

    fun isDebuggable(context: Context): Boolean =
        (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0

    fun markDartReady() {
        dartReady = true
        Log.i(TAG, "Dart IME isolate confirmed ready")
    }

    /**
     * Process-start prewarm for store / release builds only.
     * No-op when [isDebuggable] so `flutter run` stays stable.
     */
    fun tryEagerPrewarm(context: Context): FlutterEngine? {
        if (isDebuggable(context)) {
            Log.i(TAG, "Skip eager IME prewarm (debuggable — lazy / delayed only)")
            return null
        }
        return tryPrewarm(context)
    }

    fun tryPrewarm(context: Context): FlutterEngine? {
        synchronized(this) {
            val existing = engine
            if (existing != null) {
                if (dartReady) return existing
                val elapsed = SystemClock.uptimeMillis() - bootStartedAtMs
                if (elapsed < STUCK_BOOT_MS) {
                    // Still warming — return the same instance. Destroying here
                    // forced a second Dart boot on the first keyboard open.
                    return existing
                }
                Log.w(TAG, "FlutterEngine boot stuck ${elapsed}ms — recreating")
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
            bootStartedAtMs = SystemClock.uptimeMillis()
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
        bootStartedAtMs = 0L
    }

    private fun ensureFlutterInitialized(context: Context) {
        val loader = FlutterInjector.instance().flutterLoader()
        val appContext = context.applicationContext
        loader.startInitialization(appContext)
        loader.ensureInitializationComplete(appContext, null)
    }
}
