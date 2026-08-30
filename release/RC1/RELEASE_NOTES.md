# Habitat v1.0.0-rc1 Release Notes

## Release Candidate Overview
Habitat is an offline-first, local-authoritative personal discipline platform that integrates native alarms, strict video/photo evidence verification, responsive UI across mobile/web/desktop, and a gamified habit loop.

### Key Pillars Validated in RC1
1. **Core Product Loop**:
   - Task $\to$ Native Exact Alarm $\to$ Full-Screen Siren $\to$ Single-Use Nonce Challenge $\to$ Proof Capture $\to$ MoveNet / Object Detection Verification $\to$ Attempt Disarm $\to$ XP Award $\to$ Dynamic Streak $\to$ Progress Graphs.
2. **Platform & Hardware Resiliency**:
   - Android Exact Alarm & `BootReceiver` restore across reboots.
   - iOS bounded notification chain & background resilience.
   - Web keyboard navigation, focus traversal, and responsive `NavigationRail`.
3. **Health & Progress**:
   - Hydration logging with milliliter aggregation and liter conversion.
   - 4-slot meal tracking (Breakfast, Lunch, Snacks, Dinner).
   - Nap duration tracking in minutes.
   - 7-day rolling window completion graphs.
4. **Security & Privacy Hardening**:
   - Dual-token session lifecycle (`ACTIVE`, `REVOKED`, `EXPIRED`).
   - Authoritative IDOR ownership checks.
   - Challenge anti-replay ledger preventing re-submission of verified footage.
   - Sanitized audit logging (no passwords, tokens, or GPS in logs).
5. **Quality Assurance & Verification**:
   - 67 test suites with 402 passing unit and integration tests.
   - Full fail-closed CI pipeline with SHA-256 artifact verification.

### Package & Asset Verification
- Android Release APK: `Habitat-v1.0.0-rc1.apk`
- Android App Bundle: `Habitat-v1.0.0-rc1.aab`
- Web Bundle: `Habitat-Web-v1.0.0-rc1.tar.gz`
- SHA-256 Checksums: `SHA256SUMS.txt`
