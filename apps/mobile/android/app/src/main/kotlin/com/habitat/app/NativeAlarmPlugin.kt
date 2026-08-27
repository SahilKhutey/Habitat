package com.habitat.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class NativeAlarmPlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "scheduleExactAlarm" -> {
                val missionId = call.argument<String>("missionId") ?: "unknown"
                val taskTitle = call.argument<String>("taskTitle") ?: "Mission"
                val triggerEpochMs = call.argument<Long>("triggerEpochMs") ?: System.currentTimeMillis()
                val sirenVolume = call.argument<Int>("sirenVolume") ?: 70
                val attemptIndex = call.argument<Int>("attemptIndex") ?: 1

                scheduleAlarm(missionId, taskTitle, triggerEpochMs, sirenVolume, attemptIndex)
                result.success(true)
            }
            "cancelAlarm" -> {
                val missionId = call.argument<String>("missionId") ?: ""
                cancelAlarm(missionId)
                result.success(true)
            }
            "stopSiren" -> {
                val serviceIntent = Intent(context, AlarmForegroundService::class.java)
                context.stopService(serviceIntent)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun scheduleAlarm(
        missionId: String,
        taskTitle: String,
        triggerEpochMs: Long,
        sirenVolume: Int,
        attemptIndex: Int
    ) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.habitat.app.ACTION_TRIGGER_MISSION"
            putExtra("mission_id", missionId)
            putExtra("task_title", taskTitle)
            putExtra("siren_volume", sirenVolume)
            putExtra("attempt_index", attemptIndex)
        }

        val pendingIntent = PendingIntent.getBroadcast(
            context,
            missionId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerEpochMs, pendingIntent)
        } else {
            alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerEpochMs, pendingIntent)
        }
    }

    private fun cancelAlarm(missionId: String) {
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = "com.habitat.app.ACTION_TRIGGER_MISSION"
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            missionId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent)
    }
}
