# Scheduling & Rolling Horizon Recurrence Engine

## 1. Rolling Horizon Mission Generation

To prevent massive database bloat and stale future records, Habitat uses a **Rolling Horizon (7–14 Days)** scheduling strategy:

* The `SchedulingEngine` evaluates recurrence rules only for the upcoming 7–14 days.
* As days progress, background workers extend the rolling horizon automatically.

---

## 2. Recurrence Modes

* **`ONCE`**: Single calendar event.
* **`DAILY`**: Every calendar day in user timezone.
* **`WEEKDAYS`**: Monday through Friday (Days 1–5).
* **`WEEKENDS`**: Saturday and Sunday (Days 6–7).
* **`CUSTOM`**: Explicit array of days (e.g. `[1, 3, 5]` for Mon/Wed/Fri).

---

## 3. Strict Idempotency & Conflict Suppression

Every generated mission instance is assigned a deterministic idempotency key:

$$\text{Idempotency Key} = \text{ruleId} : \text{YYYY-MM-DD} : \text{taskTemplateId}$$

Running `SchedulingEngine.generateMissions()` multiple times will detect existing idempotency keys and generate **exactly 0 duplicate missions**.
