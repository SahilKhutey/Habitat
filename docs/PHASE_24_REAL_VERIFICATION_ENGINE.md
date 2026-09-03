# Phase 24: Real Verification Engine Pipeline

## Overview

Phase 24 establishes the production-grade proof verification engine for Habitat, replacing all simulated, mock, or placeholder evaluation logic with an empirical ML and biomechanical pipeline.

```
Real Media Proof (MP4/JPEG)
            ↓
     ProofValidator
 (MIME, Duration, Checksum, Nonce)
            ↓
     FrameExtractor
 (FFmpeg, 10 FPS, <= 30s cap)
            ↓
     MoveNet Lightning
 (17 Pose Keypoints, 192x192)
            ↓
      MotionAnalyzer
 (Optical Flow & Inter-frame delta)
            ↓
     LivenessAnalyzer
 (Temporal variance, Luminance delta)
            ↓
    Biomechanical Evaluator
 (Push-up elbow angle < 90°, Rep FSM)
            ↓
     Decision Engine
 ┌──────────┼──────────┐
 ▼          ▼          ▼
ACCEPT    REVIEW     REJECT
```

---

## Verification Subsystems

### 1. Proof Validation (`ProofValidator`)
- **File Integrity**: Verifies non-zero byte size, valid media container, readable headers.
- **MIME Whitelist**: `video/mp4`, `image/jpeg`, `image/png`.
- **Duration Cap**: Proof videos bounded between 3.0s and 30.0s.
- **Session Nonce**: Proof must include unconsumed cryptographic session nonce to prevent replay attacks.
- **Fail-Closed Principle**: Any parsing failure immediately yields `REJECT`.

### 2. Frame Extraction (`FFmpegFrameExtractor`)
- Native extraction via bounded FFmpeg child process.
- Uniform 10 FPS temporal sampling.
- Output resolution standardized to 192x192 for MoveNet Lightning tensor feed.

### 3. MoveNet Lightning 17-Keypoint Tracker
- Ingests extracted frames into MoveNet Lightning model.
- Keypoints tracked: Nose, Left/Right Eye, Left/Right Ear, Left/Right Shoulder, Left/Right Elbow, Left/Right Wrist, Left/Right Hip, Left/Right Knee, Left/Right Ankle.
- Minimum keypoint confidence score: 0.35.

### 4. Biomechanical Evaluator (Push-up State Machine)
- Tri-state rep finite state machine (`TOP_PLANK` -> `INFLECTION_DOWN` -> `BOTTOM_PUSHUP` -> `ASCENT` -> `REP_COUNTED`).
- Valid rep criteria:
  - Elbow flexion angle $< 90^\circ$ at bottom.
  - Full extension $> 160^\circ$ at top.
  - Spine neutral alignment (hip-shoulder-ankle collinearity $\pm 15^\circ$).

### 5. Multi-Signal Liveness & Anti-Replay Engine
- **Temporal Motion Flow**: Rejects static photos held up to camera.
- **Luminance Fluctuation**: Evaluates natural lighting shifts against synthetic display refresh artifacts.
- **Cryptographic Nonce**: Single-use token tied to mission attempt timestamp.

### 6. Tri-State Decision Engine
- **ACCEPT**: Liveness passed, motion criteria fulfilled, rep count target reached ($\ge$ threshold).
- **REVIEW**: Marginal confidence score ($0.50 \le c < 0.75$) with genuine movement; queued for secondary audit.
- **REJECT**: Below confidence threshold, failed liveness, spoof detected, or incomplete reps.
