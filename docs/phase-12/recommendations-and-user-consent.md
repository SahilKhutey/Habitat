# Personalized Recommendations & User Consent Protocol

## 1. Recommendation Lifecycle & States

$$\boxed{\textbf{PENDING} \longrightarrow \begin{cases} \textbf{ACCEPTED} & \to \text{Creates New Version Snapshot} \\ \textbf{DECLINED} & \to \text{Enforces 7-Day Cooldown} \\ \textbf{DISMISSED} & \to \text{Hidden From Active View} \\ \textbf{EXPIRED} & \to \text{Archived After 14 Days} \end{cases}}$$

---

## 2. Top-3 Ranking Strategy

To prevent decision fatigue and advice overload, the `RecommendationEngine` ranks all candidates and displays **at most 3 actionable recommendations** at any time:

$$\text{Ranking Score} = \text{Priority Weight} + \text{Confidence} \times 10$$

| Priority | Base Weight |
| :--- | :---: |
| **`URGENT`** | 40 |
| **`HIGH`** | 30 |
| **`MEDIUM`** | 20 |
| **`LOW`** | 10 |

---

## 3. Cooldown & Respecting User Intent

If a user declines a recommendation (e.g. *"Keep pushups at 10 reps"*), the engine records `status = 'DECLINED'` and **suppresses that recommendation type for 7 days**, preventing annoying repetitive prompts.
