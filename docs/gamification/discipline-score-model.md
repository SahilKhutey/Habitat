# Slow-Moving Discipline Score & Rolling Progress Model

## 1. Core Philosophy: XP vs. Discipline Score

* **XP**: Measures activity volume (how much work has the user accumulated?).
* **Discipline Score (0–100)**: Measures follow-through consistency (how reliably does the user execute commitments over time?).

A user cannot attain a high discipline score merely by completing hundreds of trivial tasks on a single day. The score is intentionally **slow-moving** and resistant to erratic spikes.

---

## 2. Mathematical Formulation

$$\boxed{\textbf{Discipline Score} = 0.40 \cdot \textbf{Completion} + 0.25 \cdot \textbf{Consistency} + 0.20 \cdot \textbf{Difficulty} + 0.15 \cdot \textbf{Streak}}$$

Where:
* $\textbf{Completion} = 100 \times \min\left(1.0, \frac{\text{Missions Completed}}{\text{Missions Assigned}}\right)$
* $\textbf{Consistency} = 100 \times \min\left(1.0, \frac{\text{Active Days with } \ge 1\text{ Completion}}{\text{Rolling Window Days (30)}}\right)$
* $\textbf{Difficulty} = 100 \times \min\left(1.0, \frac{\text{Average Task Difficulty}}{3.0}\right)$
* $\textbf{Streak} = 100 \times \min\left(1.0, \frac{\text{Current Streak}}{30}\right)$

---

## 3. Rolling Windows & Daily Precomputed Statistics

* **Rolling Windows**: Computed over 7-day, 30-day, and 90-day intervals.
* **Daily Statistics (`daily_discipline_stats`)**:
  * `tasks_assigned`, `tasks_completed`, `tasks_failed`, `xp_earned`, `discipline_score`.
  * Pre-aggregated daily records allow instantaneous ($< 50\text{ms}$) weekly and monthly analytics rendering without table-scanning raw mission logs.
