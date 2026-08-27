# Habitat Phase 11: Personal Discipline Planning & Routine Engine Architecture

## 1. Executive Summary & Core Paradigm Shift

With Phase 11, Habitat transitions from a reactive task-alarm clock into a proactive **Personal Discipline Operating System**.

$$\boxed{\textbf{Task Template} \longrightarrow \textbf{Schedule Rule} \longrightarrow \textbf{Routine Version} \longrightarrow \textbf{Mission Instance} \longrightarrow \textbf{Alarm Mesh Instance}}$$

```
                      USER
                       │
                       ▼
              DISCIPLINE PROFILE
                       │
                       ▼
                 ROUTINE PLAN
          ┌────────────┼────────────┐
          ▼            ▼            ▼
       MORNING      EXERCISE     EVENING
       ROUTINE      ROUTINE      ROUTINE
          │            │            │
          └────────────┼────────────┘
                       │
                       ▼
               SCHEDULING ENGINE
          (Rolling Horizon: 7-14 Days)
                       │
                       ▼
               MISSION INSTANCES
                       │
                       ▼
                 ALARMS & MESH
```

---

## 2. Fundamental Distinctions: Templates vs Schedules vs Missions

| Entity | Role | Example |
| :--- | :--- | :--- |
| **`TaskTemplate`** | Blueprint defining name, category, difficulty, proof requirement, and base reward. | *"10 Push-Ups"* (Physical, Video Proof, 30 XP) |
| **`ScheduleRule`** | Recurrence logic specifying when and in what timezone the task or routine runs. | *"Every Weekday at 07:00 AM (Asia/Kolkata)"* |
| **`Routine`** | Group of sequenced task items executed together as a unified discipline protocol. | *"Morning Spartan Protocol"* (Wake Photo $\to$ Hydration $\to$ Pushups) |
| **`RoutineVersion`** | Immutable configuration snapshot preserving historical mission integrity when routines are edited. | *Version 1 vs Version 2* |
| **`Mission`** | Concrete instance for a specific calendar date and time. | *"Thursday, Aug 27 at 07:00 AM"* |

---

## 3. Routine Lifecycle State Machine

$$\boxed{\textbf{DRAFT} \longrightarrow \textbf{ACTIVE} \rightleftharpoons \textbf{PAUSED} \longrightarrow \textbf{ARCHIVED}}$$

* **`DRAFT`**: Routine is being configured; no missions are scheduled.
* **`ACTIVE`**: Actively generates missions according to recurrence rules.
* **`PAUSED`**: Temporarily suspends future mission generation until `pause_until` date (e.g. during travel/recovery). Past missions remain untouched.
* **`ARCHIVED`**: Soft-deleted from planner view while preserving full historical audit logs, XP, and streak records.
