# Health & Wellness Domain Model & Units

## 1. Exercise Subsystem

### Categories:
* `STRENGTH`, `CARDIO`, `MOBILITY`, `FLEXIBILITY`, `BALANCE`, `SPORT`, `WALKING`, `RUNNING`, `OTHER`

### Units:
* `REPETITIONS`, `SECONDS`, `MINUTES`, `METERS`, `KILOMETERS`, `CALORIES`, `SETS`, `DISTANCE`

### Sources:
* `APP`, `APPLE_HEALTH`, `HEALTH_CONNECT`, `MANUAL`, `IMPORTED`

---

## 2. Hydration Subsystem
* Internal storage unit: **Milliliters ($\text{ml}$)**.
* UI displays: **Liters ($\text{L}$)** (e.g. $1.8\text{ / }2.5\text{ L}$).
* Fast quick-add actions: `[+250 ml]`, `[+500 ml]`, `[+750 ml]`.

---

## 3. Sleep Subsystem
* Tracks: `startedAt`, `endedAt`, `durationSec`, `source`, `quality`, `notes`.
* Evaluates 7-day average sleep duration and target adherence without claiming medical diagnosis.
