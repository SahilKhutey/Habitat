package com.habitat.app

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PRIMARY_ALARM_CHANNEL = "com.habitat.app/native_alarm"
    private val LEGACY_ALARM_CHANNEL = "habitat/native_alarm"
    private var pendingInitialRoute: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val plugin = NativeAlarmPlugin(context)

        // Extract launch route from notification / full-screen intent
        val launchRoute = intent?.getStringExtra("route")
        if (!launchRoute.isNullOrBlank()) {
            pendingInitialRoute = launchRoute
        }

        val handler = MethodChannel.MethodCallHandler { call, result ->
            when (call.method) {
                "getInitialRoute" -> {
                    val r = pendingInitialRoute
                    pendingInitialRoute = null
                    result.success(r)
                }
                else -> plugin.onMethodCall(call, result)
            }
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRIMARY_ALARM_CHANNEL)
            .setMethodCallHandler(handler)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LEGACY_ALARM_CHANNEL)
            .setMethodCallHandler(handler)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val route = intent.getStringExtra("route")
        if (!route.isNullOrBlank()) {
            flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                MethodChannel(messenger, PRIMARY_ALARM_CHANNEL).invokeMethod("onNotificationRoute", route)
                MethodChannel(messenger, LEGACY_ALARM_CHANNEL).invokeMethod("onNotificationRoute", route)
            }
        }
    }
}

