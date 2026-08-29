# Android Build & Release Engineering

## Application Identity
- **Package Name:** `com.habitat.discipline`
- **Application Label:** `Discipline`
- **Minimum SDK:** 24 (Android 7.0+)
- **Target SDK:** 34 (Android 14+)

## Notification Channels
The Android implementation configures granular notification channels:
1. `DISCIPLINE_ALARM` - High-priority exact alarms with full-screen intent capabilities.
2. `TASK_REMINDERS` - Routine and task upcoming reminder notifications.
3. `TASK_RESULTS` - Automated proof verification confirmations and reward updates.
4. `ACHIEVEMENTS` - Milestone and level-up celebratory alerts.
5. `SOCIAL` - Accountability partner nudges and shared challenge events.

## Build Artifacts
- **APK (`.apk`):** For direct sideloading, internal QA, and physical device test matrices.
- **AAB (`.aab`):** For Google Play Console production distribution with dynamic feature delivery and split APKs.

```bash
# Build Android artifacts
./scripts/build-android.sh
```
