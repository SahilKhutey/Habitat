// Pose Geometry & 2D Vector Angle Calculator for Human Keypoints
import { Keypoint, MoveNetKeypointName } from '../domain/evidence.types';

export interface PoseGeometryMetrics {
  leftElbowAngleDeg: number;
  rightElbowAngleDeg: number;
  meanElbowAngleDeg: number;
  bodyAlignmentAngleDeg: number;
  isLockout: boolean; // >= 155 deg
  isDeepBottom: boolean; // <= 90 deg
  isGoodForm: boolean; // body alignment >= 140 deg
  meanConfidence: number;
}

export class PoseGeometryCalculator {
  /**
   * Calculates joint angles and posture alignment from 17 MoveNet keypoints
   */
  public static calculateMetrics(keypoints: Keypoint[]): PoseGeometryMetrics {
    const kpMap = new Map<MoveNetKeypointName, Keypoint>();
    for (const kp of keypoints) {
      kpMap.set(kp.name, kp);
    }

    const leftShoulder = kpMap.get('left_shoulder');
    const leftElbow = kpMap.get('left_elbow');
    const leftWrist = kpMap.get('left_wrist');

    const rightShoulder = kpMap.get('right_shoulder');
    const rightElbow = kpMap.get('right_elbow');
    const rightWrist = kpMap.get('right_wrist');

    const leftHip = kpMap.get('left_hip');
    const leftAnkle = kpMap.get('left_ankle');
    const rightHip = kpMap.get('right_hip');
    const rightAnkle = kpMap.get('right_ankle');

    // 1. Calculate Left & Right Elbow Angles
    let leftElbowAngle: number | null = null;
    if (leftShoulder && leftElbow && leftWrist && leftElbow.score >= 0.3) {
      leftElbowAngle = this.calculateAngle(leftShoulder, leftElbow, leftWrist);
    }

    let rightElbowAngle: number | null = null;
    if (rightShoulder && rightElbow && rightWrist && rightElbow.score >= 0.3) {
      rightElbowAngle = this.calculateAngle(rightShoulder, rightElbow, rightWrist);
    }

    const lAngle = leftElbowAngle ?? rightElbowAngle ?? 180;
    const rAngle = rightElbowAngle ?? leftElbowAngle ?? 180;
    const meanElbowAngle = (lAngle + rAngle) / 2;

    // 2. Calculate Body Alignment (Plank angle from Shoulder -> Hip -> Ankle)
    let bodyAlignmentAngle = 180;
    const midShoulder = this.getMidpoint(leftShoulder, rightShoulder);
    const midHip = this.getMidpoint(leftHip, rightHip);
    const midAnkle = this.getMidpoint(leftAnkle, rightAnkle);

    if (midShoulder && midHip && midAnkle) {
      bodyAlignmentAngle = this.calculateAngle(midShoulder, midHip, midAnkle);
    }

    // 3. Confidence evaluation
    const criticalScores = [
      leftShoulder?.score ?? 0,
      rightShoulder?.score ?? 0,
      leftElbow?.score ?? 0,
      rightElbow?.score ?? 0,
      leftWrist?.score ?? 0,
      rightWrist?.score ?? 0,
      leftHip?.score ?? 0,
      rightHip?.score ?? 0
    ];
    const meanConfidence =
      criticalScores.reduce((acc, val) => acc + val, 0) / criticalScores.length;

    return {
      leftElbowAngleDeg: Math.round(leftElbowAngle * 10) / 10,
      rightElbowAngleDeg: Math.round(rightElbowAngle * 10) / 10,
      meanElbowAngleDeg: Math.round(meanElbowAngle * 10) / 10,
      bodyAlignmentAngleDeg: Math.round(bodyAlignmentAngle * 10) / 10,
      isLockout: meanElbowAngle >= 155,
      isDeepBottom: meanElbowAngle <= 90,
      isGoodForm: bodyAlignmentAngle >= 135,
      meanConfidence: Math.round(meanConfidence * 100) / 100
    };
  }

  /**
   * Computes angle ABC at vertex B (in degrees from 0 to 180)
   */
  public static calculateAngle(a: { x: number; y: number }, b: { x: number; y: number }, c: { x: number; y: number }): number {
    const v1x = a.x - b.x;
    const v1y = a.y - b.y;
    const v2x = c.x - b.x;
    const v2y = c.y - b.y;

    const dotProduct = v1x * v2x + v1y * v2y;
    const mag1 = Math.sqrt(v1x * v1x + v1y * v1y);
    const mag2 = Math.sqrt(v2x * v2x + v2y * v2y);

    if (mag1 === 0 || mag2 === 0) {
      return 180;
    }

    const cosTheta = Math.max(-1.0, Math.min(1.0, dotProduct / (mag1 * mag2)));
    const angleRad = Math.acos(cosTheta);
    return (angleRad * 180.0) / Math.PI;
  }

  private static getMidpoint(a?: Keypoint, b?: Keypoint): { x: number; y: number; score: number } | null {
    if (a && b) {
      return {
        x: (a.x + b.x) / 2,
        y: (a.y + b.y) / 2,
        score: Math.min(a.score, b.score)
      };
    }
    if (a) return a;
    if (b) return b;
    return null;
  }
}
