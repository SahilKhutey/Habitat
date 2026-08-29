# Habitat — Standard Android APK Build & Validation Guide

## 1. Prerequisites & Environment Check
```bash
# Verify Flutter SDK and Android toolchain
flutter --version
flutter doctor -v

# Accept Android licenses if needed
flutter doctor --android-licenses
```

## 2. Automated Build Commands
From the project root:
```bash
# Unix / macOS:
./scripts/build-android.sh

# Windows PowerShell:
powershell -ExecutionPolicy Bypass -File scripts/build-android.ps1
```

Or manually via Flutter CLI:
```bash
cd apps/mobile
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release
flutter build appbundle --release

# Package into release directory
mkdir -p ../../release/android
cp build/app/outputs/flutter-apk/app-release.apk ../../release/android/Habitat-1.0.0-android.apk
```

## 3. Physical Device Installation & ADB Commands
```bash
# Check connected devices
adb devices

# Clean installation
adb uninstall com.habitat.app
adb install release/android/Habitat-1.0.0-android.apk

# Verify installed package
adb shell pm list packages | grep habitat
```

## 4. Android QA & Background Alarm Matrix
Ensure the following conditions are validated on physical hardware:
- [x] **App Foreground:** Reminder triggers and opens camera proof view.
- [x] **App Backgrounded:** Alarm triggers with high-priority full-screen intent.
- [x] **Device Locked / Screen Off:** Screen turns on and sound/vibration escalates.
- [x] **5-Minute Non-Lethal Repeat:** If dismissed/ignored, alarm re-triggers after 5 minutes until proof is verified.
- [x] **Reboot Persistence:** `RECEIVE_BOOT_COMPLETED` re-schedules exact alarms via `AlarmReceiver`.
- [x] **Offline Operation:** Wi-Fi and Cellular disabled; all tasks, alarms, proofs, and XP function locally.
