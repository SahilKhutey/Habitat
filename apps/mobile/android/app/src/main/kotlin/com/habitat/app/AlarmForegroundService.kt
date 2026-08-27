package com.habitat.app

import android.app.*
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
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
        var isRunning = false
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        isRunning = true
        val missionId = intent?.getStringExtra("mission_id") ?: "unknown"
        val taskTitle = intent?.getStringExtra("task_title") ?: "Mission Active"
        val attemptIndex = intent?.getIntExtra("attempt_index", 1) ?: 1
        val sirenVolume = intent?.getIntExtra("siren_volume", 70) ?: 70

        // 1. Acquire Full Screen Wake Lock
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.FULL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP or PowerManager.ON_AFTER_RELEASE,
            "Habitat:AlarmWakeLock"
        ).apply {
            acquire(10 * 60 * 1000L) // 10 minute safety limit
        }

        // 2. Build Full Screen Intent to wake device over lock screen
        val fullScreenIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("route", "/mission/$missionId/active")
        }
        val fullScreenPendingIntent = PendingIntent.getActivity(
            this, 0, fullScreenIntent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // 3. Build High Priority Notification
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

        // 4. Play Alarm Siren with AudioAttributes.USAGE_ALARM
        playAlarmAudio(sirenVolume)

        return START_STICKY
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
}
