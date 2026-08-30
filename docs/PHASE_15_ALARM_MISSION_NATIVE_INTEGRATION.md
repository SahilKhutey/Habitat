# Habitat Phase 15 — Complete Alarm ↔ Mission Native Integration

## Overview
Phase 15 connects the alarm lifecycle directly to native OS execution mechanisms:
```
ALARM SCHEDULED
       ↓
NATIVE OS ALARM (AlarmManager / UNUserNotificationCenter)
       ↓
ALARM FIRES (Lock-screen Wake + Siren Service)
       ↓
ACTIVE MISSION HYDRATION
       ↓
CAMERA ACTION / PROOF
       ↓
PHASE 14 VERIFICATION
       ↓
       ├── REJECT → 5-MIN RETRY (Up to 6 attempts)
       │
       └── ACCEPT
             ↓
       COMPLETE MISSION
             ↓
       CANCEL NATIVE RETRIES & STOP SIREN
             ↓
       XP + STREAK PERSISTENCE
```

## Component Architecture
1. **Android Native Layer**:
   - `NativeAlarmPlugin.kt`: Exact alarm permission checking and `AlarmManager.setExactAndAllowWhileIdle()`.
   - `AlarmReceiver.kt`: BroadcastReceiver waking CPU and launching foreground service.
   - `AlarmForegroundService.kt`: `AudioAttributes.USAGE_ALARM` siren playback and full-screen intent.
   - `BootReceiver.kt`: Reschedules pending alarms upon device reboot.
2. **iOS Layer**:
   - `UNUserNotificationCenter` with bounded notification chain (`T+0`, `T+5`, `T+10`, `T+15`, `T+20`, `T+25`).
3. **Flutter Bridge**:
   - `PlatformAlarmService`: Exposes `NativeAlarmEvent` stream and cold-start pending event handler.
   - `HabitatAppController`: Listens to `alarmEvents`, hydrates `LocalTaskAttempt`, and navigates to active mission.
   - `MissionExecutionService`: Automatically invokes `cancelAlarm()` and `stopSiren()` on verified completion.
4. **Backend Occurrence Ledger**:
   - `POST /api/v1/alarms/occurrences/:occurrenceId/trigger`: Records native alarm trigger.
   - `POST /api/v1/alarms/occurrences/:occurrenceId/disarm`: Disarms occurrence on verified mission completion.
