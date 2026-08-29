# Habitat v1.0.0 — Known Platform Behaviors & Diagnostics

## iOS Notification & Background Constraints
- iOS handles background alarms via scheduled local notifications (`UNUserNotificationCenter`).
- Critical alert sounds require explicit device permission during onboarding.

## Android Battery Optimization
- Certain aggressive OEM task killers (e.g. MIUI, EMUI) may defer background alarms if battery optimization is active.
- Habitat requests standard `SCHEDULE_EXACT_ALARM` permissions and guides the user to disable battery restrictions if deferred triggers are detected.

## Web Browser Tab Throttling
- Background execution in desktop/mobile web browsers is throttled when tabs are backgrounded.
- Mobile (Android / iOS) serves as the authoritative alarm runtime; Web serves as the local dashboard and PWA task manager.
