package com.lesgo.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.lesgo.app/affiliate")
            .setMethodCallHandler { call, result ->
                if (call.method != "openAffiliate") {
                    result.notImplemented()
                } else {
                    try {
                        val intent = packageManager.getLaunchIntentForPackage("com.lesgo.rider")
                        if (intent == null) result.success(false)
                        else { startActivity(intent); result.success(true) }
                    } catch (_: Exception) { result.success(false) }
                }
            }
    }
}
