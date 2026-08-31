package com.habitat.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import org.json.JSONArray

class BootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "HabitatBootReceiver"
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val PREFS_KEY = "flutter.habitat_pending_alarms"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "BootReceiver received action: $action")

        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_MY_PACKAGE_REPLACED ||
            action == "android.intent.action.QUICKBOOT_POWERON" ||
            action == "com.htc.intent.action.QUICKBOOT_POWERON"
        ) {
            Log.i(TAG, "System rebooted / package replaced. Restoring active alarms from durable store.")
            restoreActiveAlarms(context)
        }
    }

    private fun restoreActiveAlarms(context: Context) {
        try {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val json = prefs.getString(PREFS_KEY, null)

            if (json.isNullOrBlank()) {
                Log.i(TAG, "No pending alarms to restore.")
                return
            }

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
            val array = JSONArray(json)
            val now = System.currentTimeMillis()
            var restored = 0

            for (i in 0 until array.length()) {
                val entry = array.getJSONObject(i)
                val triggerEpochMs = entry.getLong("triggerEpochMs")
                val missionId = entry.getString("missionId")
                val taskTitle = entry.optString("taskTitle", "Mission")
                val sirenVolume = entry.optInt("sirenVolume", 70)
                val attemptIndex = entry.optInt("attemptIndex", 1)

                // Skip alarms that fired more than 60 seconds ago
                if (triggerEpochMs < now - 60_000L) {
                    Log.d(TAG, "Skipping expired alarm: $missionId at $triggerEpochMs")
                    continue
                }

                // Re-arm the alarm via AlarmManager
                val alarmIntent = Intent(context, AlarmReceiver::class.java).apply {
                    action = "com.habitat.app.ACTION_TRIGGER_MISSION"
                    putExtra("mission_id", missionId)
                    putExtra("task_title", taskTitle)
                    putExtra("siren_volume", sirenVolume)
                    putExtra("attempt_index", attemptIndex)
                }

                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    missionId.hashCode(),
                    alarmIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )

                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setExactAndAllowWhileIdle(
                            AlarmManager.RTC_WAKEUP,
                            triggerEpochMs,
                            pendingIntent
                        )
                    } else {
                        alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerEpochMs, pendingIntent)
                    }
                    restored++
                    Log.i(TAG, "Restored alarm: $missionId at $triggerEpochMs")
                } catch (e: SecurityException) {
                    // Exact alarm permission revoked — fall back to inexact
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerEpochMs, pendingIntent)
                    } else {
                        alarmManager.set(AlarmManager.RTC_WAKEUP, triggerEpochMs, pendingIntent)
                    }
                    restored++
                    Log.w(TAG, "Restored alarm with inexact fallback (no SCHEDULE_EXACT_ALARM): $missionId")
                }
            }

            Log.i(TAG, "Boot restore complete. Restored $restored alarm(s).")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to restore alarms on boot", e)
        }
    }
}
