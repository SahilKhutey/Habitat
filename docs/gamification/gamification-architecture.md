# Habitat Phase 10: Gamification, Discipline Progress & Engagement Engine

## 1. Executive Summary & Three Truths Separation

A sustainable discipline engine never confuses activity volume with genuine behavioural transformation. Habitat establishes a rigorous, decoupled boundary between three distinct systems of truth:

$$\begin{aligned}
\textbf{Verification Truth} &\quad\longrightarrow\quad \text{"Did the user actually execute the required action?" (CV / Pose / Sensor)} \\
\textbf{Mission Truth} &\quad\longrightarrow\quad \text{"Was the mission completed on schedule?" (Authoritative State Machine)} \\
\textbf{Discipline Truth} &\quad\longrightarrow\quad \text{"How consistently is the user following through over time?" (Economics / Score / Streaks)}
\end{aligned}$$

```
                ALARM TRIGGERED
                      │
                      ▼
               MISSION ACTIVE
                      │
                      ▼
               CAPTURE PROOF
                      │
                      ▼
            ┌───────────────────┐
            │VERIFICATION ENGINE│
            └─────────┬─────────┘
                      │ ACCEPT
                      ▼
            ┌───────────────────┐
            │  MISSION COMPLETE │
            └─────────┬─────────┘
                      │ Domain Event: MissionCompletedEvent
                      ▼
          ┌───────────────────────┐
          │     REWARD ENGINE     │
          └───────────┬───────────┘
                      │
        ┌─────────────┼─────────────┬─────────────┐
        ▼             ▼             ▼             ▼
    XP ENGINE   STREAK ENGINE  SCORE ENGINE  ACHIEVEMENT
   (Immutable     (Timezone      (Weighted     (Declarative
     Ledger)      + Grace)        0-100)        Unlocks)
        │             │             │             │
        └─────────────┼─────────────┴─────────────┘
                      ▼
            UNIFIED USER PROFILE
```

---

## 2. Event-Driven Architectural Separation

The Alarm and Mission systems never directly mutate XP or awards. When a mission is verified:
1. `MissionStateMachine` transitions to `COMPLETED`.
2. Emits `MissionCompletedEvent`.
3. `GamificationService` orchestrates:
   * **`XpEngine`**: Writes immutable append-only ledger transaction with idempotency key `MISSION_COMPLETED:{missionId}`.
   * **`LevelEngine`**: Updates total XP and detects `LEVEL_UP` milestones.
   * **`StreakEngine`**: Evaluates local timezone date qualification and Grace Vault token accrual (1 token per 14 days, max 3).
   * **`ScoreEngine`**: Computes rolling 30-day slow-moving discipline score and records daily summary statistics.
   * **`AchievementEngine`**: Evaluates declarative requirements and unlocks badges idempotently.

---

## 3. Motivation Over Manipulation UX Philosophy

Habitat deliberately avoids fear-based, punitive notifications:
* **Avoid**: *"YOU FAILED! YOUR STREAK IS DEAD! DO IT NOW!"*
* **Deliver**: *"Missed this one. You still have today. Let's get the next one."*

The application fosters **agency, momentum, and identity** rather than anxiety, guilt, or dark patterns.
