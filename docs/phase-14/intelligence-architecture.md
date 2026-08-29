# Phase 14 — Personal Discipline Intelligence & Adaptive Coach Architecture

## 1. Core Principle & Architectural Law

$$\boxed{\textbf{AI Recommends} \longrightarrow \textbf{User Decides} \longrightarrow \textbf{Deterministic Systems Execute}}$$

The AI intelligence layer is strictly non-coercive. It never silently alters user alarms, routines, commitments, or verification rules. All mutable suggestions enter a `PENDING_APPROVAL` state requiring explicit user acceptance.

---

## 2. Product Architecture Flow

```
                         USER
                           │
                           ▼
                  MOBILE / WEB APP
                           │
            ┌──────────────┴──────────────┐
            │                             │
            ▼                             ▼
     DISCIPLINE SYSTEM              WELLNESS SYSTEM
            │                             │
            └──────────────┬──────────────┘
                           ▼
                     EVENT SYSTEM
                           │
                           ▼
                   BEHAVIOR ENGINE
                           │
                           ▼
                 PERSONAL PROFILE
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
       PATTERN ENGINE  GOAL ENGINE  CONTEXT ENGINE
             │             │             │
             └─────────────┼─────────────┘
                           ▼
                  INTELLIGENCE ENGINE
                           │
             ┌─────────────┼─────────────┐
             ▼             ▼             ▼
        RECOMMENDER     COACH AI      PLANNER
             │             │             │
             └─────────────┼─────────────┘
                           ▼
                  USER APPROVAL LAYER
                           │
                           ▼
                  DETERMINISTIC ENGINE
                           │
                           ▼
                  TASK / ALARM / ACTION
```
