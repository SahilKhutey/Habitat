# Push-Up & Exercise Video Verification Specification

## 1. Overview
Push-up verification converts raw user video into an objective repetition counter using keypoint pose tracking, landmark smoothing, and a discrete movement state machine.

---

## 2. Push-Up State Machine

$$\boxed{\textbf{UNKNOWN} \longrightarrow \textbf{TOP} \longrightarrow \textbf{DESCENDING} \longrightarrow \textbf{BOTTOM} \longrightarrow \textbf{ASCENDING} \longrightarrow \textbf{TOP} \ (\text{Count} + 1)}$$

```
          [ TOP ] (Elbow > 155°, Body > 140°)
            │
            ▼
     [ DESCENDING ] (Elbow flexion 155° → 90°)
            │
            ▼
        [ BOTTOM ] (Elbow <= 90°, Chest to Deck)
            │
            ▼
      [ ASCENDING ] (Elbow extension 90° → 155°)
            │
            ▼
       [ TOP ] ───► Repetition Verified (+1 Rep)
```

---

## 3. Joint Angles & Geometrical Constraints
* **Elbow Angle**:
  * Top Lockout: $\ge 155^\circ$
  * Bottom Descent: $\le 90^\circ$
* **Body Alignment**:
  * Shoulder $\to$ Hip $\to$ Ankle angle must exceed $130^\circ$ to reject sagging hips or pike positions.
* **False Repetition Protection**:
  * If the user descends from `TOP` but reverses before reaching `BOTTOM` (elbow $\le 90^\circ$), the rep is marked `SHALLOW` and discarded.

---

## 4. Video Sampling & Temporal Smoothing
1. **Frame Extraction**: Sampled at 15 FPS to optimize CPU/GPU throughput.
2. **Exponential Moving Average Filter**: Smooths landmark jitter across frames.
3. **Repetition Minimum**: User must complete $\ge 10$ valid reps (or task-specified `minRepetitions`).
