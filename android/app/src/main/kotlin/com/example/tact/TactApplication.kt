package com.example.tact

import android.app.Application
import io.flutter.FlutterInjector

/**
 * Application entry that boots the Flutter engine loader before any
 * component (Activity or IME Service) needs it.
 *
 * Without this, [com.example.tact.ime.TactInputMethodService] can start
 * cold — the user enables TACT and opens a text field without ever
 * launching [MainActivity]. In that case FlutterLoader was never started
 * and the IME crashed in onCreate while pre-warming the engine.
 */
class TactApplication : Application() {

    override fun onCreate() {
        super.onCreate()
        FlutterInjector.instance().flutterLoader().startInitialization(this)
    }
}
