package com.fschmatz.podmatz

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.fschmatz.podmatz/wakelock").setMethodCallHandler { call, result ->
            when (call.method) {
                "releaseWakeLock" -> {
                    WakeLockHelper.releaseWakeLock()
                    result.success(true)
                }
                "acquireWakeLock" -> {
                    WakeLockHelper.acquireWakeLock()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }
}
