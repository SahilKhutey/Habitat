# Privacy Policy for Habitat

**Effective Date:** August 31, 2026  
**Last Updated:** August 31, 2026  
**Application:** Habitat (Android, iOS, Web, and Backend Services)  

---

## 1. Overview & Core Privacy Principles

Habitat ("we", "our", or "the Platform") is a discipline and personal transformation platform designed to empower users to build unbreakable habits through physical accountability.

We believe that personal accountability must never come at the expense of personal privacy. Habitat is engineered from the ground up on three fundamental privacy invariants:

1. **Local-First & Offline-Centric:** Your habits, alarms, routine schedules, and performance histories are stored locally on your device. Habitat functions 100% offline without requiring continuous cloud communication.
2. **Zero Biometric Raw Video Harvesting:** When you perform a physical mission (e.g., push-ups, morning routine verification), real-time computer vision (MoveNet Lightning) processes video frames **locally on your device** or through transient encrypted verification sessions. Raw video feeds and photographic face/body images are **never sold, monetized, or retained** for surveillance.
3. **Cryptographic Proof Integrity:** Habit completions are verified using deterministic mathematical trajectory analysis and cryptographic SHA-256 evidence hashing. We store only cryptographic commitments and score summaries, not your private living space imagery.

---

## 2. Information We Process

### A. Information Stored Locally on Your Device
* **Habits and Routine Schedules:** Task titles, alarm times, recurrence days, and difficulty tiers.
* **Discipline & Gamification Metrics:** Streak counts, XP, level progression, and badges earned.
* **Encrypted Local Database:** Local SQLite / durable key-value store containing your operational state.
* **Alarm Configuration:** Exact alarm schedules, volume escalation preferences, and Doze exemption status.

### B. Verification & Proof Data
* **Camera & Video Streams:** Transient camera streams captured during active mission execution are passed to our on-device/local MoveNet computer vision engine.
* **Keypoint Trajectory Coordinates:** Mathematical coordinates representing 17 anatomical landmarks (e.g., shoulder, elbow, wrist positions) normalized to $[0, 1]$ bounding boxes.
* **Evidence Hashes:** SHA-256 digests of video frames and nonce challenges generated to prove physical liveness and prevent replay attacks.
* **Liveness & Anti-Cheat Metadata:** Session challenge nonces, frame-rate variance, and monotonicity timestamps.

### C. Technical & Diagnostic Information
* **Device Telemetry (Opt-in):** Device manufacturer, OS version, and crash stack traces with all personal identifiable information (PII) stripped.
* **Network Logs (Cloud Sync Users Only):** IP address and timestamp when syncing progress with the optional Habitat cloud backend.

---

## 3. Hardware & OS Permissions Rationale

Habitat requests specific platform permissions exclusively to guarantee the reliability of the wake-up alarm and mission verification systems:

### Android Permissions
| Permission | Technical Requirement | User Benefit |
|:---|:---|:---|
| `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` | Invokes `AlarmManager.setExactAndAllowWhileIdle()` | Ensures your wake-up alarm fires at the exact second configured, even when the device is in deep Doze mode. |
| `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` | Exemption from OEM aggressive process killers | Prevents device power managers from killing the alarm service while you sleep. |
| `USE_FULL_SCREEN_INTENT` | Displays `AlarmRingingScreen` over lock screen | Launches the tactical wake-up HUD directly when the alarm triggers without requiring manual unlocking. |
| `WAKE_LOCK` | CPU wake lock during active ringing | Keeps the processor active to execute siren audio and volume escalation ($70\% \rightarrow 85\% \rightarrow 100\%$). |
| `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | Foreground Service for alarm siren | Guarantees continuous high-priority audio playback that overrides silent mode. |
| `RECEIVE_BOOT_COMPLETED` | `BootReceiver` hook | Automatically restores your scheduled alarms if your device reboots or updates overnight. |
| `CAMERA` | Live mission capture | Allows you to record physical exercise or environment proofs to disarm alarms. |

### iOS Permissions
| Permission / Capability | Technical Requirement | User Benefit |
|:---|:---|:---|
| `NSCameraUsageDescription` | `AVCaptureSession` access | Captures live camera frames to verify physical mission completion. |
| `NSMicrophoneUsageDescription` | Audio capture during video proofs | Records ambient audio confirmation for supported mission types. |
| `UNAuthorizationOptionAlert / Sound` | User Notifications framework | Delivers the 6-step time-sensitive alarm escalation chain ($T+0..T+25\text{min}$). |
| `AVAudioSession (.playback)` | Audio session category override | Ensures siren audio rings even when the physical hardware mute switch is engaged. |

---

## 4. How We Use and Protect Data

* **No Data Selling:** We do not sell, rent, or trade your personal data, habit patterns, or biometric geometry to third parties, data brokers, or advertisers.
* **No Advertising Trackers:** The Habitat mobile app and web platform contain zero third-party advertising SDKs or tracking pixels.
* **End-to-End Cryptography:** Sync tokens and cloud backup payloads are encrypted in transit using TLS 1.3 and encrypted at rest using AES-256-GCM.
* **Automatic Proof Expiration:** Transient frame buffers and verification evidence artifacts are automatically purged after mathematical verification is finalized.

---

## 5. Apple App Store Privacy Nutrition Label

| Category | Data Type | Collected? | Linked to User? | Used for Tracking? |
|:---|:---|:---|:---|:---|
| **Contact Info** | Email / Name | Optional (Cloud Sync only) | Yes | No |
| **Health & Fitness** | Fitness / Habit Data | Locally Processed | No (Local-first) | No |
| **User Content** | Photos / Videos | Transient Only | No | No |
| **Identifiers** | Device ID | Optional (Crash logs) | No | No |
| **Usage Data** | Product Interaction | Optional Diagnostic | No | No |
| **Diagnostics** | Crash Data / Performance | Optional | No | No |

---

## 6. Google Play Data Safety Declaration

* **Data Collected:**
  * App activity (optional usage diagnostics, if enabled).
  * App info and performance (crash logs, diagnostics).
* **Data Shared:** None. Habitat does not share user data with third parties.
* **Security Practices:**
  * Data is encrypted in transit (TLS 1.3).
  * Users can request deletion of account and all associated cloud data at any time.
  * Local-first mode operates entirely offline without data collection.

---

## 7. User Rights & Data Control (GDPR & CCPA)

Under applicable data protection regulations (including GDPR and CCPA/CPRA), you have the right to:
1. **Access & Portability:** Export your entire habit history and event ledger in JSON format via the app settings.
2. **Erasure (Right to be Forgotten):** Clear all local databases immediately with a single tap in **Settings > Storage > Reset All Data**, or request cloud account deletion.
3. **Revoke Permissions:** Disable Camera, Microphone, or Notification permissions at any time through your OS settings (with graceful fallback to manual mission verification).

---

## 8. Contact Information

If you have questions, privacy inquiries, or data deletion requests, please contact our Data Protection Officer:

* **Email:** `privacy@habitat.app` / `support@habitat.app`  
* **Repository:** `https://github.com/SahilKhutey/Habitat`  
* **Organization:** Habitat Open Source Discipline Project  
