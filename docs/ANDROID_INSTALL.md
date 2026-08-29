# Habitat Android Installation & Offline Testing Guide

## Prerequisites
- Android 7.0+ (API 24 or higher)
- Physical Android phone or emulator with ADB enabled

## Installation Steps
1. **Download APK:** Obtain `Habitat-MVP-1.0.0-android.apk` (or `Habitat-v1.0.0.apk`).
2. **Direct Installation via ADB:**
   ```bash
   adb install -r release/android/Habitat-MVP-1.0.0-android.apk
   ```
3. **Sideloading on Device:**
   - Transfer APK to device storage.
   - Open File Manager and tap the `.apk`.
   - Allow installation from unknown sources if prompted.

## Offline Validation Protocol
1. Turn **OFF** Wi-Fi and Mobile Data (enable Airplane Mode).
2. Open **Habitat** (zero cloud login required).
3. Create a local profile and schedule a task alarm 2 minutes ahead.
4. Lock phone $\to$ Alarm triggers $\to$ Record photo/video proof $\to$ Confirm completion and XP/streak advancement.
