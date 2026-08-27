# Habitat Phase 9: Verification & Truth Architecture

## 1. Executive Summary & Core Principle

$$\textbf{Capture} \neq \textbf{Proof} \neq \textbf{Verification} \neq \textbf{Completion}$$

In Habitat, submitting evidence does not automatically complete a mission. The **Verification & Truth Engine** acts as the authoritative intelligence boundary that determines whether captured photos, videos, or sensor payloads genuinely satisfy the task's discipline requirements.

```
                    ALARM FIRED
                         │
                         ▼
                   MISSION ACTIVE
                         │
                         ▼
                  CAPTURE PROOF
                         │
                         ▼
                  UPLOAD TO S3
                         │
                         ▼
                 PROOF REGISTERED
                         │
                         ▼
             ┌────────────────────────┐
             │   VERIFICATION QUEUE   │
             └───────────┬────────────┘
                         │
                         ▼
             ┌────────────────────────┐
             │  VERIFICATION WORKER   │
             └───────────┬────────────┘
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
     PHOTO VISION    VIDEO POSE      FUTURE
      (Objects &      (Movement &    (Wearables)
        Scene)          Reps)
          │              │
          └──────┬───────┘
                 ▼
          CONFIDENCE ENGINE (0.0 to 1.0)
                 │
                 ▼
          DECISION ENGINE
          ┌──────┼──────┐
          ▼      ▼      ▼
        ACCEPT REVIEW REJECT
          │      │      │
          ▼      ▼      ▼
      COMPLETE FALLBACK RETRY (+5 MIN)
```

---

## 2. Core Architectural Separation: The AI Never Owns Discipline State

The AI model or Computer Vision pipeline outputs **raw evidence checks and confidence scores**. It does **not** directly complete missions or stop sirens.

$$\boxed{\textbf{Vision} \longrightarrow \textbf{Evidence} \longrightarrow \textbf{Verification Checks} \longrightarrow \textbf{Decision Engine} \longrightarrow \textbf{Mission Engine} \longrightarrow \textbf{Discipline State / Alarms}}$$

1. **Vision / Pose Layer**: Detects objects, poses, keypoints, scene classifiers.
2. **Task Verifier Adapter**: Matches vision outputs against task rules (e.g. `10 push-ups`, `bed made`).
3. **Confidence Engine**: Normalizes multi-signal weighted scores into a $0.00 \to 1.00$ rating.
4. **Decision Engine**: Maps confidence to `ACCEPT`, `REVIEW`, or `REJECT`.
5. **Mission Engine**: The sole authoritative state machine that marks missions `COMPLETED` or resets the 5-minute escalation retry loop.

---

## 3. Tri-State Decision Model

| Decision | Criteria | Action Taken |
| :--- | :--- | :--- |
| **`ACCEPT`** | $\text{Confidence} \ge 0.80$ AND all critical checks passed | Mission transitions to `COMPLETED`, base XP + bonuses awarded, alarm disarmed across mesh |
| **`REVIEW`** | $0.50 < \text{Confidence} < 0.80$ OR ambiguous signals | Fallback to controlled review or guided user retry; avoids false rejections |
| **`REJECT`** | $\text{Confidence} \le 0.50$ OR critical failure reason | Mission remains `ACTIVE`, actionable advice displayed, 5-minute retry cycle continues |

---

## 4. Verification Audit Trail & Explainability

Every evaluation records a complete immutable verification report in the `verification_reports` and `verifications` tables:
* `id`: Unique verification UUID.
* `verifier`: Verifier strategy identifier (`PushupVideoVerifier`, `OutdoorPhotoVerifier`, `BrushingPhotoVerifier`).
* `verifier_version`: Exact model version (e.g. `pushup-v1.0`).
* `confidence`: Continuous confidence score.
* `checks`: Array of named check items (`PERSON_PRESENT`, `OUTDOOR_SCENE`, `REPETITION_COUNT`, `IMAGE_QUALITY`).
* `reasons`: Array of human-explainable rejection reason codes (`TOO_DARK`, `INSUFFICIENT_REPETITIONS`, `LENS_COVERED`).
