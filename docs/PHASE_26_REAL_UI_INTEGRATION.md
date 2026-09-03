# Phase 26: Real UI Integration & Mock-Data Elimination

## Objective

Connect every Flutter UI screen to the authentic local SQLite database, domain services, and live backend APIs. All hardcoded dashboard values, fake task states, simulated XP, placeholder completion flows, and mock vision providers are permanently eliminated from production runtime.

```
REAL DATABASE / LOCAL STATE
          ↓
   Repository Layer
          ↓
    Domain Services
          ↓
     API / Offline
          ↓
  Flutter State Layer
          ↓
     UI Screens
          ↓
   REAL USER ACTION
          ↓
 REAL PERSISTED STATE
```

---

## Screen Audits & Real Persistence Wiring

### 1. Home Dashboard (`HomePage` & `HomeController`)
- **Action Header**: Shows genuine next pending discipline from `LocalDatabase`.
- **Today's Score**: Real calculation based on completed vs scheduled tasks for the current calendar date (`0 / 8 Tasks Complete`).
- **Upcoming Disciplines**: Ordered queue of active tasks with verification type icons (`VIDEO`, `PHOTO`).
- **Quick Actions**: Real database logging for water (`logWater(250)`), meals, and naps.

### 2. Discipline Tasks (`TasksPage` & `TaskController`)
- Dynamic filtering by **ALL**, **ACTIVE**, **SCHEDULED**, and **COMPLETED**.
- Real XP awards (`+30 XP`) pulled from task definition.
- Task execution triggers authentic `TaskLifecycleService.startTaskAttempt(...)`.

### 3. Health & Wellness (`HealthPage` & `HealthController`)
- **Hydration Tracker**: Tracks exact milliliter volume with dynamic goal percentage calculation (`250 ml / 2000 ml = 12%`).
- **Preserved Presets**: `+250 ml`, `+500 ml`, `+750 ml` write atomic entries to `water_entries`.
- **Meal Nourishment**: Breakfast, Lunch, Snacks, Dinner status backed by `meal_entries`.
- **Rest & Naps**: `startNap()` / `stopNap()` records timestamps into `nap_entries`.

### 4. Discipline Progress (`ProgressPage` & `ProgressController`)
- **7-Day Trend**: Queries completed missions over rolling 7-day window.
- **Streak Ledger**: Calculates consecutive disciplined days without artificial increments.
- **Grace Token Balance**: Displays true unspent grace tokens from the user account.

### 5. Stoic Daily Journal (`JournalPage`)
- Full CRUD lifecycle for daily reflections: write, edit, delete.
- State persists across process death via local SQLite serialization.

### 6. Mission Execution & Proof Capture (`MissionExecutionScreen`)
- Complete elimination of mock completion buttons.
- Requires genuine camera capture (`PhotoCaptureScreen` / `VideoCaptureScreen`) or verifiable sensor telemetry.
- Uploads binary payload to backend verification pipeline or queues for offline sync.
