package com.habitat.app

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class AlarmForegroundService : Service() {
    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null

    companion object {
        const val CHANNEL_ID = "habitat_alarm_channel"
        const val NOTIFICATION_ID = 7001
        const val MAX_RETRIES = 6
        const val RETRY_INTERVAL_MS = 5 * 60 * 1000L // 5 minutes
        var isRunning = false
        @Volatile var currentMissionId: String? = null
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        isRunning = true

        val missionId  = intent?.getStringExtra("mission_id")   ?: "unknown"
        val taskTitle  = intent?.getStringExtra("task_title")    ?: "Mission Active"
        val attemptIndex = intent?.getIntExtra("attempt_index", 1) ?: 1
        val sirenVolume  = intent?.getIntExtra("siren_volume", 70) ?: 70

        storeMissionId(missionId)

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        @Suppress("DEPRECATION")
        wakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or
            PowerManager.ACQUIRE_CAUSES_WAKEUP or
            PowerManager.ON_AFTER_RELEASE,
            "Habitat:AlarmWakeLock"
        ).apply {
            acquire(10 * 60 * 1000L) // 10-minute safety cap
        }

        // ── 2. Full-Screen Intent (wakes lock screen) ─────────────────────────
        val fullScreenIntent = Intent(this, MainActivity::class.java).apply {
            this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/mission/$missionId/active")
            putExtra("task_title", taskTitle)
            putExtra("attempt_index", attemptIndex)
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this, 0, fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // ── 3. High-Priority Foreground Notification ──────────────────────────
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("🔴 $taskTitle")
            .setContentText("Attempt $attemptIndex • Complete mission to dismiss.")
            .setSmallIcon(android.R.drawable.ic_lock_idle_alarm)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setOngoing(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)

        // ── 4. Play Siren Audio (USAGE_ALARM, looping) ───────────────────────
        playAlarmAudio(sirenVolume)

        // ── 5. Schedule Escalation Retry at T+5min ────────────────────────────
        // Escalation is handled entirely in native Kotlin so it survives
        // the Flutter engine being backgrounded or killed.
        if (attemptIndex < MAX_RETRIES) {
            scheduleEscalation(
                missionId   = missionId,
                taskTitle   = taskTitle,
                attemptIndex = attemptIndex,
                sirenVolume  = sirenVolume
            )
        }

        return START_STICKY
    }

    /**
     * Schedules the next escalation attempt via AlarmManager so it fires
     * even if the device enters Doze after the user dismisses the screen.
     *
     * Volume escalation: attempt 1→70%, 2→85%, 3→100%, 4+→100%
     */
    private fun scheduleEscalation(
        missionId: String,
        taskTitle: String,
        attemptIndex: Int,
        sirenVolume: Int
    ) {
        val nextAttempt = attemptIndex + 1
        val nextVolume = when (nextAttempt) {
            2    -> 85
            else -> 100
        }
        val triggerMs = System.currentTimeMillis() + RETRY_INTERVAL_MS

        val escalationIntent = Intent(this, AlarmReceiver::class.java).apply {
            action = "com.habitat.app.ACTION_TRIGGER_MISSION"
            putExtra("mission_id", missionId)
            putExtra("task_title", taskTitle)
            putExtra("siren_volume", nextVolume)
            putExtra("attempt_index", nextAttempt)
        }

        // Use missionId.hashCode() + attempt as request code so each attempt
        // gets a unique PendingIntent that can be cancelled independently.
        val requestCode = missionId.hashCode() + nextAttempt
        val pendingIntent = PendingIntent.getBroadcast(
            this,
            requestCode,
            escalationIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP, triggerMs, pendingIntent
                )
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerMs, pendingIntent)
            }
        } catch (e: SecurityException) {
            // No exact alarm permission — fall back to inexact (Doze may delay by up to 10min)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerMs, pendingIntent)
            } else {
                alarmManager.set(AlarmManager.RTC_WAKEUP, triggerMs, pendingIntent)
            }
        }
    }

    /**
     * Cancels all pending escalation PendingIntents for this missionId
     * (called when user disarms the alarm).
     */
    private fun cancelPendingEscalations(missionId: String) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        // Cancel attempts 2..MAX_RETRIES
        for (attempt in 2..MAX_RETRIES + 1) {
            val requestCode = missionId.hashCode() + attempt
            val cancelIntent = Intent(this, AlarmReceiver::class.java).apply {
                action = "com.habitat.app.ACTION_TRIGGER_MISSION"
            }
            val pendingIntent = PendingIntent.getBroadcast(
                this,
                requestCode,
                cancelIntent,
                PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
            ) ?: continue
            alarmManager.cancel(pendingIntent)
            pendingIntent.cancel()
        }
    }

    private fun playAlarmAudio(volumePercent: Int) {
        try {
            val alertUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)

            mediaPlayer = MediaPlayer().apply {
                setDataSource(applicationContext, alertUri)
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                isLooping = true
                val vol = volumePercent / 100f
                setVolume(vol, vol)
                prepare()
                start()
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false

        // Cancel any pending escalations — user disarmed
        // We need the missionId here; it's not stored on onDestroy since
        // START_STICKY may restart us. Store in a companion field.
        currentMissionId?.let { cancelPendingEscalations(it) }

        mediaPlayer?.stop()
        mediaPlayer?.release()
        mediaPlayer = null

        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Habitat Wake-up Sirens",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Critical mission wake-up alarms"
                setBypassDnd(true)
                enableVibration(true)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    // Store missionId when service starts
    private fun storeMissionId(id: String) { currentMissionId = id }
}
