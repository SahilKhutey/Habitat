# Behavioral Modeling, Pattern Confidence & Failure Diagnostics

## 1. Personal Discipline Profile Versioning

The `DisciplineProfile` records behavioral preferences (preferred wake, sleep, peak focus windows, coaching style) with strict integer versioning:
$$\text{Profile } v_1 \longrightarrow \text{Profile } v_2 \longrightarrow \text{Profile } v_3$$
This ensures behavioral model evolution is completely traceable over time.

---

## 2. Pattern Classification & Confidence

| Classification | Confidence Range | Minimum Sample Size |
| :--- | :---: | :---: |
| **`OBSERVED`** | $\ge 0.80$ | $\ge 5$ observations |
| **`LIKELY`** | $0.65\text{--}0.79$ | $\ge 3$ observations |
| **`POSSIBLE`** | $0.50\text{--}0.64$ | $\ge 3$ observations |
| **`INSUFFICIENT_DATA`** | $< 0.50$ | $< 3$ observations |

---

## 3. Explainable Failure Diagnostics & Non-Punitive Recovery

When a user repeatedly misses a task:
1. **Friction Diagnostic**: Pinpoints friction without blaming the user (`TIME_CONFLICT`, `TASK_TOO_LONG`, `TOO_FREQUENT`).
2. **Single Recovery Action**: Proposes exactly 1 streamlined recovery session (e.g. 5-minute session at 18:00) rather than punishing the user with a stack of makeup tasks.
