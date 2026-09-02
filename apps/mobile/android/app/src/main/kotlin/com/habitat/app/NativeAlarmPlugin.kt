package com.habitat.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativeAlarmPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "HabitatAlarm"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "canScheduleExactAlarms" -> {
                val canExact = checkCanScheduleExactAlarms()
                Log.d(TAG, "ALARM_PERMISSION_CHECK: canScheduleExact=$canExact")
                result.success(canExact)
            }
            "openExactAlarmSettings" -> {
                openExactAlarmSettings()
                result.success(true)
            }
            "isIgnoringBatteryOptimizations" -> {
                result.success(checkIsIgnoringBatteryOptimizations())
            }
            "openBatteryOptimizationSettings" -> {
                openBatteryOptimizationSettings()
                result.success(true)
            }
            "getDeviceManufacturer" -> {
                result.success(Build.MANUFACTURER ?: "Unknown")
            }
            "scheduleExactAlarm" -> {
                val missionId = call.argument<String>("missionId") ?: "unknown"
                val taskTitle = call.argument<String>("taskTitle") ?: "Mission"
                val triggerEpochMs = call.argument<Long>("triggerEpochMs") ?: System.currentTimeMillis()
                val sirenVolume = call.argument<Int>("sirenVolume") ?: 70
                val attemptIndex = call.argument<Int>("attemptIndex") ?: 1

                Log.i(TAG, "ALARM_SCHEDULE_REQUEST: missionId=$missionId triggerAt=$triggerEpochMs volume=$sirenVolume attempt=$attemptIndex")
                val scheduleResult = scheduleAlarmWithFallback(missionId, taskTitle, triggerEpochMs, sirenVolume, attemptIndex)
                result.success(scheduleResult)
            }
            "cancelAlarm" -> {
                val missionId = call.argument<String>("missionId") ?: ""
                Log.i(TAG, "ALARM_CANCELLED: missionId=$missionId")
                cancelAlarm(missionId)
                result.success(true)
            }
            "stopSiren" -> {
                try {
                    val serviceIntent = Intent(context, AlarmForegroundService::class.java)
                    context.stopService(serviceIntent)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun checkCanScheduleExactAlarms(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarmManager.canScheduleExactAlarms()
        } else {
            true
        }
    }

    private fun openExactAlarmSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                    data = Uri.parse("package:${context.packageName}")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
            } catch (e: Exception) {
                // Fallback to app details settings if specific action fails
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
            }
        }
    }

    private fun checkIsIgnoringBatteryOptimizations(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            powerManager.isIgnoringBatteryOptimizations(context.packageName)
        } else {
            true
        }
    }

    private fun openBatteryOptimizationSettings() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
            } catch (e: Exception) {
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.parse("package:${context.packageName}")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(intent)
            }
        }
    }

    private fun scheduleAlarmWithFallback(
        missionId: String,
        taskTitle: String,
        triggerEpochMs: Long,
        sirenVolume: Int,
        attemptIndex: Int
    ): Map<String, Any?> {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.habitat.app.ACTION_TRIGGER_MISSION"
            putExtra("mission_id", missionId)
            putExtra("task_title", taskTitle)
            putExtra("siren_volume", sirenVolume)
            putExtra("attempt_index", attemptIndex)
        }

        val requestCode = missionId.hashCode()
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val canExact = checkCanScheduleExactAlarms()
        var isExact = false
        var failureReason: String? = null

        if (canExact) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerEpochMs, pendingIntent)
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerEpochMs, pendingIntent)
                }
                isExact = true
                Log.i(TAG, "ALARM_SCHEDULED: missionId=$missionId requestCode=$requestCode triggerAt=$triggerEpochMs exact=true")
            } catch (e: SecurityException) {
                // Exact alarm permission was revoked after runtime check; fallback gracefully
                failureReason = "EXACT_ALARM_SECURITY_EXCEPTION"
                Log.w(TAG, "ALARM_SCHEDULED: missionId=$missionId exact=false fallback=SecurityException")
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerEpochMs, pendingIntent)
                } else {
                    alarmManager.set(AlarmManager.RTC_WAKEUP, triggerEpochMs, pendingIntent)
                }
            } catch (e: Exception) {
                failureReason = e.message
                Log.e(TAG, "ALARM_SCHEDULED: failed with exception: ${e.message}")
            }
        } else {
            failureReason = "EXACT_ALARM_PERMISSION_NOT_GRANTED"
            Log.w(TAG, "ALARM_SCHEDULED: missionId=$missionId exact=false fallback=EXACT_ALARM_PERMISSION_NOT_GRANTED")
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerEpochMs, pendingIntent)
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerEpochMs, pendingIntent)
            }
        }

        return mapOf(
            "scheduled" to true,
            "exact" to isExact,
            "reason" to failureReason
        )
    }

    private fun cancelAlarm(missionId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.habitat.app.ACTION_TRIGGER_MISSION"
        }
        val requestCode = missionId.hashCode()
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
        Log.i(TAG, "ALARM_CANCELLED: cancelled requestCode=$requestCode missionId=$missionId")
    }
}

