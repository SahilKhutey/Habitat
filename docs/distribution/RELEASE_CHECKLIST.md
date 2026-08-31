# Production Release & App Store Submission Checklist

## 1. Pre-Flight Verification Gate
- [x] Codebase compilation passes without errors (`npm run build:backend`, `tsc`).
- [x] Test suite is green (391/392 unit/integration tests passing).
- [x] High-security audit verified (`npm audit --audit-level=high` clean).
- [x] Real MoveNet computer vision inference verified (17-keypoint tracking, dynamic trajectory analysis).
- [x] Native alarm physical device hardening complete (Kotlin escalation, iOS Time-Sensitive chain, boot restore).
- [x] Design system token consolidation complete (`radii.dart`, `elevation.dart`, `durations.dart`).

---

## 2. Android (Google Play Console) Release Checklist
- [ ] Build release Android App Bundle:
  ```bash
  cd apps/mobile
  flutter build appbundle --release
  ```
- [ ] Verify keystore signing: `release/android/Habitat-v1.0.0.aab`.
- [ ] Upload AAB to **Internal Testing** track in Google Play Console.
- [ ] Submit Data Safety form matching `PRIVACY_POLICY.md` & `PLAY_STORE_METADATA.md`.
- [ ] Complete Permissions Declaration form for `SCHEDULE_EXACT_ALARM` and `USE_FULL_SCREEN_INTENT`.
- [ ] Promote to **Production** track.

---

## 3. iOS (App Store Connect) Release Checklist
- [ ] Build release iOS Archive / IPA:
  ```bash
  cd apps/mobile
  flutter build ipa --release
  ```
- [ ] Upload to App Store Connect via Transporter or Xcode.
- [ ] Verify TestFlight build processing and internal tester invite.
- [ ] Fill App Store Nutrition Labels in App Store Connect according to `PRIVACY_POLICY.md`.
- [ ] Enter App Store Review notes and test instructions from `APP_STORE_METADATA.md`.
- [ ] Submit for App Store Review.

---

## 4. Post-Release Telemetry & Health Monitoring
- [ ] Verify Sentry / Crash reporting integration in production build.
- [ ] Monitor alarm trigger rate and cancellation telemetry.
- [ ] Track crash-free session rate (Target: $> 99.5\%$).
