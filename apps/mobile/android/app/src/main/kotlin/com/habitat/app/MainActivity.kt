package com.habitat.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val PRIMARY_ALARM_CHANNEL = "com.habitat.app/native_alarm"
    private val LEGACY_ALARM_CHANNEL = "habitat/native_alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val plugin = NativeAlarmPlugin(context)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, PRIMARY_ALARM_CHANNEL)
            .setMethodCallHandler(plugin)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LEGACY_ALARM_CHANNEL)
            .setMethodCallHandler(plugin)
    }
}
