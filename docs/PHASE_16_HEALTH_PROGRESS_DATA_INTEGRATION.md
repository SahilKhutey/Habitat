# Habitat Phase 16 — Health + Progress Full Data Integration

## Overview
Phase 16 transitions the Health and Progress sections from placeholder demo values to persistent, local-first data architecture unified with Tasks, Missions, XP, and Streaks:
```
                    HABITAT DATA CORE
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
      TASKS             HEALTH           MISSIONS
        │                 │                 │
        │          ┌──────┼──────┐          │
        │          │      │      │          │
        │        WATER   MEAL   NAP         │
        │                 │                 │
        └─────────────────┼─────────────────┘
                          │
                          ▼
                   LOCAL DATABASE
                          │
                          ▼
                  EVENT / LOG DATA
                          │
              ┌───────────┼───────────┐
              ▼           ▼           ▼
           Progress      XP        Streak
```

## Component Architecture
1. **`LocalHealthLog` Data Model**:
   - Stores `id`, `type` (`WATER`, `MEAL`, `NAP`, `EXERCISE`), `recordedAt`, `amount`, `unit`, `mealType`, `durationMinutes`, and `note`.
2. **`HealthProgressService`**:
   - `addWaterMl(int ml)`
   - `logMeal(String mealType)`
   - `logNap(Duration duration)`
   - Aggregations: `todayWaterLiters`, `todayMealCount`, `todayNapMinutes`, `dailyCompletions`, `dailyWater`.
3. **7-Day Progress & Visual Aggregation**:
   - Real-time 7-day completion count from `LocalTaskAttempt` where status == `COMPLETED`.
   - Dynamic streak engine (`currentStreak`, `longestStreak`).
   - Integrated XP ledger (`LocalXPEvent`).
4. **Offline-First Persistence**:
   - All events persist locally without network dependency.
