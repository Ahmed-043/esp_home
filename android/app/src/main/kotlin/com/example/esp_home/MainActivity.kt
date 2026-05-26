package com.example.esp_home

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingInitialAction: String? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        pendingInitialAction = intent?.getStringExtra(EXTRA_OPEN_ACTION)
    }

    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        pendingInitialAction = intent.getStringExtra(EXTRA_OPEN_ACTION)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            WIDGET_CHANNEL,
        ).setMethodCallHandler { call, result ->
            if (call.method == "consumeInitialAction") {
                result.success(pendingInitialAction)
                pendingInitialAction = null
                return@setMethodCallHandler
            }
            result.notImplemented()
        }
    }

    companion object {
        const val WIDGET_CHANNEL = "esp_home/widget_actions"
        const val EXTRA_OPEN_ACTION = "open_action"
    }
}
