# Habitat Phase 12: Intelligent Discipline Adaptation & Personalization Engine Architecture

## 1. Executive Summary & Core Philosophy

Habitat Phase 12 transitions the platform from a structured routine scheduler into a proactive, **adaptive personal discipline operating system**.

$$\boxed{\textbf{Analytics} \longrightarrow \textbf{Recommendation} \longrightarrow \textbf{User Explanation} \longrightarrow \textbf{User Accepts} \longrightarrow \textbf{New Routine/Task Version}}$$

```
                       USER
                         │
                         ▼
                ┌────────────────┐
                │ Discipline App │
                └───────┬────────┘
                        │
          ┌─────────────┼──────────────┐
          ▼             ▼              ▼
       ROUTINES       MISSIONS       ALARMS
          │             │              │
          └─────────────┼──────────────┘
                        ▼
                   USER ACTION
                        │
                        ▼
                  PHOTO / VIDEO
                        │
                        ▼
                   VERIFICATION
                        │
                        ▼
                   GAMIFICATION
                        │
                        ▼
                  BEHAVIOR EVENTS
                        │
                        ▼
                ┌───────────────┐
                │   ANALYTICS   │
                └───────┬───────┘
                        ▼
                ┌───────────────┐
                │   BEHAVIOR    │
                │    ENGINE     │
                └───────┬───────┘
                        ▼
                ┌───────────────┐
                │  ADAPTATION   │
                │    ENGINE     │
                └───────┬───────┘
                        ▼
                ┌───────────────┐
                │ RECOMMENDATION│
                │    ENGINE     │
                └───────┬───────┘
                        ▼
                  USER APPROVAL
                        │
                        ▼
                 ROUTINE VERSION
                        │
                        ▼
                  FUTURE MISSIONS
```

---

## 2. Fundamental Axiom: Non-Coercive User Consent

> **Critical Architecture Rule**: Analytics and background engines must **NEVER** silently or automatically mutate a user's routines or tasks.
>
> The system formulates explainable, confidence-scored recommendations. Routine changes only take effect when the user explicitly clicks **Accept**.
>
> Accepting a recommendation creates a **new immutable version snapshot** (`v1` $\to$ `v2`). Historical missions remain untouched.

---

## 3. Key Engine Components

| Engine | Primary Responsibility |
| :--- | :--- |
| **`BehaviorEngine`** | Idempotent event ingestion and multi-signal task performance calculation (success rate, delay, duration, difficulty classification). |
| **`TimingEngine`** | 24-hour success distribution analysis with minimum observation thresholds ($\ge 5$) to identify optimal performance windows. |
| **`OverloadEngine`** | Quantitative Routine Load scoring ($0\text{--}100$) and overload risk detection for heavily burdened schedules. |
| **`RecoveryEngine`** | Temporary 3-day momentum recovery protocol preserving streak and gamification progress. |
| **`RecommendationEngine`** | Ranked candidate deduplication (max 3), explainable justification synthesis, and 7-day cooldown on declined proposals. |
| **`AnalyticsEngine`** | Sub-300ms consolidated discipline health overview and tactical insights. |
