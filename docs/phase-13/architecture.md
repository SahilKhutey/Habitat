# Phase 13 — Health, Exercise & Wellness Discipline Layer Architecture

## 1. Executive Summary & Core Principle

Phase 13 establishes the **Health, Exercise & Wellness Discipline Layer** within Habitat.

### Core Architectural Axiom:
> **Health & Wellness is a strictly separate domain from the core alarm and task execution engine.**
>
> Exercise does not directly modify alarms. Instead:
> $$\text{Exercise} \longrightarrow \text{Wellness Event} \longrightarrow \text{Analytics} \longrightarrow \text{Recommendation} \longrightarrow \text{User Consent} \longrightarrow \text{Discipline Task}$$

---

## 2. Product Architecture

```
                    DISCIPLINE APP
                         │
          ┌──────────────┴──────────────┐
          │                             │
          ▼                             ▼
   DISCIPLINE DOMAIN             WELLNESS DOMAIN
          │                             │
          │                       ┌─────┼─────┐
          │                       │     │     │
          │                       ▼     ▼     ▼
          │                    Exercise Water Sleep
          │
          ▼
       Missions
          │
          ▼
       Alarms
          │
          ▼
       Proof
          │
          ▼
     Verification
          │
          └──────────────┬──────────────┘
                         ▼
                    GAMIFICATION
                         │
                         ▼
                     ANALYTICS
```

---

## 3. Discipline-to-Wellness Bridge

When a user completes a physical discipline mission (e.g. *15 Pushups* with video verification):
1. **Verification Engine** confirms proof validity.
2. **Mission Engine** marks mission as `COMPLETED`.
3. **Discipline-to-Wellness Bridge** creates a corresponding `ExerciseSession` (15 repetitions, 180s duration).
4. **Gamification Engine** awards XP and updates streaks.
5. **Wellness Analytics** updates weekly volume and movement metrics.
