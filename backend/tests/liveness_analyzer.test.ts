// Unit & Security Tests: Temporal Liveness & Anti-Cheat Analyzer
import { describe, it, expect } from 'vitest';
import { LivenessAnalyzer } from '../src/modules/verification/engine/liveness-analyzer';
import { FramePoseRecord } from '../src/modules/verification/domain/evidence.types';

describe('LivenessAnalyzer', () => {
  // Helper to generate a realistic 10-pushup trajectory (300 frames at 30 FPS = 10s)
  function generateValidTrajectory(repCount: number = 10, fps: number = 30): FramePoseRecord[] {
    const totalFrames = repCount * 30; // 30 frames per rep = 1.0s per rep
    const records: FramePoseRecord[] = [];

    for (let i = 0; i < totalFrames; i++) {
      const timestampMs = Math.round(i * (1000 / fps));
      const repProgress = (i % 30) / 30; // 0 to 1
      // Sine curve: 165 at top (0 and 1), 80 at bottom (0.5)
      const elbowAngle = 165 - 85 * Math.sin(repProgress * Math.PI);
      const frameHash = `hash_${i}_${Math.floor(elbowAngle)}`;

      records.push({
        timestampMs,
        frameIndex: i,
        frameHash,
        keypoints: [],
        leftElbowAngleDeg: elbowAngle,
        rightElbowAngleDeg: elbowAngle,
        bodyAlignmentAngleDeg: 170
      });
    }

    return records;
  }

  it('validates a continuous, authentic human push-up session', () => {
    const trajectory = generateValidTrajectory(10);
    const result = LivenessAnalyzer.analyze(trajectory);

    expect(result.isLivenessValid).toBe(true);
    expect(result.livenessScore).toBeGreaterThanOrEqual(0.85);
    expect(result.frameUniquenessScore).toBeGreaterThanOrEqual(0.80);
    expect(result.temporalContinuityScore).toBeGreaterThanOrEqual(0.95);
    expect(result.flags.length).toBe(0);
    expect(result.rejectionReason).toBeNull();
  });

  it('flags and rejects a static photograph attack (repeated identical frame hash)', () => {
    // 30 frames with the exact same image hash and static angle
    const staticPhotoFrames: FramePoseRecord[] = Array.from({ length: 30 }, (_, i) => ({
      timestampMs: i * 33,
      frameIndex: i,
      frameHash: 'static_photo_sha256_constant_hash_value',
      keypoints: [],
      leftElbowAngleDeg: 160,
      rightElbowAngleDeg: 160,
      bodyAlignmentAngleDeg: 175
    }));

    const result = LivenessAnalyzer.analyze(staticPhotoFrames);

    expect(result.isLivenessValid).toBe(false);
    expect(result.flags).toContain('STATIC_PHOTO_OR_FROZEN_FRAME');
    expect(result.livenessScore).toBeLessThan(0.50);
    expect(result.rejectionReason).toContain('Static photograph');
  });

  it('flags temporal monotonicity violations (retro-dated or disordered frames)', () => {
    const trajectory = generateValidTrajectory(5);
    // Inject out-of-order timestamp anomalies
    trajectory[10].timestampMs = trajectory[15].timestampMs; // Duplicate
    trajectory[20].timestampMs = trajectory[5].timestampMs;  // Retro-dated jump

    const result = LivenessAnalyzer.analyze(trajectory);
    expect(result.flags).toContain('TEMPORAL_MONOTONICITY_VIOLATION');
    expect(result.temporalContinuityScore).toBeLessThan(0.90);
  });

  it('flags unnatural joint velocity teleports (frame splicing / deepfake artifacts)', () => {
    const trajectory = generateValidTrajectory(5);
    // Inject sudden 90-degree instantaneous jump in 33ms (> 2700 deg/sec)
    trajectory[15].leftElbowAngleDeg = 170;
    trajectory[16].leftElbowAngleDeg = 60;
    trajectory[15].rightElbowAngleDeg = 170;
    trajectory[16].rightElbowAngleDeg = 60;
    trajectory[25].leftElbowAngleDeg = 170;
    trajectory[26].leftElbowAngleDeg = 60;
    trajectory[35].leftElbowAngleDeg = 170;
    trajectory[36].leftElbowAngleDeg = 60;
    trajectory[45].leftElbowAngleDeg = 170;
    trajectory[46].leftElbowAngleDeg = 60;

    const result = LivenessAnalyzer.analyze(trajectory);
    expect(result.flags).toContain('UNNATURAL_TRAJECTORY_VELOCITY');
  });

  it('detects negligible motion amplitude when user is lying flat without moving', () => {
    const flatFrames: FramePoseRecord[] = Array.from({ length: 50 }, (_, i) => ({
      timestampMs: i * 33,
      frameIndex: i,
      frameHash: `noise_hash_${i}`,
      keypoints: [],
      leftElbowAngleDeg: 175 + (i % 2), // negligible 1 degree jitter
      rightElbowAngleDeg: 175 + (i % 2),
      bodyAlignmentAngleDeg: 170
    }));

    const result = LivenessAnalyzer.analyze(flatFrames);
    expect(result.flags).toContain('NEGLIGIBLE_MOTION_AMPLITUDE');
    expect(result.motionContinuityScore).toBeLessThan(0.30);
  });
});
