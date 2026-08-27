# ADR-007: Mobile Native Alarm & Wake-up Lockdown Integration

## Status
Accepted (2026-08-27)

## Context
Standard mobile push notifications are insufficient for an alarm discipline engine because:
1. Android Doze Mode and OEM battery optimizations suppress delayed background notifications.
2. iOS physical silent/mute switch silences standard system notifications.
3. Users waking up need an immediate, zero-friction full-screen mission HUD rather than having to unlock, search for an app icon, and open a screen.

## Decision
Implement platform-specific native alarm modules via Flutter `MethodChannel`:
* **Android (Kotlin)**: `AlarmManager.setExactAndAllowWhileIdle()` + `AlarmForegroundService` (`FOREGROUND_SERVICE_MEDIA_PLAYBACK`) + `fullScreenIntent` Notification waking the screen immediately.
* **iOS (Swift)**: `AVAudioSessionCategoryPlayback` with `.duckOthers` to override the physical silent switch + `UNNotificationSound.defaultCriticalSound` for Critical Alerts bypass.

## Consequences
* **Positive**: 100% reliable wake-up alarms with unkillable sirens and zero-friction lock-screen presentation.
* **Tradeoff**: Requires maintaining native Swift and Kotlin modules alongside Flutter.
