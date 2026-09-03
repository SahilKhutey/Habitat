// Pose Quality Filter & Biomechanical Sanity Guard
import { Keypoint } from '../domain/evidence.types';
import { PoseKeypointDetection } from '../domain/vision-provider.interface';

export interface PoseQualityCheckResult {
  valid: boolean;
  meanConfidence: number;
  coreJointsVisible: boolean;
  geometrySane: boolean;
  rejectionReason?: string;
}

export interface PoseSequenceQualityResult<T> {
  validFrames: T[];
  discardedFramesCount: number;
  totalFrames: number;
  qualityRatio: number;
  isQualitySufficient: boolean;
  reasons: string[];
}

export class PoseQualityFilter {
  public static readonly MIN_POSE_CONFIDENCE = 0.30;
  public static readonly MIN_JOINT_CONFIDENCE = 0.20;
  public static readonly MIN_VALID_FRAMES = 5;
  public static readonly MIN_QUALITY_RATIO = 0.40;

  /**
   * Evaluates individual frame keypoint quality
   */
  public static evaluateFrame(keypoints: Keypoint[]): PoseQualityCheckResult {
    if (!keypoints || keypoints.length < 17) {
      return {
        valid: false,
        meanConfidence: 0,
        coreJointsVisible: false,
        geometrySane: false,
        rejectionReason: 'Missing or incomplete 17 COCO keypoints.'
      };
    }

    // 1. Mean Confidence Calculation
    const scores = keypoints.map((kp) => kp.score ?? 0);
    const meanConfidence = scores.reduce((sum, s) => sum + s, 0) / scores.length;

    if (meanConfidence < this.MIN_POSE_CONFIDENCE) {
      return {
        valid: false,
        meanConfidence,
        coreJointsVisible: false,
        geometrySane: false,
        rejectionReason: `Low pose confidence (${meanConfidence.toFixed(2)} < ${this.MIN_POSE_CONFIDENCE}).`
      };
    }

    // 2. Core Joints Visibility (Shoulders, Elbows, Wrists, Hips)
    // Indices: 5: L_Shoulder, 6: R_Shoulder, 7: L_Elbow, 8: R_Elbow, 9: L_Wrist, 10: R_Wrist, 11: L_Hip, 12: R_Hip
    const leftShoulder = keypoints[5];
    const rightShoulder = keypoints[6];
    const leftElbow = keypoints[7];
    const rightElbow = keypoints[8];
    const leftWrist = keypoints[9];
    const rightWrist = keypoints[10];
    const leftHip = keypoints[11];
    const rightHip = keypoints[12];

    const hasShoulder = (leftShoulder?.score ?? 0) >= this.MIN_JOINT_CONFIDENCE || (rightShoulder?.score ?? 0) >= this.MIN_JOINT_CONFIDENCE;
    const hasElbow = (leftElbow?.score ?? 0) >= this.MIN_JOINT_CONFIDENCE || (rightElbow?.score ?? 0) >= this.MIN_JOINT_CONFIDENCE;
    const hasWrist = (leftWrist?.score ?? 0) >= this.MIN_JOINT_CONFIDENCE || (rightWrist?.score ?? 0) >= this.MIN_JOINT_CONFIDENCE;
    const hasHip = (leftHip?.score ?? 0) >= this.MIN_JOINT_CONFIDENCE || (rightHip?.score ?? 0) >= this.MIN_JOINT_CONFIDENCE;

    const coreJointsVisible = hasShoulder && hasElbow && hasWrist && hasHip;

    if (!coreJointsVisible) {
      return {
        valid: false,
        meanConfidence,
        coreJointsVisible: false,
        geometrySane: false,
        rejectionReason: 'Essential exercise landmarks (shoulders, elbows, wrists, or hips) are not visible.'
      };
    }

    // 3. Anatomical Geometry Sanity Check
    // Normal coordinate bounds check [0, 1]
    const outOfBounds = keypoints.some(
      (kp) => (kp.x !== undefined && (kp.x < -0.1 || kp.x > 1.1)) || (kp.y !== undefined && (kp.y < -0.1 || kp.y > 1.1))
    );

    if (outOfBounds) {
      return {
        valid: false,
        meanConfidence,
        coreJointsVisible,
        geometrySane: false,
        rejectionReason: 'Keypoint coordinates fall outside valid normalized frame boundaries.'
      };
    }

    return {
      valid: true,
      meanConfidence,
      coreJointsVisible: true,
      geometrySane: true
    };
  }

  /**
   * Filters a trajectory of pose frames, retaining only high-quality frames
   */
  public static filterSequence<T extends { keypoints: Keypoint[] }>(
    frames: T[]
  ): PoseSequenceQualityResult<T> {
    const validFrames: T[] = [];
    const reasons: string[] = [];

    for (const frame of frames) {
      const evaluation = this.evaluateFrame(frame.keypoints);
      if (evaluation.valid) {
        validFrames.push(frame);
      }
    }

    const totalFrames = frames.length;
    const discardedFramesCount = totalFrames - validFrames.length;
    const qualityRatio = totalFrames > 0 ? validFrames.length / totalFrames : 0;

    let isQualitySufficient = true;

    if (validFrames.length < this.MIN_VALID_FRAMES) {
      isQualitySufficient = false;
      reasons.push(
        `Insufficient valid pose frames: ${validFrames.length} valid frames found, minimum ${this.MIN_VALID_FRAMES} required.`
      );
    } else if (qualityRatio < this.MIN_QUALITY_RATIO) {
      isQualitySufficient = false;
      reasons.push(
        `Poor pose quality ratio: ${(qualityRatio * 100).toFixed(1)}% valid frames, minimum ${(this.MIN_QUALITY_RATIO * 100)}% required.`
      );
    }

    return {
      validFrames,
      discardedFramesCount,
      totalFrames,
      qualityRatio,
      isQualitySufficient,
      reasons
    };
  }
}
