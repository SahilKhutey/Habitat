# iOS Build & Release Engineering

## Application Identity
- **Bundle Identifier:** `com.habitat.discipline`
- **App Name:** `Discipline`
- **Minimum iOS Version:** iOS 16.0+

## Architecture & Alarm Adapter
iOS does not support an arbitrary persistent background alarm loop identical to Android.
Instead, the architecture utilizes a decoupled **Notification & Alarm Adapter**:
- `UNUserNotificationCenter` with critical alert audio where authorized.
- Scheduled local notifications repeating every 5 minutes during active mission windows.
- Background app refresh reconciliation on connection recovery.

## Build Artifacts
- **Archive / `.ipa`:** Produced via `xcodebuild` or Xcode organizer for TestFlight external beta and App Store production distribution.

```bash
# Build iOS Archive
./scripts/build-ios.sh
```
