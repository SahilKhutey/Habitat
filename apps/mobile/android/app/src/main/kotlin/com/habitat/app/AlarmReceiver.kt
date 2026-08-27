package com.habitat.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val missionId = intent.getStringExtra("mission_id") ?: "unknown"
        val taskTitle = intent.getStringExtra("task_title") ?: "Morning Mission"
        val sirenVolume = intent.getIntExtra("siren_volume", 70)
        val attemptIndex = intent.getIntExtra("attempt_index", 1)

        val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
            putExtra("mission_id", missionId)
            putExtra("task_title", taskTitle)
            putExtra("siren_volume", sirenVolume)
            putExtra("attempt_index", attemptIndex)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(serviceIntent)
        } else {
            context.startService(serviceIntent)
        }
    }
}
