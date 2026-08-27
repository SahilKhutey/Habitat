# ADR-008: Proof Verification Pipeline & Anti-Cheat Heuristics

## Status
Accepted (2026-08-27)

## Context
A discipline app that allows easy cheating (e.g. snapping a pitch-black photo from under the blanket or uploading yesterday's photo from the camera gallery) immediately fails its core psychological commitment contract.

## Decision
Implement a multi-tiered verification pipeline:
1. **Tier 1 (V1 Heuristic & Anti-Cheat)**:
   * Reject photos/videos from system gallery picker (live camera sensor stream only).
   * Verify hardware capture timestamps (must be $< 3\text{ minutes}$ old).
   * Measure ambient lux illumination (reject photos $< 30\text{ lux}$).
   * Measure accelerometer motion vector during exercise tasks.
2. **Tier 2 (V2 Smart CV & Edge Validation)**:
   * On-device object detection (MobileNet / YOLO) confirming presence of beds, glasses, sinks, or books.
3. **Tier 3 (V3 Action & Pose Recognition)**:
   * MediaPipe / PyTorch cloud worker counting repetitions for push-ups and squats.

## Consequences
* **Positive**: Enforces genuine physical action; prevents lazy dismissal tricks; validates the core behavioral habit loop.
* **Tradeoff**: Low-light rooms require turning on lights or stepping into sunlight before proof passes.
