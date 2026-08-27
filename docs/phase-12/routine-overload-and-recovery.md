# Routine Overload Detection & Recovery Protocols

## 1. Routine Load Score Calculation

$$\text{Load Score} = (\text{TaskCount} \times 5) + \left\lfloor\frac{\text{EstimatedMinutes}}{2}\right\rfloor + (\text{AverageDifficulty} \times 5)$$

| Score Range | Load Level | Operational Assessment |
| :---: | :--- | :--- |
| **$0\text{--}30$** | `LIGHT` | Low mental friction; highly sustainable. |
| **$31\text{--}60$** | `MODERATE` | Balanced routine; optimal daily volume. |
| **$61\text{--}80$** | `HIGH` | Demanding volume; sensitive to life disruption. |
| **$81\text{--}100$** | `VERY_HIGH` | Overload risk; candidate for routine simplification. |

---

## 2. 3-Day Momentum Recovery Protocol

When 7-day completion falls below $45\%$, the system offers **Recovery Mode**:
* Temporarily simplifies routines to essential baseline habits (e.g. hydration, sunlight, brushing).
* Converts secondary tasks to optional.
* **Preserves streaks and XP economy** during recovery so the user isn't penalized while rebuilding momentum.
