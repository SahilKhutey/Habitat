# Google Play Store Submission Metadata — Habitat

**App Name:** Habitat: Habit & Alarm OS  
**Short Description (80 chars max):**  
Action-driven habits, exact wake-up alarms, physical mission proof & streaks. (77 chars)  
**Package Name:** `com.habitat.app`  
**Category:** Health & Fitness / Productivity  
**Content Rating:** Everyone (PEGI 3 / ESRB Everyone)  

---

## 1. Full Description (4,000 characters max)
```
Habitat is the definitive habit execution and personal transformation operating system.

Most habit trackers rely on passive checkboxes and wishful thinking. Habitat turns discipline into an active, verifiable commitment with physical mission verification, exact wake-up alarms, and RPG streak progression.

KEY FEATURES:

🔴 ACTION-DRIVEN WAKE-UP ALARMS
• Exact wake-up alarms engineered to break through sleep inertia.
• Progressive 5-minute escalation with volume ramping (70% → 85% → 100%) ensures you get out of bed.
• Full-screen wake-up HUD over lock screen.
• No snooze button: complete your committed physical mission to disarm the alarm.

📹 COMPUTER VISION MISSION PROOF
• Verify physical exercise (push-ups, morning stretches) using real-time on-device MoveNet pose estimation.
• Instant motion trajectory analysis ensures genuine physical movement.
• Zero biometric harvesting: all computer vision is processed privately on your device. Raw video is never stored or uploaded.

⚔️ RPG STREAKS, XP & DISCIPLINE RANKS
• Earn XP for every completed mission and morning alarm conquered.
• Level up from Novice to Discipline Master as your consistency builds.
• Milestone achievements, discipline tiers, and streak freeze protections.

🔒 100% LOCAL-FIRST & PRIVATE
• Full functionality offline without mandatory account creation or cloud dependencies.
• Zero third-party ads or surveillance trackers.
• Your habits, schedules, and proofs remain entirely on your device.

Start building the life you want to live with Habitat.
```

---

## 2. Google Play Declared Permissions & Policy Justifications

Google Play requires explicit declarations and functional justifications for high-priority Android permissions:

### 1. `SCHEDULE_EXACT_ALARM` & `USE_EXACT_ALARM`
* **Core Purpose:** Habitat is an alarm clock and mission scheduling application.
* **Justification Statement:** "Habitat requires exact alarm scheduling to wake users at their chosen wake-up time and trigger critical habit missions. Inexact alarms introduce delays of 10 to 30 minutes in Doze mode, which violates the core purpose of a morning alarm."

### 2. `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`
* **Core Purpose:** Alarm reliability during deep device idle states (Doze).
* **Justification Statement:** "To guarantee that the alarm foreground service and audio siren ring reliably overnight across all OEM battery optimization profiles."

### 3. `USE_FULL_SCREEN_INTENT`
* **Core Purpose:** Displaying the tactical wake-up screen when the device is locked.
* **Justification Statement:** "Habitat launches a full-screen alarm ringing screen when a scheduled wake-up alarm triggers while the device screen is locked, allowing the user to immediately view their morning mission and disarm the siren."

### 4. `FOREGROUND_SERVICE_MEDIA_PLAYBACK`
* **Core Purpose:** High-priority looping siren audio playback.
* **Justification Statement:** "Required to play continuous alarm audio through Android's USAGE_ALARM audio attributes and manage the wake-up alarm notification until the user completes their morning physical mission."

---

## 3. Data Safety Form Responses
* **Data collected:** None required for core offline usage.
* **Data shared:** None with third parties.
* **Data security:** Encryption in transit (HTTPS/TLS 1.3), Account Deletion URL provided (`https://habitat.app/account/delete`).
