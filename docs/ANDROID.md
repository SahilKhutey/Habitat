# Android Build & Release Engineering

## Application Identity
- **Package Name:** `com.habitat.app`
- **Application Label:** `Habitat`
- **Minimum SDK:** 24 (Android 7.0+)
- **Target SDK:** 36 (Android 16)
- **Compile SDK:** 36 (Android 16)
- **NDK Version:** `25.1.8937393`
- **CMake Version:** `3.22.1`
- **Java Compatibility:** Java 17 (OpenJDK 17.0.20.1)

## Notification Channels & Foreground Services
The Android implementation configures high-priority notification channels and background services:
1. `habitat_alarm_channel` (`AlarmForegroundService`) - High-priority exact alarms with full-screen intent capabilities, wake-locks, and volume escalation.
2. `DISCIPLINE_ALARM` - High-priority exact alarms with full-screen intent capabilities.
3. `TASK_REMINDERS` - Routine and task upcoming reminder notifications.
4. `TASK_RESULTS` - Automated proof verification confirmations and reward updates.
5. `ACHIEVEMENTS` - Milestone and level-up celebratory alerts.
6. `SOCIAL` - Accountability partner nudges and shared challenge events.

## Build Artifacts
- **Debug APK (`app-debug.apk`):** For virtual emulator validation, local ADB deployment, and end-to-end integration testing.
- **Release APK (`app-release.apk`):** Sideloadable production build optimized with R8/ProGuard.
- **AAB (`app-release.aab`):** Google Play Console production distribution with dynamic feature delivery and architecture splits.

```bash
# Build Android debug APK
flutter build apk --debug --android-skip-build-dependency-validation

# Sideload to active Android device or emulator
adb -s emulator-5554 install -r build/app/outputs/flutter-apk/app-debug.apk
```
