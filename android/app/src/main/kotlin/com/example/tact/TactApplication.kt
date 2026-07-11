package com.example.tact

import android.app.Application
import android.os.Handler
import android.os.Looper
import android.util.Log
import com.example.tact.ime.FlutterEngineHost
import io.flutter.FlutterInjector

/**
 * Boots the Flutter loader and, on non-debuggable builds, eagerly prewarms
 * the IME [FlutterEngine] so the first keyboard open is not a ~1s hitch.
 *
 * Debuggable (`flutter run`) skips eager prewarm — see [FlutterEngineHost].
 */
class TactApplication : Application() {

    companion object {
        private const val TAG = "TactApplication"
    }

    override fun onCreate() {
        super.onCreate()
        val app = this
        try {
            FlutterInjector.instance().flutterLoader().startInitialization(app)
        } catch (t: Throwable) {
            Log.w(TAG, "Flutter loader start deferred", t)
            return
        }
        Handler(Looper.getMainLooper()).post {
            try {
                FlutterInjector.instance()
                    .flutterLoader()
                    .ensureInitializationComplete(app, null)
                FlutterEngineHost.tryEagerPrewarm(app)
            } catch (t: Throwable) {
                Log.w(TAG, "IME Flutter prewarm deferred", t)
            }
        }
    }
}
