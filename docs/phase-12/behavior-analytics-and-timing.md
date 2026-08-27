# Behavior Analytics, Multi-Signal Scoring & Timing Optimization

## 1. Multi-Signal Behavior Score Formulation

Rather than calculating a simplistic $\frac{\text{Completed}}{\text{Total}}$ percentage, Habitat evaluates discipline health across 5 orthogonal vectors:

$$\text{Behavior Score} = 0.40 \cdot \text{Comp} + 0.25 \cdot \text{Cons} + 0.15 \cdot \text{Time} + 0.10 \cdot \text{Proof} + 0.10 \cdot \text{Stab}$$

* **$\text{Comp}$ (Completion Rate)**: $\frac{\text{Completed Missions}}{\text{Total Scheduled}} \times 100$.
* **$\text{Cons}$ (Consistency Rate)**: 14-day rolling daily execution stability.
* **$\text{Time}$ (Timeliness Score)**: Penalizes delay between trigger time and actual proof submission: $\max(0, 100 - \frac{\text{AvgDelaySeconds}}{6})$.
* **$\text{Proof}$ (Proof Reliability)**: $\max(0, 100 - \text{RejectionRate})$.
* **$\text{Stab}$ (Schedule Stability)**: Measures adherence without excessive manual snoozes or reschedules: $\max(0, 100 - \text{RescheduleCount} \times 10)$.

---

## 2. Timing Optimization & Anti-Overfitting Safeguard

The `TimingEngine` partitions historical performance across 24 hourly buckets ($00\text{--}23$).

### Minimum Data Threshold:
* **$\ge 5$ total observations** are required before any timing recommendation is generated.
* If observations $< 5$, the system explicitly declares:
  > *"Not enough behavioral data yet (minimum 5 observations needed)."*

---

## 3. Difficulty Classification

| Classification | Success Rate | Average Delay | Action Recommendation |
| :--- | :---: | :---: | :--- |
| **`TOO_EASY`** | $\ge 95\%$ | $< 60\text{s}$ | Recommend increasing challenge |
| **`EASY`** | $\ge 85\%$ | $< 120\text{s}$ | Candidate for difficulty bump |
| **`BALANCED`** | $65\%\text{--}84\%$ | $< 300\text{s}$ | Maintain current configuration |
| **`CHALLENGING`** | $40\%\text{--}64\%$ | Variable | High engagement; keep building momentum |
| **`TOO_HARD`** | $< 40\%$ | $> 600\text{s}$ | Recommend difficulty reduction or timing shift |
