package com.edutech.edutech_app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Content protection: FLAG_SECURE blocks screenshots AND screen
        // recording AND the app-switcher thumbnail for the whole app. This is a
        // real OS-level guarantee on Android (unlike the web, where it's only
        // best-effort). Set before super.onCreate so it applies from first frame.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        super.onCreate(savedInstanceState)
    }
}
