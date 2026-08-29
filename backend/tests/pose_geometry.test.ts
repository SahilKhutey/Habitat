// Unit Tests: MoveNet Pose Geometry & Vector Angle Engine
import { describe, it, expect } from 'vitest';
import { PoseGeometryCalculator } from '../src/modules/verification/engine/pose-geometry.calculator';
import { Keypoint } from '../src/modules/verification/domain/evidence.types';

describe('PoseGeometryCalculator', () => {
  it('accurately calculates basic 2D geometric vector angles', () => {
    // 90-degree right angle (Vertex at (0, 0), Point A at (0, 1), Point C at (1, 0))
    const angle90 = PoseGeometryCalculator.calculateAngle(
      { x: 0, y: 1 },
      { x: 0, y: 0 },
      { x: 1, y: 0 }
    );
    expect(Math.round(angle90)).toBe(90);

    // 180-degree straight line
    const angle180 = PoseGeometryCalculator.calculateAngle(
      { x: 0, y: 1 },
      { x: 0, y: 0 },
      { x: 0, y: -1 }
    );
    expect(Math.round(angle180)).toBe(180);

    // 45-degree acute angle
    const angle45 = PoseGeometryCalculator.calculateAngle(
      { x: 1, y: 1 },
      { x: 0, y: 0 },
      { x: 1, y: 0 }
    );
    expect(Math.round(angle45)).toBe(45);
  });

  it('detects top lockout position from 17 MoveNet keypoints', () => {
    const lockoutKeypoints: Keypoint[] = [
      { name: 'left_shoulder', x: 0.40, y: 0.30, score: 0.95 },
      { name: 'left_elbow', x: 0.40, y: 0.45, score: 0.95 },
      { name: 'left_wrist', x: 0.40, y: 0.60, score: 0.98 },
      { name: 'right_shoulder', x: 0.60, y: 0.30, score: 0.95 },
      { name: 'right_elbow', x: 0.60, y: 0.45, score: 0.95 },
      { name: 'right_wrist', x: 0.60, y: 0.60, score: 0.98 },
      { name: 'left_hip', x: 0.42, y: 0.65, score: 0.92 },
      { name: 'right_hip', x: 0.58, y: 0.65, score: 0.92 },
      { name: 'left_ankle', x: 0.44, y: 0.90, score: 0.90 },
      { name: 'right_ankle', x: 0.56, y: 0.90, score: 0.90 }
    ];

    const metrics = PoseGeometryCalculator.calculateMetrics(lockoutKeypoints);
    expect(metrics.isLockout).toBe(true);
    expect(metrics.isDeepBottom).toBe(false);
    expect(metrics.isGoodForm).toBe(true);
    expect(metrics.meanElbowAngleDeg).toBeGreaterThanOrEqual(160);
    expect(metrics.bodyAlignmentAngleDeg).toBeGreaterThanOrEqual(160);
  });

  it('detects deep bottom position from 17 MoveNet keypoints', () => {
    // Elbow flared out at 90 degrees or less
    const bottomKeypoints: Keypoint[] = [
      { name: 'left_shoulder', x: 0.40, y: 0.45, score: 0.95 },
      { name: 'left_elbow', x: 0.25, y: 0.45, score: 0.95 },
      { name: 'left_wrist', x: 0.25, y: 0.60, score: 0.98 },
      { name: 'right_shoulder', x: 0.60, y: 0.45, score: 0.95 },
      { name: 'right_elbow', x: 0.75, y: 0.45, score: 0.95 },
      { name: 'right_wrist', x: 0.75, y: 0.60, score: 0.98 },
      { name: 'left_hip', x: 0.42, y: 0.65, score: 0.92 },
      { name: 'right_hip', x: 0.58, y: 0.65, score: 0.92 },
      { name: 'left_ankle', x: 0.44, y: 0.90, score: 0.90 },
      { name: 'right_ankle', x: 0.56, y: 0.90, score: 0.90 }
    ];

    const metrics = PoseGeometryCalculator.calculateMetrics(bottomKeypoints);
    expect(metrics.isDeepBottom).toBe(true);
    expect(metrics.isLockout).toBe(false);
    expect(metrics.meanElbowAngleDeg).toBeLessThanOrEqual(95);
  });

  it('identifies hip sag / bad push-up posture', () => {
    // In profile view: Shoulder at (0.2, 0.4), Ankle at (0.8, 0.4), but Hips sagging down at (0.5, 0.75)
    const sagKeypoints: Keypoint[] = [
      { name: 'left_shoulder', x: 0.20, y: 0.40, score: 0.95 },
      { name: 'right_shoulder', x: 0.20, y: 0.40, score: 0.95 },
      { name: 'left_elbow', x: 0.20, y: 0.55, score: 0.95 },
      { name: 'right_elbow', x: 0.20, y: 0.55, score: 0.95 },
      { name: 'left_wrist', x: 0.20, y: 0.70, score: 0.98 },
      { name: 'right_wrist', x: 0.20, y: 0.70, score: 0.98 },
      { name: 'left_hip', x: 0.50, y: 0.75, score: 0.90 }, // Severe sag
      { name: 'right_hip', x: 0.50, y: 0.75, score: 0.90 },
      { name: 'left_ankle', x: 0.80, y: 0.40, score: 0.90 },
      { name: 'right_ankle', x: 0.80, y: 0.40, score: 0.90 }
    ];

    const metrics = PoseGeometryCalculator.calculateMetrics(sagKeypoints);
    expect(metrics.isGoodForm).toBe(false);
    expect(metrics.bodyAlignmentAngleDeg).toBeLessThan(135);
  });
});
